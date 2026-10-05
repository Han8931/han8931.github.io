#include <cuda_runtime.h>

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <vector>

// This example deliberately uses small, irregular dimensions by default.
// Usage: ./matmul [M N K], with positive dimensions no larger than 4096.
#define CUDA_CHECK(call) do {                                           \
    cudaError_t status = (call);                                        \
    if (status != cudaSuccess) {                                        \
        std::fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__,           \
                     cudaGetErrorString(status));                      \
        std::exit(EXIT_FAILURE);                                       \
    }                                                                  \
} while (0)

constexpr int T = 16;

__global__ void naive_matmul(int M, int N, int K,
                             const float* A, const float* B, float* C) {
    int col = blockIdx.x * blockDim.x + threadIdx.x;
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    if (row < M && col < N) {
        float acc = 0.0f;
        for (int k = 0; k < K; ++k)
            acc += A[row * K + k] * B[k * N + col];
        C[row * N + col] = acc;
    }
}

__global__ void tiled_matmul(int M, int N, int K,
                             const float* A, const float* B, float* C) {
    __shared__ float As[T][T], Bs[T][T];
    int tx = threadIdx.x, ty = threadIdx.y;
    int row = blockIdx.y * T + ty;
    int col = blockIdx.x * T + tx;
    float acc = 0.0f;
    for (int k0 = 0; k0 < K; k0 += T) {
        As[ty][tx] = (row < M && k0 + tx < K)
                        ? A[row * K + k0 + tx] : 0.0f;
        Bs[ty][tx] = (k0 + ty < K && col < N)
                        ? B[(k0 + ty) * N + col] : 0.0f;
        __syncthreads();
        for (int k = 0; k < T; ++k)
            acc += As[ty][k] * Bs[k][tx];
        __syncthreads();
    }
    if (row < M && col < N)
        C[row * N + col] = acc;
}

int parse_dimension(const char* arg) {
    char* end = nullptr;
    long value = std::strtol(arg, &end, 10);
    if (end == arg || *end != '\0' || value < 1 || value > 4096) {
        std::fprintf(stderr, "Dimensions must be integers in [1, 4096].\n");
        std::exit(EXIT_FAILURE);
    }
    return static_cast<int>(value);
}

int main(int argc, char** argv) {
    if (argc != 1 && argc != 4) {
        std::fprintf(stderr, "Usage: %s [M N K]\n", argv[0]);
        return EXIT_FAILURE;
    }
    int M = 37, N = 53, K = 29;
    if (argc == 4) {
        M = parse_dimension(argv[1]);
        N = parse_dimension(argv[2]);
        K = parse_dimension(argv[3]);
    }
    std::vector<float> A(M * K), B(K * N), C(M * N);
    std::vector<double> reference(M * N, 0.0);
    for (int i = 0; i < M * K; ++i) A[i] = (i % 17 - 8) / 16.0f;
    for (int i = 0; i < K * N; ++i) B[i] = (i % 13 - 6) / 16.0f;
    // Double precision provides a separate reference for the FP32 kernels.
    for (int row = 0; row < M; ++row)
        for (int k = 0; k < K; ++k)
            for (int col = 0; col < N; ++col)
                reference[row * N + col] +=
                    static_cast<double>(A[row * K + k]) * B[k * N + col];

    int device = 0;
    cudaDeviceProp properties{};
    CUDA_CHECK(cudaGetDevice(&device));
    CUDA_CHECK(cudaGetDeviceProperties(&properties, device));
    std::printf("GPU: %s; M=%d N=%d K=%d; FP32 inputs/output\n",
                properties.name, M, N, K);

    float *dA = nullptr, *dB = nullptr, *dC = nullptr;
    const size_t a_bytes = A.size() * sizeof(float);
    const size_t b_bytes = B.size() * sizeof(float);
    const size_t c_bytes = C.size() * sizeof(float);
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&dA), a_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&dB), b_bytes));
    CUDA_CHECK(cudaMalloc(reinterpret_cast<void**>(&dC), c_bytes));
    CUDA_CHECK(cudaMemcpy(dA, A.data(), a_bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(dB, B.data(), b_bytes, cudaMemcpyHostToDevice));

    dim3 block(T, T);
    dim3 grid((N + T - 1) / T, (M + T - 1) / T);
    cudaEvent_t start, stop;
    CUDA_CHECK(cudaEventCreate(&start));
    CUDA_CHECK(cudaEventCreate(&stop));
    bool all_passed = true;
    for (int variant = 0; variant < 2; ++variant) {
        auto launch = [&]() {
            if (variant == 0)
                naive_matmul<<<grid, block>>>(M, N, K, dA, dB, dC);
            else
                tiled_matmul<<<grid, block>>>(M, N, K, dA, dB, dC);
            CUDA_CHECK(cudaGetLastError());
        };
        // Warm up outside the timed region. All work uses the default stream.
        for (int i = 0; i < 3; ++i) launch();
        CUDA_CHECK(cudaDeviceSynchronize());
        constexpr int repeats = 10;
        CUDA_CHECK(cudaEventRecord(start));
        for (int i = 0; i < repeats; ++i) launch();
        CUDA_CHECK(cudaEventRecord(stop));
        CUDA_CHECK(cudaEventSynchronize(stop));
        float elapsed_ms = 0.0f;
        CUDA_CHECK(cudaEventElapsedTime(&elapsed_ms, start, stop));
        CUDA_CHECK(cudaMemcpy(C.data(), dC, c_bytes, cudaMemcpyDeviceToHost));

        bool passed = true;
        double max_error = 0.0;
        for (size_t i = 0; i < C.size(); ++i) {
            double error = std::abs(static_cast<double>(C[i]) - reference[i]);
            max_error = std::max(max_error, error);
            if (!std::isfinite(C[i]) || error > 1e-4 + 1e-4 * std::abs(reference[i]))
                passed = false;
        }
        double ms = elapsed_ms / repeats;
        double gflops = 2.0 * M * N * K / (ms * 1e6);
        std::printf("%-5s: %s, max error %.6g, %.4f ms, %.3f GFLOP/s\n",
                    variant == 0 ? "naive" : "tiled", passed ? "PASS" : "FAIL",
                    max_error, ms, gflops);
        all_passed = all_passed && passed;
    }
    CUDA_CHECK(cudaEventDestroy(start));
    CUDA_CHECK(cudaEventDestroy(stop));
    CUDA_CHECK(cudaFree(dA));
    CUDA_CHECK(cudaFree(dB));
    CUDA_CHECK(cudaFree(dC));
    return all_passed ? EXIT_SUCCESS : EXIT_FAILURE;
}
