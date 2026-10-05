---
weight: 1
title: "Understanding GPUs: From Memory to Fast Matrix Multiplication"
date: 2026-10-05
draft: false
author: Han
math: true
description: "A gradual tutorial on how GPUs execute programs and why data movement decides performance — from a 4x4 matmul you can do by hand to asynchronous Hopper kernels. Slide deck plus the full written tutorial."
tags: ["GPU", "CUDA", "matmul", "H100", "Hopper", "Tensor Core", "TMA", "WGMMA", "memory hierarchy", "coalescing", "tiling", "roofline", "performance"]
categories: ["GPU", "Performance"]
library:
  css:
    - "css/deck-embed.css"
---

GPUs are usually introduced as machines that do a lot of arithmetic. That framing
makes the hard part invisible. An H100 SXM can issue roughly **989 trillion** bf16
operations per second through its Tensor Cores, while its memory delivers about
**3.35 TB/s** — so if every multiply-add had to fetch both of its inputs from main
memory, memory could keep up with less than **0.2%** of the math. Almost everything
that makes a fast kernel fast is about not being in that situation.

This post has two halves. The deck below is the talk version: 34 slides with two
interactive figures, bilingual EN/한국어, and a provenance stamp on every slide
saying whether its claim comes from documentation, from a calculation done on the
slide, or from someone else's benchmark. Under it is the **full written tutorial**,
which goes considerably deeper — hand calculations, a runnable CUDA example, and
the detailed H100 case study.

<div class="deck-embed">
  <iframe src="/gpu-deck/" title="Understanding GPUs — slide deck" loading="lazy" allowfullscreen></iframe>
</div>

<div class="deck-embed-bar">
  <a class="open" href="/gpu-deck/" target="_blank" rel="noopener">Open deck fullscreen ↗</a>
  <span class="keys"><kbd>←</kbd> <kbd>→</kbd> navigate &nbsp;·&nbsp; <kbd>N</kbd> notes &nbsp;·&nbsp; <kbd>L</kbd> EN / 한국어 &nbsp;·&nbsp; <kbd>F</kbd> fullscreen &nbsp;·&nbsp; <kbd>Home</kbd> <kbd>End</kbd> jump</span>
</div>

Present from the fullscreen link — the deck is a standalone page with no site
chrome. Each slide is addressable by hash, so `/gpu-deck/#16` opens directly on the
roofline explorer, and the position survives a reload. Press <kbd>N</kbd> to expand
the teaching notes, which carry the caveats that do not fit on a slide.

---

A gradual tutorial for programmers who want to understand how GPUs execute
programs, why data movement matters, and how fast kernels are designed.

You need familiarity with variables, arrays, and loops in C or Python. You do
not need prior CUDA or computer-architecture knowledge. We start with a matrix
small enough to calculate by hand, explain the CUDA-specific syntax as it appears,
and build toward advanced NVIDIA Hopper kernels.

The tutorial is laid out in parts so you can learn one layer at a time.
The first three form a complete introduction. Later parts provide deeper
architecture and systems material; they are not prerequisites for running your
first kernel.

## Reading path

| Part | What you will learn | Milestone |
|---|---|---|
| [1. Numbers, addresses, and memory](#part-1-numbers-addresses-and-memory) | Matrix multiplication, row-major storage, precision, latency, bandwidth, caches, and locality | Explain why the same arithmetic can have different memory costs |
| [2. Your first kernel](#part-2-your-first-kernel-and-the-machine-that-runs-it) | Host/device execution, thread indexing, a runnable example, SMs, warps, and memory hierarchy | Trace each thread's output and explain how the GPU runs it |
| [3. Reuse, tiling, and measurement](#part-3-reuse-tiling-and-measurement) | Coalescing, shared-memory tiling, register reuse, roofline, correctness, and timing | Explain an optimization and measure it fairly |
| [4. A closer look at hardware](#part-4-a-closer-look-at-the-hardware) | DRAM, cache behavior, banks, compute ceilings, CUDA/PTX/SASS | Connect code behavior to a hardware constraint |
| [5. Advanced Hopper kernels](#part-5-advanced-matrix-multiplication-on-hopper) | Tensor Cores, TMA, swizzling, pipelines, persistence, and scheduling | Reason about asynchronous data lifetimes and resource tradeoffs |
| [6. Other kernels and the whole system](#part-6-other-kernels-and-the-whole-system) | Reductions, fusion, irregular work, virtual memory, transfers, and multiple GPUs | Apply the reasoning beyond matrix multiplication |
| [Exercises, glossary, and sources](#exercises-glossary-and-sources) | Practice questions, definitions, and primary references | Review and continue studying |

**First pass:** Parts 1 → 2 → 3. Work through the small calculations and checkpoints.
Then read Part 6 for breadth, or Parts 4 → 5 for the detailed H100 case study.
Chapter numbers remain continuous across files so references are easy to follow.

**Without a GPU:** you can follow the hand calculations, code traces, and diagrams.
**With CUDA:** compile [examples/matmul.cu](/gpu-matmul-assets/matmul.cu) using the commands
in [Chapter 4](#4-your-first-cuda-matrix-multiplication).
The example contains naive and tiled FP32 kernels, checks all outputs against a
CPU reference, and reports kernel-only timing. It is separate from the advanced
Hopper designs, which are explained conceptually.

## Two complementary sources

[Ulrich Drepper's *What Every Programmer Should Know About Memory*](/gpu-matmul-assets/cpumemory.pdf)
provides the foundation for locality, working sets, and measurement. It was
published in 2007 and focuses on CPUs. We use those foundational ideas while
keeping historical CPU details separate from GPU mechanisms.

[Aleksa Gordić's *Inside NVIDIA GPUs: Anatomy of High Performance Matmul Kernels*](https://www.aleksagordic.com/blog/matmul)
provides the main GPU architecture and matrix-kernel case study. This tutorial
introduces its prerequisites more slowly and preserves the deeper material in
the later parts. The adapted diagrams remain in [figures](/gpu-matmul-assets/figures/).

## How to read the examples

Figures are numbered within each part. Read the one-sentence takeaway first;
expand **Walk through Figure …** for a guide to the shapes, labels, arrows, and
a concrete example. Each walkthrough links to the full-size SVG for small text.

- Small matrices explain indexing and reuse; they are not performance benchmarks.
- Each memory-traffic calculation states what it counts. Requested values, cache
  transfers, and HBM transfers are not interchangeable.
- Hardware numbers are labeled examples, especially where H100 SXM and PCIe differ.
- Reported optimization rates come from the source case study, not local runs of
  this tutorial. FP32 and BF16 results are not one controlled speedup comparison.
- Advanced pseudocode explains dependencies. Correct implementations also need
  the architecture's exact synchronization and memory-ordering rules.

Start with [Part 1: Numbers, addresses, and memory](#part-1-numbers-addresses-and-memory).

---

## Part 1: Numbers, addresses, and memory


Start here. You need loops and basic arithmetic. By the end, you can calculate a matrix output, flatten a matrix into memory, and distinguish latency, bandwidth, and locality.

- [1. Why matmul?](#1-why-matmul)
- [2. Units you need: FLOPs, bytes, and time](#2-units-you-need-flops-bytes-and-time)
- [3. Why memory changes the cost of a program](#3-why-memory-changes-the-cost-of-a-program)

Each figure has a short takeaway and an expandable walkthrough. Open the walkthrough to decode the labels and follow a concrete example; its full-size link helps with small text.

---

### 1. Why matmul?

A **matrix multiply** (*matmul*) takes two grids of numbers, **A** and **B**, and produces a third grid, **C**.
Each cell of C is a **dot product**: take one row of A and one column of B, multiply the numbers pair by pair, and add everything up.

$$
C_{ij} = \sum_{k} A_{ik} \, B_{kj}
$$

```
        B (K×N)
        ┌─────┬─┬─────┐
        │     │█│     │   ← column j
        │     │█│     │
        └─────┴─┴─────┘
A (M×K)            C (M×N)
┌─────────┐        ┌─────┬─┬─────┐
│█████████│ row i  │     │●│     │   ● = C[i][j] = row i · column j
└─────────┘        └─────┴─┴─────┘
```

In plain code, it's three nested loops:

```python
for i in range(M):
    for j in range(N):
        acc = 0
        for k in range(K):
            acc += A[i][k] * B[k][j]   # one "multiply-add"
        C[i][j] = acc
```

That's all there is to it. The math itself has no clever trick in it.

#### 1.1 A calculation we can follow by hand

Throughout the first parts, we will return to these matrices:

```text
A = [ 1  2  3  4 ]       B = [ 1  0  2  0 ]
    [ 5  6  7  8 ]           [ 0  1  0  2 ]
    [ 9 10 11 12 ]           [ 1  0  1  0 ]
    [13 14 15 16 ]           [ 0  1  0  1 ]
```

We use zero-based indices: the first row is row 0. To find `C[0,0]`, multiply
the first row of A by the first column of B:

```text
C[0,0] = 1×1 + 2×0 + 3×1 + 4×0 = 4
C[0,1] = 1×0 + 2×1 + 3×0 + 4×1 = 6
```

![Pair A’s first row with B’s second column to compute C[0,1]=6.](/gpu-matmul-assets/figures/beginner_dot_product.svg)
*Figure 1.1. Pair A’s first row with B’s second column to compute C[0,1]=6.*

<details>
<summary>Walk through Figure 1.1</summary>

1. The blue highlight is row 0 of A; the red highlight is column 1 of B. Indices start at zero, so column 1 is the second column. Only the selected amber result is shown in C; dots stand for other outputs.

2. The bottom panel lines up the four k values. For k=1, A[0,1]=2 pairs with B[1,1]=1. Perform the four pairwise products, then sum 0+2+0+4.

3. Keep the blue row but choose another red column to compute a neighboring output. That reuse of the A row is what later tiling makes explicit.

[Open the full-size figure](/gpu-matmul-assets/figures/beginner_dot_product.svg).

</details>

Notice that both results need the same row of A. Remember that repeated use;
later it will explain why sharing data is valuable.

The complete result is:

```text
C = [ 4  6  5  8 ]
    [12 14 17 20 ]
    [20 22 29 32 ]
    [28 30 41 44 ]
```

**Check yourself:** Which two inputs determine `C[1,2]`?

<details>
<summary>Answer</summary>

Row 1 of A and column 2 of B: `5×2 + 6×0 + 7×1 + 8×0 = 17`.
Another output can be computed independently, because it does not need this result.

</details>

#### 1.2 Why use matrix multiplication to learn GPUs?

Matrix multiplication is common in scientific computing and neural networks.
It also gives us a useful combination: many independent outputs, repeated use
of the inputs, and a compact mathematical definition. We can change how the
computer does the work without changing the mathematical problem.

Our 4×4 example is for reasoning on paper. It is too small to demonstrate the
benefits of GPU execution. Later experiments use larger matrices, but the
indexing and reuse follow the same pattern.

The central question is: **how do we organize this work so that the hardware
spends more time producing useful results?** We will first build a correct
program, then improve it one bottleneck at a time. The advanced parts study
NVIDIA's H100, a GPU based on the Hopper architecture. Its details are a case
study, not requirements for understanding the early chapters.

---

### 2. Units you need: FLOPs, bytes, and time

You need these units for everything that follows.

| Term | Meaning |
|---|---|
| **FLOP** | one floating-point operation (one add, or one multiply) |
| **FMA** | *fused multiply-add*: `a*b + c` as a single instruction. It counts as **2 FLOPs** |
| **FLOP/s** | FLOPs per second (throughput) |
| **TFLOP/s** | 10¹² FLOP/s ("tera" = trillion) |
| **GB/s, TB/s** | bytes moved per second (memory bandwidth) |
| **fp32 / bf16** | 32-bit float (4 bytes) / 16-bit "brain float" (2 bytes) |

Bandwidth units here use decimal prefixes: 1 GB is 10⁹ bytes and 1 TB is 10¹²
bytes. For binary-sized arrays and on-chip storage, 1 KiB is 1,024 bytes and
1 MiB is 1,048,576 bytes. Preserve the units when comparing an array's footprint
with a hardware capacity quoted in MB.

**How many FLOPs is a matmul?** Each of the M·N output cells needs K multiply-adds = 2K FLOPs:

$$
\text{FLOPs} = 2 \cdot M \cdot N \cdot K
$$

**Worked example.** M = N = K = 4096:

$$
2 \times 4096^3 \approx 1.37 \times 10^{11} \text{ FLOPs}
$$

To turn an operation count into a time estimate, divide by an assumed rate.
For example, at **10 TFLOP/s**, this multiplication would take:

$$
\frac{1.37 \times 10^{11}}{10 \times 10^{12}}
\approx 0.0137 \text{ s} = 13.7 \text{ ms}
$$

This is a calculation, not a measurement or a promise about any particular GPU.
Real time also depends on memory accesses, instructions, and synchronization.

#### 2.1 What a matrix looks like in memory

Memory addresses identify bytes. A 32-bit floating-point value takes four bytes.
In a **row-major** matrix, the values of one row appear consecutively, followed
by the next row. Our A matrix is stored as:

```text
element index:  0  1  2  3 | 4  5  6  7 | 8  9 10 11 |12 13 14 15
value:          1  2  3  4 | 5  6  7  8 | 9 10 11 12 |13 14 15 16
```

For a matrix with `width` columns, element `[row, col]` is at element index
`row * width + col`. Its byte offset is that index multiplied by the element size.
Thus `A[1,2]` has value 7, element index 6, and byte offset 24 for FP32 storage.

![The value 7 at A[1,2] lives at element index 6 and byte offset 24.](/gpu-matmul-assets/figures/beginner_row_major.svg)
*Figure 1.2. The value 7 at A[1,2] lives at element index 6 and byte offset 24.*

<details>
<summary>Walk through Figure 1.2</summary>

1. Start with the highlighted 7 in the upper-left matrix. Row and column labels are zero-based. Skipping one complete row and two more elements gives index 1×4+2=6.

2. Follow the arrow into the flattened array. Numbers above the boxes are element indices; numbers inside are stored values; numbers below are starting byte offsets. Colored groups show the four original rows.

3. FP32 occupies four bytes, so element 6 begins at offset 24 and occupies bytes 24–27. That offset is added to A’s base address. The diagram shows storage layout, not cache lines or DRAM rows.

[Open the full-size figure](/gpu-matmul-assets/figures/beginner_row_major.svg).

</details>

In C++, `const float* A` means that A holds the address of floating-point data
that this function will read without modifying. `A[6]` reads the sixth offset
from that address. The pointer does not remember the matrix's dimensions; we
pass them separately. Python's nested-list syntax hides this layout decision.

The **stride** is the distance between successive accesses, or between successive
positions along a chosen dimension. Walking along a row here advances by one
element; walking down a column advances by four elements.

**Check yourself:** Where is `B[2,3]` in the flattened array?

<details>
<summary>Answer</summary>

Index `2×4 + 3 = 11`, byte offset `11×4 = 44` for FP32. Its value is 0.

</details>

#### 2.2 Precision is part of the problem

FP32 and BF16 are different representations of real numbers. BF16 uses fewer
bits for precision, so converting FP32 inputs to BF16 can round away information.
An operation may multiply low-precision inputs while accumulating into FP32.
Always state both input and accumulator types when comparing kernels.

Floating-point arithmetic also rounds intermediate results. Reordering sums or
using a fused multiply-add can change the final low-order bits. The mathematical
answer is unchanged, but the stored result need not be bit-for-bit identical.
We will compare results with an explicit numerical tolerance.

---

### 3. Why memory changes the cost of a program

**Learning goal:** distinguish the time for one access from the rate of many
accesses, and explain why nearby or recently used data is valuable.

This chapter draws on Ulrich Drepper's [*What Every Programmer Should Know
About Memory*](/gpu-matmul-assets/cpumemory.pdf), especially §§2–3 and §6.2. Its experiments and
CPU descriptions date from 2007. We use its explanations of locality and working
sets; we do not transfer its cache sizes, timings, CPU instructions, or motherboard
diagrams to modern GPUs.

#### 3.1 A load is work

In `acc += A[k] * B[k]`, the multiplications cannot use values that have not
arrived yet. A **load** brings a value from memory into storage the processor can
use. A **store** writes a value back. Arithmetic, loads, and stores all consume
hardware resources.

Two measurements describe different aspects of memory performance:

| Measurement | Question | Example unit |
|---|---|---|
| **Latency** | How long until one request produces its result? | nanoseconds |
| **Bandwidth** | How many bytes can be delivered per second? | GB/s |

A system can have high bandwidth and still have high latency. Think of many
deliveries traveling at once: the total delivery rate can be large even though
each individual delivery takes time.

Suppose an imaginary memory takes 100 ns to return a request and can sustain
64 GB/s. Keeping that rate requires roughly `64 GB/s × 100 ns = 6,400 bytes`
in flight. One dependent four-byte request at a time cannot do that. This is a
rough concurrency calculation, not a GPU specification.

#### 3.2 Independent work can cover a wait

Compare these two loops:

```text
Dependent:    read an index → use that index to find the next address → read it
Independent:  read A[0], read A[1], read A[2], ... without waiting for earlier values
```

In the dependent case, you cannot issue the next useful request until the current
one returns. In the independent case, hardware can have multiple requests in
progress. GPUs also keep many groups of threads available so one group can work
while another waits. That hides latency; it does not make an individual memory
request complete sooner or increase the bandwidth limit.

**Check yourself:** Can adding more waiting threads fix an already saturated
memory link?

<details>
<summary>Answer</summary>

No. Concurrency helps fill unused capacity. Once the link is delivering as many
bytes per second as it can, improvement requires fewer bytes or more bandwidth.

</details>

#### 3.3 Caches and two kinds of locality

A **cache** keeps copies of data in smaller, faster storage. A **cache hit** means
the requested data is present. A **miss** means another level must supply it.
Space is finite: bringing new data in can **evict** old data.

Caches move groups of bytes, often described as **cache lines**. Some GPU caches
divide lines into smaller **sectors**, so a line does not imply every byte is
transferred on every request. We will count sectors when discussing GPU loads.

Two patterns make caching useful:

- **Spatial locality:** use nearby addresses. If a transfer brings neighboring
  values, use those values too.
- **Temporal locality:** use a value again soon, while its copy is still nearby.

For an illustrative cache with 64-byte lines, one aligned line holds sixteen
FP32 values. Reading all sixteen uses the transferred bytes well. Reading one
value from each of many different lines can waste most of the delivery capacity.
This line size is an example, not a rule for every cache or GPU.

#### 3.4 The working set: what must stay nearby?

The **working set** is the data needed during the portion of execution we are
examining. A complete matrix can be much larger than a cache while the small
piece currently being processed still fits.

Suppose we repeatedly use 8 KiB of data in an otherwise idle 32 KiB cache. Keeping
the useful data nearby is plausible. If we cycle through 8 MiB between uses, much
of it must be fetched again. Capacity is not the only issue—address placement and
competing work matter too—but working-set size is a good first question.

Drepper's §3.3.2 varies working-set size and traversal order to reveal memory
behavior. The lesson to carry forward is the experimental method: change one
factor, measure, and explain the transition. Do not memorize the old CPU's cycle
counts.

#### 3.5 A first look at reuse in matrix multiplication

In our 4×4 multiplication, `C[0,0]` and `C[0,1]` both need A's first row. If we
compute them together, we can keep that row nearby and use it twice. If we compute
all four outputs in row 0 together, each value in that row of A contributes to
four results.

A **tile** is a rectangular piece of a matrix. Working on tiles limits the active
working set and makes reuse deliberate. Drepper's §6.2.1 explores transposition
and blocking for CPU matrix multiplication. Later we will express the same reuse
idea with cooperating GPU threads and explicitly managed shared memory.

That distinction matters: CPU cache blocking arranges accesses so hardware caches
can retain useful data. GPU shared-memory tiling explicitly copies data into a
buffer and coordinates which threads may use it. Both pursue reuse; their
programming mechanisms differ.

#### 3.6 A small experiment before touching CUDA

On paper, list the element indices visited by a row walk and a column walk of our
4×4 A matrix. The row walk begins `0,1,2,3`; the column walk begins `0,4,8,12`.

For an optional CPU experiment, write those two traversals in compiled C or C++,
sum the values, and print the sums so the compiler cannot simply remove the work.
Sweep from small arrays to much larger ones. Repeat measurements and record the
compiler options. Python interpreter overhead can obscure the memory effect in a
plain Python loop.

The prediction is about access patterns, not a guaranteed speedup: a tiny matrix
may already fit in cache, and processors can overlap or anticipate some loads.
Later GPU experiments will ask a further question: **which addresses do neighboring
threads request in the same instruction?**

---

## Part 2: Your first kernel and the machine that runs it


Build on Part 1. First trace a complete CUDA kernel; then connect threads and blocks to the GPU memory and execution resources. You can stop after Chapter 4 to run the example before reading the architecture tour.

- [4. Your first CUDA matrix multiplication](#4-your-first-cuda-matrix-multiplication)
- [5. What a GPU actually is](#5-what-a-gpu-actually-is)
- [6. The memory hierarchy](#6-the-memory-hierarchy)
- [7. How the compute side is organized](#7-how-the-compute-side-is-organized)


---

### 4. Your first CUDA matrix multiplication

**Learning goal:** explain what runs on the CPU, what runs on the GPU, and which
output belongs to each thread. You do not need the chip's internal layout yet.

#### 4.1 The CPU starts the work

In this tutorial, the **host** is the CPU side of the program and the **device**
is the NVIDIA GPU. We use a discrete GPU with its own memory. Our basic program:

1. Creates A and B in host memory.
2. Allocates space for A, B, and C in device memory.
3. Copies A and B to the device.
4. Launches a GPU function called a **kernel**.
5. Waits for its result, copies C back, and checks it.

```text
CPU: create A,B → copy inputs → launch kernel → wait → read and check C
GPU:                         many threads compute C
```

Moving inputs to a GPU takes time. A tiny matrix usually does not justify that
overhead. The 4×4 example helps us reason about correctness; it is not a useful
GPU benchmark.

#### 4.2 One function, many thread identities

A **thread** is one logical execution of the kernel. Each thread has its own
local variables and an identity. Threads are grouped into **blocks**; the collection
of blocks is the **grid**. These groups describe work, not the physical shape of
the chip.

We give every thread one output cell. A 2×2 teaching block covers four outputs:

```text
4×4 output C, divided into 2×2 blocks

          columns 0,1       columns 2,3
rows 0,1  block (0,0)       block (1,0)
rows 2,3  block (0,1)       block (1,1)
```

The first coordinate is x (column direction); the second is y (row direction).
CUDA supplies `blockIdx`, `threadIdx`, and `blockDim`:

```cpp
int col = blockIdx.x * blockDim.x + threadIdx.x;
int row = blockIdx.y * blockDim.y + threadIdx.y;
```

Thread `(x=1,y=0)` in block `(x=1,y=0)`, with 2×2 blocks, computes row 0,
column `1×2 + 1 = 3`. It computes `C[0,3]`, whose value is 8 in our example.

![Thread (1,0) in block (1,0) computes output C[0,3] in the 2×2 teaching launch.](/gpu-matmul-assets/figures/beginner_thread_mapping.svg)
*Figure 2.1. Thread (1,0) in block (1,0) computes output C[0,3] in the 2×2 teaching launch.*

<details>
<summary>Walk through Figure 2.1</summary>

1. The left 4×4 output is partitioned into four 2×2 regions. The amber outline selects the top-right block, whose CUDA block coordinates are (x=1,y=0). The red-bordered output contains 8.

2. The curved arrow enlarges that same block on the right. Now each box is one thread’s assignment. The selected local thread (x=1,y=0) is the top-right thread inside the block.

3. Use the formulas below: col=1×2+1=3 and row=0×2+0=0. CUDA coordinate pairs use (x,y), whereas C[row,col] uses (row,column). Each displayed result comes from a complete four-term dot product.

[Open the full-size figure](/gpu-matmul-assets/figures/beginner_thread_mapping.svg).

</details>

The thread does not compute a quarter of a dot product. In this first kernel it
computes the **entire** dot product for its output, looping through K itself.
Different output cells are the independent jobs.

#### 4.3 Read the kernel line by line

```cuda
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
```

`__global__` declares a GPU kernel that the host can launch. `M`, `N`, and `K`
describe the matrices: A is M×K, B is K×N, C is M×N. `const` marks the inputs
read-only through these pointers. Each thread's `acc` holds its partial sum.
The flattened-array expressions are the row-major indexing from
[Chapter 2](#2-units-you-need-flops-bytes-and-time).

No thread needs to wait for another here: each reads the inputs and writes a
different output. Parallel code becomes harder when threads cooperate on
intermediate data. We will introduce synchronization when we reach that case.

#### 4.4 Launch enough threads, including the edges

The executable example uses 16×16 blocks. The host launches it with:

```cuda
dim3 block(16, 16);
dim3 grid((N + 15) / 16, (M + 15) / 16);
naive_matmul<<<grid, block>>>(M, N, K, dA, dB, dC);
```

`dim3` is CUDA's type for dimensions. The `<<<grid, block>>>` syntax specifies
how many blocks to launch and how many threads belong to each. `dA`, `dB`, and
`dC` are pointers to allocated device memory, not the host arrays.

Integer division rounds down. Adding 15 before dividing by 16 rounds a positive
size **up** to the number of blocks needed. If N is 17, we need two blocks across,
not one. Some threads in the final block lie outside the matrix; the kernel's
`if` prevents them from accessing invalid elements.

**Check yourself:** For M=3, N=5 and 2×2 teaching blocks, what grid do we need?
How many launched threads produce an output?

<details>
<summary>Answer</summary>

Three blocks across and two down: `grid(3,2)`. Six blocks of four threads launch
24 threads; 15 write outputs and nine fail the bounds check.

</details>

#### 4.5 Run and check it

The complete program is [examples/matmul.cu](/gpu-matmul-assets/matmul.cu). It includes
host allocation, transfers, error checking, a CPU reference, and both the naive
and shared-memory kernels. Read only `naive_matmul` and the host setup on your
first pass; [Chapter 9](#9-the-big-idea-tiling-and-reuse)
explains the tiled version.

With an NVIDIA GPU and a compatible CUDA Toolkit installed, from the repository
root run:

```sh
nvcc -O3 -std=c++17 examples/matmul.cu -o /tmp/gpu-matmul
/tmp/gpu-matmul
/tmp/gpu-matmul 4 4 4
/tmp/gpu-matmul 1 17 3
/tmp/gpu-matmul 256 256 256
```

The default shape is M=37, N=53, K=29, which deliberately exercises incomplete
tiles. The executable uses deterministic mixed-sign inputs, rather than the
hand-calculation matrices, and compares **every output** against a double-precision
CPU reference. Look for `PASS` for both kernels; times depend on your hardware.
The reference calculation can take a long time for large matrices.

This program is a teaching harness, not an exhaustive numerical test suite or a
replacement for a tuned matrix library. Its timed region excludes allocation and
host/device transfers. We will discuss what that means in
[Chapter 10](#10-check-correctness-then-explain-performance).

If you do not have CUDA available, trace the 4×4 example and continue reading.
The memory and indexing arguments do not require owning a GPU.

---

### 5. What a GPU actually is

A GPU does two things:

1. **Moves data around**, which is the job of the memory system.
2. **Does math on the data**, which is the job of the compute units.

The fact everything else hinges on is this: **data movement can cost more than the arithmetic it supplies.**

Some numbers make it concrete. An H100 SXM using its specialized matrix units can do roughly **a thousand trillion** math operations per second (~989 TFLOP/s in bf16).
Its main memory delivers about **3.35 TB/s**. That sounds like a lot until you do the division.
If every multiply-add had to fetch both of its inputs (2 × 2 bytes) straight from main memory, memory could keep up with only about

$$
\frac{3.35 \times 10^{12} \text{ bytes/s}}{4 \text{ bytes per FMA}} \approx 0.84 \times 10^{12} \text{ FMA/s} \approx 1.7 \text{ TFLOP/s}
$$

That's **less than 0.2%** of what the math units can do. If you're careless, and it's very easy to be careless,
the expensive math hardware spends almost all of its time idle, starving.

So the best way to think of a GPU is:

> **A GPU is a data-moving machine with some very fast math attached.**

For matrix multiplication, a major part of optimization is **keeping the math units supplied with useful data**. Other kernels may be limited by instruction dependencies, control flow, or synchronization.

![Many SMs share a cache and a larger off-chip memory; a thread is not one of these hardware boxes.](/gpu-matmul-assets/figures/h100_model_2.svg)
*Figure 2.2. Many SMs share a cache and a larger off-chip memory; a thread is not one of these hardware boxes.*

<details>
<summary>Walk through Figure 2.2</summary>

1. Start at the small red rectangles: each is an SM, which can host blocks of threads. Orange outlines group SMs into GPCs. Gray rectangles illustrate disabled units; their placement is not a map of a particular card.

2. Move downward to the two blue L2 partitions and the purple HBM box. These store or supply data for the SMs. The double-headed arrows indicate connectivity, not a mandatory sequence of instructions.

3. The bottom links lead outside the GPU: PCIe toward the host and NVLink toward other supported devices. On a first pass, remember just SM → shared L2 → HBM; leave the link rates and address-space labels for Part 6.

[Open the full-size figure](/gpu-matmul-assets/figures/h100_model_2.svg).

</details>

Think of a factory with thousands of incredibly fast workers and only a few delivery trucks. Hiring more workers doesn't help, because the trucks are the bottleneck.
Many optimizations in this tutorial follow five habits for getting more out of those trucks:

1. **Move less data.**
2. **Move it efficiently**, in big, well-aligned chunks.
3. **Keep important data nearby**, in fast memory.
4. **Reuse it many times** once it's nearby.
5. **Overlap movement with computation**, so neither one waits for the other.

#### 5.1 CPU and GPU: different balances

A CPU is designed to make progress on a small number of complex instruction
streams, including branches and dependent operations. A GPU devotes more of its
resources to throughput across many threads. Both have caches, parallel execution,
and finite memory bandwidth; neither is simply the other with more cores.

An **SM**, or streaming multiprocessor, is a GPU execution unit that hosts groups
of threads. A software thread is not a permanently dedicated arithmetic circuit.
Many threads can be resident while only some of their instructions issue in a
given cycle. Chapter 7 connects this distinction to latency hiding.

---

### 6. The memory hierarchy

#### 6.1 The fundamental trade-off

> **Fast memory is small. Big memory is slow.**

This comes from physics. Fast memory (SRAM) needs ~6 transistors per bit and must sit right next to the compute units.
Dense memory (DRAM) needs 1 transistor + 1 capacitor per bit, so it's compact but slower and lives off-chip.
So GPUs, like CPUs, stack several layers of memory.

#### 6.2 The analogy

| Memory | Analogy |
|---|---|
| **Registers** | things already in your hands |
| **Shared memory (SMEM)** | your desk |
| **L1 cache** | a shelf next to your desk that tidies itself |
| **L2 cache** | the shared storeroom down the hall |
| **HBM / global memory (GMEM)** | a giant warehouse across town |

#### 6.3 H100 numbers (approximate)

| Level | What it is | Size on H100 | Speed |
|---|---|---|---|
| **Registers** | private per-thread storage | 65,536 × 32-bit = 256 KiB **per SM** | fastest |
| **Shared memory** | scratchpad you manage yourself, shared by a thread block | up to **228 KiB per SM** | very fast, on-chip |
| **L1 cache** | hardware-managed cache, shares the same physical SRAM as SMEM | 256 KiB combined L1+SMEM per SM | very fast |
| **L2 cache** | hardware cache shared by the whole GPU | **50 MB** | fast |
| **HBM (GMEM)** | off-chip stacked DRAM | **80 GB**, ~2.0 TB/s (PCIe) to ~3.35 TB/s (SXM) | slowest |

(An **SM** is one of the GPU's ~132 mini-processors. Covered in [§7](#7-how-the-compute-side-is-organized).)

![Compare who owns each storage level and who controls its contents.](/gpu-matmul-assets/figures/mem_hierarchy.svg)
*Figure 2.3. Compare who owns each storage level and who controls its contents.*

<details>
<summary>Walk through Figure 2.3</summary>

1. Read the four horizontal bands from top to bottom. Registers hold a thread’s values. Shared memory is managed by a block’s code, while L1 and L2 are caches managed by hardware.

2. The capacities on the right use different scopes: registers and the combined L1/shared-memory pool are per SM; L2 and HBM figures are for the whole GPU.

3. Follow a global load conceptually: a cache may supply it to a register. The picture does not require the value to pass through a shared-memory array. That extra staging occurs only when the program requests it.

[Open the full-size figure](/gpu-matmul-assets/figures/mem_hierarchy.svg).

</details>


Exact latencies depend on access pattern and load, so memorize the **ordering**, not cycle counts.
Latency, bandwidth, and capacity are different properties; the diagram is a guide to locality, not a fixed multiplier between levels.

#### 6.4 The rule

> **Copy useful chunks *up* the hierarchy, reuse them many times while they're up there, and avoid going back to HBM for the same data.**

If a value is loaded from HBM **once** and used in **100** calculations, that's far better than loading it **100** times.
The requested data movement differs by 100×. The runtime improvement depends on whether that traffic was the bottleneck and whether caches already supplied some of the reuse.

#### 6.5 Address spaces are not a mandatory route through every memory

The hierarchy diagram shows kinds of storage, not an instruction to copy every
value through every box. An ordinary global load can be supplied by a cache and
placed in a register. It does not automatically pass through a programmer's
shared-memory array. To use shared memory, the kernel explicitly stages data
there. Some transfer instructions also bypass particular cache levels.

Likewise, **global memory** names a programming address space, while **HBM**
names the physical memory technology used by the H100. A global-memory access
that hits L2 does not fetch those bytes from HBM. This distinction will matter
when we count traffic.

**Check yourself:** If two threads need a value, should you always copy it into
shared memory first?

<details>
<summary>Answer</summary>

No. The copying and synchronization have a cost. A cache or broadcast may already
serve the accesses efficiently. Explicit staging pays when useful reuse outweighs
the additional work; we will test it with matrix tiles.

</details>

---

### 7. How the compute side is organized

#### 7.1 The hardware: GPCs and SMs

You already saw the whole chip in §5: 8 GPCs, each a row of SMs, sharing an L2 cache and HBM. Here's what's inside **one SM**:

![Zooming into one SM reveals execution resources alongside the storage that supplies them.](/gpu-matmul-assets/figures/h100_model.svg)
*Figure 2.4. Zooming into one SM reveals execution resources alongside the storage that supplies them.*

<details>
<summary>Walk through Figure 2.4</summary>

1. The four vertical columns are sub-partitions, not four software threads. In each, the scheduler selects eligible warp instructions; registers retain thread state; arithmetic and load/store units execute different kinds of work.

2. The large band below is one on-chip SRAM pool divided between shared memory and L1. Allocating more to shared memory leaves less for L1; it does not enlarge the pool.

3. TMA is a bulk-copy facility and the DSMEM link permits cluster communication. These advanced boxes are explained in Part 5. For now, locate the scheduler, registers, and shared-memory pool; the small footnotes are reference details.

[Open the full-size figure](/gpu-matmul-assets/figures/h100_model.svg).

</details>

- **SM (Streaming Multiprocessor):** the GPU's building block. The H100 SXM has **132 SMs**, the H100 PCIe **114**.
  The full silicon die has 144, but some are disabled ("fused off") to improve manufacturing yield.
- **GPC (Graphics Processing Cluster):** a group of SMs that sit physically close together. This matters later for *clusters* ([§15.7](#157-clusters-and-tma-multicast--734-tflops)).

- Each SM has **4 sub-partitions**. Each has its own **warp scheduler**, a slice of the register file, ordinary arithmetic units, and **one Tensor Core** (a matrix-math unit, [§14.3](#143-tensor-cores-and-wgmma)).

#### 7.2 The software: threads, warps, blocks, grid

When you write a CUDA **kernel** (a function that runs on the GPU), you launch it with a **grid** of **thread blocks**:

```
Grid  (the whole kernel launch)
 ├─ Block (0,0)  ── runs on ONE SM for its whole life
 │   ├─ Warp 0  = threads 0..31
 │   ├─ Warp 1  = threads 32..63
 │   └─ ...
 ├─ Block (0,1)
 └─ ...
```

| Level | What it is | Key property |
|---|---|---|
| **Thread** | one logical worker with its own registers | the unit you write code for |
| **Warp** | **32 threads** that execute together | the unit the hardware *schedules* |
| **Warp group** | 4 warps = 128 threads (Hopper) | the unit for big Tensor Core instructions |
| **Thread block (CTA)** | up to 1024 threads | stays on one SM; threads can share SMEM and synchronize |
| **Grid** | all blocks of one launch | independent scheduling; communication requires an explicit supported mechanism |

![Software groups determine which threads can cooperate; memory visibility alone does not synchronize them.](/gpu-matmul-assets/figures/cuda_model.svg)
*Figure 2.5. Software groups determine which threads can cooperate; memory visibility alone does not synchronize them.*

<details>
<summary>Walk through Figure 2.5</summary>

1. Read the software hierarchy on the right: thread → warp → block → cluster → grid. The left side names storage associated with different scopes. Dashed arrows connect related scopes; they are not data-transfer instructions.

2. A block’s threads can use its shared-memory array, but they still need a barrier when one thread must wait for another’s writes. A warp is 32 thread identities; it is not a piece of shared memory.

3. At grid scope, global memory can hold shared results, but ordinary blocks are independently scheduled. A memory address is not a grid-wide barrier. Clusters and other supported coordination mechanisms have their own rules.

[Open the full-size figure](/gpu-matmul-assets/figures/cuda_model.svg).

</details>

Every thread can ask "where am I?" through built-in variables: `blockIdx` (which block), `threadIdx` (which thread inside the block), and `blockDim`/`gridDim` (how big they are):

![Find a block first, then a thread within that block, then calculate the matrix coordinates.](/gpu-matmul-assets/figures/cuda_model2.svg)
*Figure 2.6. Find a block first, then a thread within that block, then calculate the matrix coordinates.*

<details>
<summary>Walk through Figure 2.6</summary>

1. The upper-left grid contains blocks. The orange block is (2,1). The arrow zooms into that block; the upper-right grid now contains threads, not more blocks.

2. With 32×32 threads, the highlighted thread (31,2) has global column 2×32+31=95 and row 1×32+2=34. The green row is one warp because x varies fastest and the row has exactly 32 threads.

3. The lower panel repeats the zoom idea for optional Hopper clusters. Labels beginning with % are PTX special registers. Skip that panel until the cluster section; the thread-coordinate calculation above is unchanged.

[Open the full-size figure](/gpu-matmul-assets/figures/cuda_model2.svg).

</details>

**SIMT (Single Instruction, Multiple Threads):** an issued warp instruction applies to the participating lanes, each on **its own data**. A lane is a thread position within the warp:

```
instruction: c = a + b
thread 0:  c0  = a0  + b0
thread 1:  c1  = a1  + b1
...
thread 31: c31 = a31 + b31
```

If lanes take different branches, the hardware executes the required paths with the relevant lanes enabled. This **warp divergence** can reduce useful work per issued instruction. Treat this as a first mental model; it does not mean that independent threads can safely communicate without synchronization.

#### 7.3 Latency hiding: why an SM keeps many warps around

An H100 SM can hold up to **2048 threads (64 warps)** at once. Its four schedulers can each issue a warp instruction per cycle when eligible work and execution resources are available. Issuing an instruction does not mean all of its work completes in that cycle.
Why keep so many warps resident?

Because memory is slow. When warp A issues a load, it may wait hundreds of cycles for the data.
Instead of idling, the scheduler switches to another warp that's ready, without saving and restoring the warp's registers to memory: resident warps already have storage allocated on-chip. Dependencies and execution resources can still prevent an instruction from issuing.

```
Without enough warps:                    With many warps:
warp A: load ░░░░░░░░░ compute           warp A: load ░░░░░░░░░ compute
        (SM idle while waiting)          warp B:   compute load ░░░░░░
                                         warp C:     load ░░░░░░ compute
                                         warp D: compute   load ░░░░░░
                                         → more opportunities to issue useful work
```

This is **latency hiding**: other warps' work fills the time one warp spends waiting.

#### 7.4 Occupancy, and why maximum isn't the goal

**Occupancy** = active warps on an SM ÷ maximum warps (64).

What limits it? Each SM has a fixed budget:

- **Registers:** 65,536 per SM
- **Shared memory:** up to 228 KiB per SM
- **Threads:** 2048 per SM, **blocks:** 32 per SM

**Worked example (the article's naive kernel):** blocks of 32×32 = 1024 threads, each using 32 registers.

$$
1024 \text{ threads} \times 32 \text{ regs} = 32{,}768 \text{ regs per block}
\;\Rightarrow\; \frac{65{,}536}{32{,}768} = 2 \text{ blocks per SM}
$$

2 blocks × 1024 threads = 2048 threads = 100% occupancy.

But:

> **Maximum occupancy ≠ maximum performance.**

A fast matmul kernel often **deliberately** uses many registers per thread (to hold lots of partial results) and lots of shared memory (to hold big tiles).
That *lowers* occupancy but greatly reduces memory traffic, and it wins. The goal isn't "maximize occupancy." The goal is **keep the machine busy.**
Later kernels hide latency through *asynchrony and pipelining* ([§15](#15-building-an-asynchronous-pipeline)) rather than lots of warps.

**Check yourself:** If all resident warps are waiting for the same saturated
memory system, does 100% occupancy guarantee full arithmetic throughput?

<details>
<summary>Answer</summary>

No. Occupancy counts resident warps, not ready instructions or useful arithmetic.
It is a resource measure, not a performance score.

</details>

---

## Part 3: Reuse, tiling, and measurement


Build on the first kernel. Learn why address patterns matter, cooperate through shared memory, and measure a change without confusing correctness, kernel time, and application time.

- [8. The naive kernel, and why it's slow](#8-the-naive-kernel-and-why-its-slow)
- [9. The big idea: tiling and reuse](#9-the-big-idea-tiling-and-reuse)
- [10. Check correctness, then explain performance](#10-check-correctness-then-explain-performance)


---

### 8. The naive kernel, and why it's slow

#### 8.1 Start from the program we already understand

Our naive kernel is correct: each thread computes one cell, and edge threads
check their bounds. Now ask what addresses **neighboring lanes** read at one
iteration of the inner loop.

For the address diagrams in this chapter, assume a **32×32 block**, so a warp
occupies one complete row of the block. The executable defaults to 16×16 blocks,
where a warp spans two rows; that is a valid launch, but its lane mapping differs.
Changing the block shape changes the access pattern, even with the same kernel.

**Coalescing** means combining a warp's memory requests into as few transferred
sectors as possible. In the examples below, sectors are 32 bytes. An aligned
group of 32 consecutive FP32 values uses four sectors; 32 far-apart values can
require 32 sectors. These counts describe requests at the cache interface, not
a guarantee that all those bytes travel from HBM.

#### 8.2 Pitfall 1: which index is "x" matters (coalescing)

Threads are numbered so that **`threadIdx.x` varies fastest**. With a 32×32 block, **one warp = 32 threads with the same `threadIdx.y` and `threadIdx.x = 0..31`**.

In the code above, the 32 threads of a warp share `row` and have consecutive `col`:

![A warp follows a row of output cells in this 32×32-block example.](/gpu-matmul-assets/figures/simple_kernel_logical.svg)
*Figure 3.1. A warp follows a row of output cells in this 32×32-block example.*

<details>
<summary>Walk through Figure 3.1</summary>

1. The left grid represents the output matrix. Each large square is a block’s output region; only a few of the 128×128 blocks are drawn. The dashed arrow enlarges block (0,0).

2. On the right, each tiny cell is one thread’s output. Read across the row labeled warp 0: x runs from 0 to 31 while y stays 0. The next row belongs to warp 1.

3. The conclusion depends on the illustrated block width. The runnable example uses 16×16 blocks, where a warp spans two rows; do not carry the “one warp per row” picture over unchanged.

[Open the full-size figure](/gpu-matmul-assets/figures/simple_kernel_logical.svg).

</details>

| Access | Addresses across the warp | Result |
|---|---|---|
| `A[row*K + k]` | all the **same** | broadcast ✅ |
| `B[k*N + col]` | **consecutive** | coalesced ✅ |
| `C[row*N + col]` | **consecutive** | coalesced ✅ |

![At one k value, the warp shares one A value and reads neighboring B values.](/gpu-matmul-assets/figures/simple_kernel.svg)
*Figure 3.2. At one k value, the warp shares one A value and reads neighboring B values.*

<details>
<summary>Walk through Figure 3.2</summary>

1. Start with the amber strip of C: 32 lanes own C[0,0] through C[0,31]. Freeze the inner loop at one k. All those outputs need A[0,k], the single highlighted A element.

2. The red horizontal strip of B is B[k,0:32]. Lane t reads B[k,t]. The enlarged strip at the upper left shows these 32 FP32 values packed into 128 aligned bytes: four 32-byte sectors.

3. Repeat at the next k. The thin A highlight moves along its row and the B highlight moves down a row. The pale background panels show all data eventually needed, not one enormous load. Cache hits may reduce the bytes reaching HBM.

[Open the full-size figure](/gpu-matmul-assets/figures/simple_kernel.svg).

</details>

In the next diagram, keep the block-to-output mapping and the square 32×32 block shape, but exchange the local thread indices: row = blockIdx.y*32 + threadIdx.x and col = blockIdx.x*32 + threadIdx.y. Each warp then walks down a column of C:

| Access | Addresses across the warp | Result |
|---|---|---|
| `A[row*K + k]` | stride of K = 4096 floats | uncoalesced ❌ |
| `B[k*N + col]` | all the same | broadcast |
| `C[row*N + col]` | stride of N | uncoalesced ❌ |

![Changing the local x/y mapping makes each warp follow a column of C.](/gpu-matmul-assets/figures/simple_kernel_uncoalesced_logical.svg)
*Figure 3.3. Changing the local x/y mapping makes each warp follow a column of C.*

<details>
<summary>Walk through Figure 3.3</summary>

1. Compare the two coordinate formulas with the previous logical diagram. Here threadIdx.x changes the row within a block, while threadIdx.y changes the column. Block coordinates still locate the same output region.

2. Read down the highlighted warp 0: its 32 lanes own different rows but the same column. Hardware still groups consecutive linear thread identities; drawing them vertically does not change the warp size.

3. Now predict the inputs for one k: different rows of A, one common B element. The following diagram translates this ownership change into addresses.

[Open the full-size figure](/gpu-matmul-assets/figures/simple_kernel_uncoalesced_logical.svg).

</details>

![Strided A accesses request many sectors while using only a small part of each.](/gpu-matmul-assets/figures/simple_kernel_uncoalesced.svg)
*Figure 3.4. Strided A accesses request many sectors while using only a small part of each.*

<details>
<summary>Walk through Figure 3.4</summary>

1. The blue vertical A strip contains A[0,k] through A[31,k]. With K=4096 FP32 values per row, adjacent lanes’ addresses differ by 4096×4=16,384 bytes.

2. In the enlargement, each blue sliver is four useful bytes and each hatched remainder is 28 other bytes in its sector. The warp requests 32 sectors rather than the four needed for an aligned contiguous group of 32 floats.

3. The red B highlight is a single common value, so that load can still be shared. This is a request-level explanation; cache reuse and instruction behavior also affect the reported timing. A sector count alone does not predict a 13× slowdown.

[Open the full-size figure](/gpu-matmul-assets/figures/simple_kernel_uncoalesced.svg).

</details>

The article measured this on an H100 PCIe with 4096×4096 matrices:

> **3171 GFLOP/s → 243 GFLOP/s.** A roughly 13× slowdown from changing the mapping of lanes to matrix coordinates.

> **Two programs doing mathematically identical work can differ in speed by 10× or more because of their address patterns.**

#### 8.3 Pitfall 2: little organized reuse (arithmetic intensity)

**Count requested values and transferred bytes separately.**
For one output, a thread requests K values from A and K from B. With FP32
inputs, that is 8K input bytes for about 2K FLOPs, or **0.25 FLOP per requested
byte**. This count ignores the output store.

But it is **not automatically the arithmetic intensity at HBM**. In a warp,
multiple threads may request the same value and share the transfer. Caches may
also serve repeated requests. A byte requested by many threads need not cross
the HBM interface many times.

**Arithmetic intensity** is operations divided by bytes moved across a specified
boundary. Always say which boundary you mean: HBM to the chip, L2 to an SM,
shared memory to registers, or simply source-level requested bytes.

The weakness of the naive kernel is not that it has literally no reuse. It is
that it does not explicitly organize cooperative reuse across the output tile.
We will make that reuse deliberate in the next chapter.

#### 8.4 Roofline: a bound, not a prediction of exact runtime

If a kernel performs F operations and transfers Q bytes across the memory
boundary we are studying, a simple lower bound on its time is:

$$
t \ge \max\left(\frac{F}{P},\frac{Q}{B}\right)
$$

Here P is peak compute throughput for the **actual arithmetic path and data type**,
and B is bandwidth at that memory boundary. Equivalently:

$$
\text{achieved FLOP/s} \le \min(P,\; \text{AI} \times B),
\qquad \text{AI}=F/Q
$$

![The lower of the bandwidth and compute ceilings bounds performance.](/gpu-matmul-assets/figures/roofline.svg)
*Figure 3.5. The lower of the bandwidth and compute ceilings bounds performance.*

<details>
<summary>Walk through Figure 3.5</summary>

1. The horizontal axis is arithmetic intensity, in FLOP per byte across the chosen memory boundary. The vertical axis is FLOP/s. Both axes are logarithmic: equal distances represent ratios, not equal numerical increments.

2. Follow the blue rising line until it meets the red flat line. More reuse raises the bandwidth ceiling; after the ridge, compute throughput supplies the lower ceiling. The example ridge is 60 TFLOP/s ÷ 2 TB/s = 30 FLOP/byte.

3. The gray points are illustrations, not benchmark measurements. A point may fall below either ceiling because of dependencies or other costs. Moving right does not automatically move a measured kernel onto the roof.

[Open the full-size figure](/gpu-matmul-assets/figures/roofline.svg).

</details>

For an illustrative FP32 processor with P=60 TFLOP/s and B=2 TB/s, the two
ceilings meet at `60/2 = 30 FLOP/byte`. Below that **ridge point**, the bandwidth
bound is lower. Above it, the compute bound is lower. Real performance may sit
well below either ceiling because of dependencies, instruction overhead, or
insufficient parallelism.

Do not compare our ordinary FP32 kernel to the much higher BF16 Tensor Core
ceiling. That ceiling belongs to a different arithmetic path. Likewise, do not
multiply a count of per-thread requested bytes by HBM bandwidth and call it a
measured memory limit.

**Check yourself:** A kernel performs 100 GFLOPs and moves 10 GB from HBM. With
2 TB/s HBM bandwidth, what is its memory-time lower bound?

<details>
<summary>Answer</summary>

`10 GB / 2,000 GB/s = 0.005 s = 5 ms`. Its HBM intensity is 10 FLOP/byte,
so the corresponding bandwidth ceiling is 20 TFLOP/s. This does not establish
that the kernel achieves that rate.

</details>

#### 8.5 Pitfall 3: quantization (work comes in discrete chunks)

**Tile quantization.** If a block computes a 32×32 tile but the matrix is 4100 wide, the last column of blocks covers only 4 useful columns.
The other 28 columns of threads exist, take up resources, and do nothing.

![Edge blocks contain thread positions that do not correspond to valid outputs.](/gpu-matmul-assets/figures/tile_quantization.svg)
*Figure 3.6. Edge blocks contain thread positions that do not correspond to valid outputs.*

<details>
<summary>Walk through Figure 3.6</summary>

1. The black rectangle is the real M×N output. Orange dashed lines divide the launched work into equal block tiles; the last tiles extend beyond the black boundary.

2. Amber positions produce valid outputs. Hatched positions are outside the matrix but are included by rounding the grid dimensions upward. For width 4100 and 32-wide tiles, the final tile has four valid columns and 28 invalid ones.

3. The early exit shown applies to the naive kernel. In a cooperating shared-memory kernel, edge threads must still perform required loads and reach barriers; guard accesses and stores instead of returning before synchronization.

[Open the full-size figure](/gpu-matmul-assets/figures/tile_quantization.svg).

</details>

**Wave quantization.** A **wave** is one round of blocks that fills every SM at once. Article example (H100 PCIe, 114 SMs, 2 blocks per SM):

$$
\text{blocks} = \frac{4096}{32} \times \frac{4096}{32} = 16{,}384, \qquad
\text{per wave} = 114 \times 2 = 228, \qquad
\frac{16{,}384}{228} \approx 71.9 \text{ waves}
$$

So 71 full waves plus a **partial** last wave. A worse case: 115 equal blocks on 114 SMs (one block per SM) takes **2 full rounds** of time,
and in the second round 113 SMs sit idle. This is the **tail effect**.

![One extra block can create a nearly empty final round in this simplified scheduling example.](/gpu-matmul-assets/figures/wave_quant.svg)
*Figure 3.7. One extra block can create a nearly empty final round in this simplified scheduling example.*

<details>
<summary>Walk through Figure 3.7</summary>

1. Read the three panels from top to bottom. There are 115 equal-duration blocks and 114 SMs, with room for one block per SM. Small purple squares in the queue are symbolic; not all 115 are drawn.

2. At t1, 114 blocks run and one waits. At t2, the remaining block runs alone while 113 SMs are idle. The bottom bar compares equal-duration rounds and shows unused SM capacity in the second round.

3. Real scheduling is not a global wave barrier, and block durations can differ. This model isolates tail inefficiency. Persistent scheduling alone cannot turn 115 indivisible equal tasks into two full rounds.

[Open the full-size figure](/gpu-matmul-assets/figures/wave_quant.svg).

</details>

The sizes determine how important these losses are. A partial final wave is negligible in a long run of full waves and can dominate a very short run.

---

### 9. The big idea: tiling and reuse

#### 9.1 From "one thread, one cell" to "one block, one tile"

The naive kernel already assigns a rectangular region of outputs to each block.
The new idea is **cooperation on the input data**: threads load a tile together,
reuse it from shared memory, and coordinate when it can be overwritten.

Start with the top-left 2×2 tile of our 4×4 output. In the first K step, load:

```text
A rows 0,1; columns 0,1     B rows 0,1; columns 0,1
[1 2]                      [1 0]
[5 6]                      [0 1]

partial C = [1 2]
            [5 6]
```

In the second K step, load the next two columns of A and the next two rows of B:

```text
[3 4] × [1 0] = [3 4]      final C tile = [1 2] + [3 4] = [ 4  6]
[7 8]   [0 1]   [7 8]                     [5 6]   [7 8]   [12 14]
```

![Two K chunks add contributions to the same top-left 2×2 tile of C.](/gpu-matmul-assets/figures/beginner_tiling_steps.svg)
*Figure 3.8. Two K chunks add contributions to the same top-left 2×2 tile of C.*

<details>
<summary>Walk through Figure 3.8</summary>

1. The top row uses A columns 0–1 and B rows 0–1. The second row uses A columns 2–3 and B rows 2–3. Output rows 0–1 and columns 0–1 stay fixed in both steps; slices [0:2] include 0 and 1.

2. Each small matrix product contributes to all four output cells. Follow the bottom-right cell: the first chunk contributes 6, the second 8, and their sum is C[1,1]=14.

3. The bottom panel adds the two contributions element by element. A real tiled kernel keeps running accumulators; it need not store both contribution matrices separately. Here each loaded A or B value serves two outputs.

[Open the full-size figure](/gpu-matmul-assets/figures/beginner_tiling_steps.svg).

</details>

Each step loads eight values for four outputs. Each loaded A value serves two
output columns; each B value serves two output rows. Without cooperative reuse,
four independent threads request sixteen input values for the same two k values.
This is a count of requested elements; caches may already reduce physical traffic.

We call the output dimensions **BM** (rows) and **BN** (columns), and the K-step
length **BK**. Here all three are 2. In a larger design, an output tile might be
128×128, with K processed in steps of 16:

![One block keeps its C tile fixed while moving through matching slices of A and B.](/gpu-matmul-assets/figures/warp_tiling_pt1.svg)
*Figure 3.9. One block keeps its C tile fixed while moving through matching slices of A and B.*

<details>
<summary>Walk through Figure 3.9</summary>

1. Find the amber square in C. Its output rows select a horizontal blue panel of A; its output columns select a vertical red panel of B. BM=BN=128 describe the output, while BK=16 is the reduction-step width.

2. Follow the blue arrow right through A and the red arrow down through B together. At each step, a 128×16 A slice multiplies a 16×128 B slice and contributes to every entry of the same 128×128 C tile.

3. The 256 steps are K/BK = 4096/16; they are not 256 output tiles. The second outlined C tile belongs to another block. This figure scales up the 2×2 teaching example; it uses different dimensions from the runnable 16×16 kernel.

[Open the full-size figure](/gpu-matmul-assets/figures/warp_tiling_pt1.svg).

</details>

$$
C_{\text{tile}} = \sum_{\text{steps } s} A_{\text{tile}}^{(s)} \times B_{\text{tile}}^{(s)}
$$

The identity is exact in real arithmetic. Floating-point additions round, so regrouping a sum may change low-order bits. Our simple tiled loop preserves the k order; later matrix instructions may use a different accumulation order.

![Splitting the reduction dimension into chunks preserves the real-arithmetic dot product.](/gpu-matmul-assets/figures/block_tile_equivalence.svg)
*Figure 3.10. Splitting the reduction dimension into chunks preserves the real-arithmetic dot product.*

<details>
<summary>Walk through Figure 3.10</summary>

1. The top blue row and red column produce one output, C[0,0]. B’s column is drawn horizontally so the two lists of K values can be lined up; B has not necessarily been transposed in memory.

2. In the lower panel, matching colors mark matching ranges of k in the two inputs. Multiply corresponding entries in one chunk, form its partial sum, then add all the chunk contributions.

3. Each small colored square at the bottom is a partial scalar sum, not a different output cell. Regrouping floating-point additions may change rounding; the diagram expresses the mathematical decomposition.

[Open the full-size figure](/gpu-matmul-assets/figures/block_tile_equivalence.svg).

</details>

Another way to see the same thing: a matmul is a **sum of outer products**. Each k contributes "column k of A × row k of B", a full M×N layer,
and C is all K layers added up. Tiling just groups those layers into chunks of BK.

![At a fixed k, an A column and a B row contribute a product to every output cell.](/gpu-matmul-assets/figures/outer.svg)
*Figure 3.11. At a fixed k, an A column and a B row contribute a product to every output cell.*

<details>
<summary>Walk through Figure 3.11</summary>

1. Read the panels left to right: k=0, k=1, then the final k. In each panel, the highlighted A column pairs with the highlighted B row. The outer-product symbol means multiply every selected A entry by every selected B entry.

2. Follow only the small highlighted C[2,3] cell first. Its contributions are A[2,0]B[0,3], then A[2,1]B[1,3], and so on. The formula along the bottom adds these into the familiar dot product.

3. The larger tinted C area means all outputs receive a contribution at that step. It does not mean the full multiplication has finished after one outer product, or that the program must allocate intermediate matrices.

[Open the full-size figure](/gpu-matmul-assets/figures/outer.svg).

</details>

#### 9.2 The algorithm

```
for this block's output tile:
    acc = 0                                   (in registers)
    for each K-chunk s:
        cooperatively load A_tile(s), B_tile(s): GMEM → SMEM
        __syncthreads()     // wait: everyone finished WRITING SMEM
        acc += A_tile(s) @ B_tile(s)          (read SMEM, math in registers)
        __syncthreads()     // wait: everyone finished READING before it's overwritten
    write acc → C (GMEM)
```

Both barriers (`__syncthreads()`) are essential:

- The first stops threads from reading SMEM before others have finished writing it.

- The second stops a fast thread from overwriting a tile that a slow thread is still reading.

Here is the edge-safe version used in the executable. It requires a block
shape of `dim3(T,T)`, with T=16 in the example:

```cuda
constexpr int T = 16;
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
```

`__shared__` declares arrays shared by threads of **this block**. Each thread
loads one A value and one B value per step. Out-of-range inputs become zero,
which contributes nothing to the sum. Every thread reaches both barriers, even
when its own output is outside the matrix. Only the final store is conditional.

Do not return early for edge threads before these barriers. A thread whose output
is outside the matrix may still need to load data for other threads, and barriers
must be reached consistently by the block's participating threads.

For a full T×T tile, each loaded value is reused T times. With T=16, that is
16 uses per value. Edge tiles have less useful work.

**Check yourself:** Why is the second barrier needed if the first one already
waited for all loads?

<details>
<summary>Answer</summary>

The first barrier protects readers from incomplete writes. The second protects
the current readers from the **next iteration's** writes into the same arrays.
One thread finishing its arithmetic does not mean all other threads have finished.

</details>

#### 9.3 Why bigger tiles mean more reuse, worked out

Per K-step, a block loads `BM·BK + BK·BN` elements and does `2·BM·BN·BK` FLOPs:

$$
\text{AI}_{\text{tile}} = \frac{2 \cdot BM \cdot BN \cdot BK}{(BM + BN)\cdot BK \cdot \text{bytes}} = \frac{2 \cdot BM \cdot BN}{(BM + BN) \cdot \text{bytes}}
$$

BK cancels out. **Reuse depends on the output tile's size and shape.**

| Tile (BM×BN) | dtype | FLOP/byte of input loads into the block tile |
|---|---|---|
| 1×1 (naive) | fp32 | 0.25 |
| 32×32 | fp32 | 8 |
| 128×128 | fp32 | 32 |
| 128×128 | bf16 | 64 |
| 128×256 | bf16 | ~85 |

Two lessons:

- **Bigger tiles = more reuse.**

- For a fixed area, **square tiles are best**: BM+BN is smallest relative to BM·BN when BM = BN.

![For four outputs, a square patch needs fewer input values than a thin strip.](/gpu-matmul-assets/figures/arithmetic_intensity.svg)
*Figure 3.12. For four outputs, a square patch needs fewer input values than a thin strip.*

<details>
<summary>Walk through Figure 3.12</summary>

1. Compare the middle and right panels, which both compute four amber output cells. The 4×1 strip needs four A rows and one B column: 5K requested input values.

2. The 2×2 square needs two A rows and two B columns: 4K values. Dividing by four outputs gives 1.25K versus K input values per result. The left panel is the one-output baseline.

3. These are element counts over the full reduction dimension, excluding stores and cache effects. The lesson is reuse in both output directions, not that the squarer tile must win after register limits and scheduling are included.

[Open the full-size figure](/gpu-matmul-assets/figures/arithmetic_intensity.svg).

</details>

These counts exclude output writes, partial tiles, and cross-block cache reuse.
They describe the tile's input traffic, not measured HBM traffic. L2 hits can
make HBM traffic smaller. Bigger BK does not change this particular reuse ratio,
but it does change shared-memory capacity, synchronization frequency, and how a
pipeline can be organized.

#### 9.4 The same trick, again, one level down: warp tiles and thread tiles

Tiling applies at **every** level of the hierarchy:

```
whole matrix C
  └─ block tile  (e.g. 128×128)  ← data staged in SMEM
      └─ warp tile  (e.g. 64×32)   ← each warp owns a sub-tile
          └─ thread tile (e.g. 8×8)   ← each thread accumulates 64 outputs IN REGISTERS
```

**Why thread tiles?** A thread computing an 8×8 patch, at each k step:

- loads **8** values of A and **8** values of B from SMEM into registers (16 loads),

- does **8×8 = 64** FMAs.

That's 4 FMAs per SMEM load, versus about 0.5 in the simple tiled kernel. Registers become the busy layer and SMEM traffic drops.

The article's kernel uses a slightly different split (each thread owns four 8×4 pieces), but the idea is identical:

![A thread can own several separated patches while holding all its partial results in registers.](/gpu-matmul-assets/figures/warp_tiling_pt3_compute.svg)
*Figure 3.13. A thread can own several separated patches while holding all its partial results in registers.*

<details>
<summary>Walk through Figure 3.13</summary>

1. The left 128×128 output tile is split among four warps, each owning 64×64 outputs. Colors here identify warps. The dashed zoom enlarges warp 0’s tile.

2. The right grid labels thread positions, not individual matrix-element coordinates. The example thread at threadRowInWarp=1 and threadColInWarp=1 owns matrix rows 8–15 and four groups of columns: 4–7, 20–23, 36–39, and 52–55.

3. The four red patches are all owned by that one thread: 4×8×4=128 outputs. This is a particular optimized layout, distinct from the earlier illustrative 8×8 thread tile. Spatially separated outputs can still be accumulated by one thread.

[Open the full-size figure](/gpu-matmul-assets/figures/warp_tiling_pt3_compute.svg).

</details>

![The highlighted thread gets 128 multiply-adds from 24 shared-memory input values per k step.](/gpu-matmul-assets/figures/warp_tiling_pt3_compute_2.svg)
*Figure 3.14. The highlighted thread gets 128 multiply-adds from 24 shared-memory input values per k step.*

<details>
<summary>Walk through Figure 3.14</summary>

1. Start at the two top arrays. As stores transposed A, so row dotIdx contains an original A column. The selected eight As entries supply regM. Four groups of four Bs entries supply the sixteen values of regN.

2. The arrows copy those values into registers. Each regM value multiplies all sixteen regN values, filling the 8×16 accumulator diagram: 128 multiply-adds from 8+16 input values.

3. Dashed vertical lines separate the four output-column groups from the preceding figure. Repeat dotIdx=0 through 15 for this K chunk. The accumulator values remain live across later chunks; they are stored to C only at the end.

[Open the full-size figure](/gpu-matmul-assets/figures/warp_tiling_pt3_compute_2.svg).

</details>

The data flow becomes:

```
global loads (possibly cached) → SMEM → registers → repeated FMAs
```

The key change is planned reuse at each level, rather than repeatedly requesting inputs without coordinating their reuse.

#### 9.5 More classic tricks from the article's warp-tiling kernel

- **Vectorized loads:** load 4 floats (128 bits) per instruction (`LDG.128` from GMEM, `LDS.128` from SMEM) instead of 4 separate loads. Fewer instructions, same bytes.
- **Transpose A in SMEM:** store A column-wise in SMEM so that the inner loop can read A with vectorized, conflict-free loads.
  The stores become scattered and awkward, but they happen **once per tile**, while the reads happen **many times**.

> **Optimize the access pattern that happens most often.**

![A is read contiguously, then stored transposed to favor the later compute loop.](/gpu-matmul-assets/figures/warp_tiling_pt2_smem_load.svg)
*Figure 3.15. A is read contiguously, then stored transposed to favor the later compute loop.*

<details>
<summary>Walk through Figure 3.15</summary>

1. Follow the numbered panels. First arrange 128 loading threads as 32 rows of four threads. Each thread loads a float4, meaning four FP32 values or 16 bytes. Four threads therefore cover one 16-element row of the A tile.

2. One pass covers 32 rows; four passes cover all 128 rows. The colors identify the loading warp. Thread 0, for example, loads A[0,0:4] during the first pass.

3. The lower panel applies A[r,c] → As[c,r]. Thread 0’s values become As[0:4,0], separated in the shared-memory layout. This makes those stores less convenient but gives the repeatedly executed compute loop a better read layout. It is not a general rule to transpose every A tile.

[Open the full-size figure](/gpu-matmul-assets/figures/warp_tiling_pt2_smem_load.svg).

</details>

![B keeps its layout, so both its loads and shared-memory stores can be vectorized.](/gpu-matmul-assets/figures/warp_tiling_pt2_smem_load_b.svg)
*Figure 3.16. B keeps its layout, so both its loads and shared-memory stores can be vectorized.*

<details>
<summary>Walk through Figure 3.16</summary>

1. The top panel arranges the same 128 loading threads as four rows of 32. A warp’s 32 lanes each load four floats, together covering one 128-element B row.

2. In pass 0, warps 0–3 load rows 0–3. The next pass loads rows 4–7. Four passes cover the 16×128 tile. Thread 0 loads B[0,0:4], then B[4,0:4], and so on.

3. Compare the two lower panels: the colored rows retain their positions in Bs. The straight arrow means a copy with the same logical layout, unlike A’s transpose in the previous picture. LDG and STS label global loads and shared-memory stores; 128 means bits per instruction, not bytes.

[Open the full-size figure](/gpu-matmul-assets/figures/warp_tiling_pt2_smem_load_b.svg).

</details>

**Result:** a well-tuned classic kernel reaches tens of TFLOP/s in fp32 without any Hopper-specific features. The mathematical operation is unchanged. Register reuse, memory layout, and instruction organization all contribute to the result.

---

### 10. Check correctness, then explain performance

**Learning goal:** distinguish a kernel measurement from an application speedup
and test an optimization without changing several variables at once.

#### 10.1 Correctness comes first

For every optimization, compare the complete result with a reference. Include
rectangular matrices, dimensions smaller than a tile, dimensions not divisible
by a tile, zeros, and mixed-sign inputs. A kernel that works only on 4096×4096
inputs may have an indexing bug hidden by that convenient shape.

Use a documented tolerance, for example:

```text
abs(actual - reference) <= absolute_tolerance + relative_tolerance * abs(reference)
```

Also reject nonfinite output when finite results are expected. A tolerance is
part of the numerical contract, not permission to ignore arbitrary errors.
Long sums, cancellation, and lower-precision input conversion need additional
care. The example's simple inputs and tolerance are a starting point.

#### 10.2 What exactly did the timer measure?

A kernel launch normally returns to the CPU before the GPU finishes. Timing
only the host launch call does not measure the kernel's execution time.

Our executable records CUDA events before and after repeated launches in the
same stream, waits for the stop event, and divides the elapsed time by the number
of repetitions. A **stream** is an ordered sequence of GPU operations; this
example uses the default stream for everything. It also performs warm-up launches
outside the timed region.

The resulting number excludes allocation, CPU reference calculation, and the
initial and final host/device copies. Report it as **kernel timing**, not as the
time for the entire application. For tiny kernels, launch and submission effects
can dominate even a repeated measurement.

Repeated use of the same arrays can keep data in cache. A working set larger
than L2, or a benchmark that rotates buffers, can behave differently. Describe
which workload you measured; do not silently compare warm-cache and cold-cache
results.

#### 10.3 Make a useful experiment table

Run the same shapes and data types for both kernels. Try 32×32×32,
37×53×29, 256×256×256, and 512×512×512 before increasing sizes.

| Record | Why it matters |
|---|---|
| GPU model, toolkit, compiler flags | Hardware and compilation affect the result |
| M, N, K; input and accumulator types | Defines the actual problem |
| Block and tile sizes | Determines work mapping and resource use |
| Correctness result and tolerance | A faster incorrect answer is not an improvement |
| Repeated timings and variation | One sample can be misleading |
| Timing boundary | Distinguishes kernel time from transfers and total time |

For elapsed time t in seconds, report `2*M*N*K/t` FLOP/s. This is a conventional
useful-work count; it does not count padded arithmetic as useful work. The simple
tiled kernel is not guaranteed to beat the naive kernel on every size or device.
It adds synchronization and load instructions, while the naive kernel may benefit
from caches already.

#### 10.4 Ask the profiler a specific question

First form a hypothesis: “This change should reduce shared-memory loads,” or
“These blocks leave too few independent warps resident.” Then inspect evidence.
A profiler records measurements of hardware activity; it does not automatically
identify the best algorithm.

Nsight Systems helps examine the application timeline, including transfers and
gaps between kernels. Nsight Compute examines a kernel's memory traffic,
instruction behavior, and resource use. Names and availability of individual
metrics depend on the device and tool version; use the corresponding tool's
documentation when running an experiment.

Keep unprofiled timing runs separate: profiling can add overhead or replay work.
If a change reduces one kind of traffic without improving time, another resource
may now be the limit. Revisit the roofline and the dependency structure.

#### 10.5 A small kernel speedup may barely affect the program

Suppose 40% of application time is spent in a kernel and 60% elsewhere. Making
the kernel twice as fast changes normalized runtime to `0.60 + 0.40/2 = 0.80`.
The application becomes 1.25× faster, not 2×. This is **Amdahl's law** in a concrete
example.

**Checkpoint:** Before moving to hardware details, you should be able to trace
the naive and tiled kernels, explain both barriers, distinguish requested loads
from HBM bytes, and say what your timing includes. That is a complete first
milestone; the next parts explain how the hardware supports and limits it.

For timing and profiling details, consult the [CUDA Best Practices Guide](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html), [Nsight Compute Profiling Guide](https://docs.nvidia.com/nsight-compute/ProfilingGuide/index.html), and [Nsight Systems User Guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html).

---

## Part 4: A closer look at the hardware


This is the second pass through memory and execution. You now have concrete kernels to connect to DRAM, cache lines, banks, throughput ceilings, and generated instructions. Read Chapter 11 before the Hopper layouts; the assembly details can wait until you need them.

- [11. How each memory really works](#11-how-each-memory-really-works)
- [12. The "speed of light"](#12-the-speed-of-light)
- [13. Talking to the hardware: CUDA, PTX, SASS](#13-talking-to-the-hardware-cuda-ptx-sass)


---

### 11. How each memory really works

Knowing the hierarchy isn't enough. You need to know **how each level prefers to be accessed**,
because GPU "rules" like *coalesce your loads* and *avoid bank conflicts* follow directly from the hardware.

#### 11.1 GMEM: DRAM likes neighbors

Global memory is **DRAM**. A simple DRAM cell stores a bit using a capacitor and an access transistor; sensing its charge disturbs it, so the sense amplifier restores the value.
DRAM is organized in **rows**. Reading starts by "opening" a whole row into a row buffer, which is slow. After that, reading neighboring bytes from the open row is fast.
Data also moves through the caches in fixed-size chunks: **128-byte cache lines**, split into four **32-byte sectors**.

![A DRAM cell stores a bit as charge, which must be sensed and restored.](/gpu-matmul-assets/figures/gmem_dram_cell.svg)
*Figure 4.1. A DRAM cell stores a bit as charge, which must be sensed and restored.*

<details>
<summary>Walk through Figure 4.1</summary>

1. The dashed outline encloses one cell. The two green plates are a capacitor storing charge. The transistor acts as a switch connecting it to the vertical bitline; the horizontal wordline controls that switch.

2. During a read, charge sharing produces a small signal on the bitline. A sense amplifier, outside this cell drawing, detects the stored value and restores it. The read disturbs charge; it does not work like reading a software variable without affecting storage.

3. The 0 V symbol marks a voltage reference, not a matrix element. Periodic refresh also counters leakage. This explains a physical cost of DRAM; it is not enough by itself to predict a kernel’s memory latency.

[Open the full-size figure](/gpu-matmul-assets/figures/gmem_dram_cell.svg).

</details>

![A DRAM access selects a row first, then data within the activated row.](/gpu-matmul-assets/figures/gmem.svg)
*Figure 4.2. A DRAM access selects a row first, then data within the activated row.*

<details>
<summary>Walk through Figure 4.2</summary>

1. Trace the green address field to row 4 in the lower array. Activating that wordline allows the sense amplifiers to capture the row; the curved green arrow depicts that operation.

2. Now follow the blue field to column selection 2 in the upper buffer. The row buffer can supply selected pieces without reopening the same row for each piece.

3. A row here is a physical DRAM row, not a row of A or B. Address mapping also involves banks and channels. The channel counts and 32-byte atom in the lower inset are a particular HBM example, not universal constants across memory generations.

[Open the full-size figure](/gpu-matmul-assets/figures/gmem.svg).

</details>

![Row-major indexing makes a row walk contiguous and a column walk strided.](/gpu-matmul-assets/figures/gmem_example.svg)
*Figure 4.3. Row-major indexing makes a row walk contiguous and a column walk strided.*

<details>
<summary>Walk through Figure 4.3</summary>

1. The top-left matrix has 256 FP32 values per row. The top-right drawing flattens its rows into memory: row 0 occupies byte offsets 0–1023 and row 1 starts at 1024.

2. Follow the green horizontal arrows: changing col by one advances four bytes. Follow the red vertical arrows: changing row by one advances 256×4=1024 bytes.

3. This proves the address strides, not the number of physical DRAM row activations. A software row need not match a DRAM row. On a GPU, also inspect addresses across a warp at one instruction, not only one thread’s loop order.

[Open the full-size figure](/gpu-matmul-assets/figures/gmem_example.svg).

</details>

![The illustrated bandwidth falls as useful reads become farther apart.](/gpu-matmul-assets/figures/gmem_example_2.svg)
*Figure 4.4. The illustrated bandwidth falls as useful reads become farther apart.*

<details>
<summary>Walk through Figure 4.4</summary>

1. Read the horizontal axis as byte stride between accesses and the vertical axis as achieved GB/s. Both are logarithmic, so the spacing represents multiplicative changes.

2. Compare the circled endpoints: about 1,418 GB/s for closely spaced reads and 111 GB/s at a 1,024-byte stride, a ratio near 12.8. These are approximate A100 results reproduced from the source case study, not measurements from this tutorial’s H100 kernels.

3. The burst/page annotations belong to that experiment. The trend motivates examining access patterns; do not transfer the exact rates to different data widths, cache states, or GPUs.

[Open the full-size figure](/gpu-matmul-assets/figures/gmem_example_2.svg).

</details>

So:

```
read x[0], x[1], x[2], x[3] ...         → a few big transfers   ✅ fast
read x[0], x[1000], x[2000], x[3000]... → many separate transfers ❌ slow
```

#### 11.2 Coalescing: the most important GMEM rule

When the 32 threads of a warp each issue a load, the hardware tries to **merge (coalesce)** them into as few memory transactions as possible.

**Good: adjacent threads read adjacent addresses**

```
thread 0 → x[0], thread 1 → x[1], ..., thread 31 → x[31]
32 threads × 4 bytes = 128 bytes → four 32-byte sectors (aligned case)
```

**Bad: adjacent threads read far-apart addresses (large stride)**

```
thread 0 → x[0], thread 1 → x[4096], thread 2 → x[8192], ...
→ up to 32 separate transactions, each fetching 32 bytes to use only 4
→ up to 8× wasted bandwidth, plus far more requests
```

**Special case:** if all 32 threads read the **same** address, the hardware fetches it once and **broadcasts** it. That's cheap.

Motto: **neighbors good, large strides bad.**

#### 11.3 SMEM: 32 banks

Shared memory is on-chip SRAM that **your code manages explicitly**: you decide what goes in and when.
It's split into **32 banks**, each **4 bytes wide**. Consecutive 4-byte words go to consecutive banks, wrapping around:

$$
\text{bank} = \left(\frac{\text{byte address}}{4}\right) \bmod 32
$$

```
address (bytes):  0   4   8  ...  124 | 128 132 ... 252 | 256 ...
bank:             0   1   2  ...   31 |  0   1  ...  31 |  0  ...
```

Think of 32 bank tellers. For the simple 32-bit access pattern below, each bank can supply one distinct word per service step. This models conflicts, not the total instruction latency.

![Consecutive four-byte words rotate through 32 shared-memory banks.](/gpu-matmul-assets/figures/smem_pt1.svg)
*Figure 4.5. Consecutive four-byte words rotate through 32 shared-memory banks.*

<details>
<summary>Walk through Figure 4.5</summary>

1. Each vertical column is a bank, numbered 0–31. Each small square is one four-byte word. The horizontal “rows” are groups of 128 bytes in this explanatory layout, not necessarily rows of your C++ array.

2. Trace byte address 0 to bank 0, address 4 to bank 1, and address 128 back to bank 0 on the next drawn row. The mapping is floor(byte_address/4) modulo 32.

3. Two different words can belong to the same bank. Whether that causes a conflict depends on whether lanes request them in the same serviced access. The 228 KiB annotation is a per-SM capacity, not the size of one thread’s allocation.

[Open the full-size figure](/gpu-matmul-assets/figures/smem_pt1.svg).

</details>

- If the lanes access **32 different banks**, the access needs no extra passes due to bank conflicts.

- If lanes access **different words in the same bank**, the hardware needs additional service passes. This is a **bank conflict**.

- If lanes read the **same word**, a **broadcast** avoids that conflict. It is not a zero-latency memory access.

The examples use one 32-bit word per lane. Wider instructions and matrix loads
need analysis at their actual transaction granularity. A 32-way conflict does not
mean the entire kernel becomes exactly 32 times slower.

![Conflicts depend on bank columns, not on whether highlighted words share a drawn row.](/gpu-matmul-assets/figures/smem_pt2.svg)
*Figure 4.6. Conflicts depend on bank columns, not on whether highlighted words share a drawn row.*

<details>
<summary>Walk through Figure 4.6</summary>

1. In the upper panel, highlighted words cluster in a few bank columns. Bank 2 has three different requested words and needs additional service passes. Those are different addresses, so one broadcast cannot satisfy them.

2. In the lower panel, the highlighted words occupy different bank columns, even though they come from different drawn rows. They do not compete for the same bank in this scalar access model.

3. Count requested words per bank, not the distance between highlights. Extra bank-conflict passes are not the entire load latency and do not directly multiply the runtime of the whole kernel.

[Open the full-size figure](/gpu-matmul-assets/figures/smem_pt2.svg).

</details>

![Several lanes reading exactly the same word can share a broadcast.](/gpu-matmul-assets/figures/smem_pt3.svg)
*Figure 4.7. Several lanes reading exactly the same word can share a broadcast.*

<details>
<summary>Walk through Figure 4.7</summary>

1. Follow T0, T1, and T2: their arrows converge on the same highlighted word in bank 0. T3 and T4 similarly request one word in bank 1.

2. Each bank needs to supply only one distinct word. Compare this with the previous figure, where one bank was asked for several different words.

3. The arrows show reads. They do not make multiple writes to one location safe, and “no bank conflict” does not mean zero latency.

[Open the full-size figure](/gpu-matmul-assets/figures/smem_pt3.svg).

</details>

**Worked example: column reads cause conflicts.** A tile `float tile[32][32]` stored row-major:

```c
// Thread t reads tile[t][c] — walking DOWN column c
address = (t * 32 + c) * 4
bank    = (t * 32 + c) % 32 = c        // the same bank for every t!
```

All 32 threads hit bank `c`: a **32-way conflict**. Reading a *row* (`tile[r][t]`) is fine: bank = `t`, all different.

**Classic fix: padding.** Declare `float tile[32][33]` (one extra column):

```c
bank = (t * 33 + c) % 32 = (t + c) % 32  // a different bank for every t ✅
```

Padding wastes a bit of memory. Hopper's preferred fix, **swizzling**, wastes none. See [§14.2](#142-swizzling-shuffling-addresses-to-dodge-bank-conflicts).

#### 11.4 L1: an automatic cache

L1 is **hardware-managed**. For loads that use L1, a cache **hit** supplies present data and a **miss** requires another level. Some instructions and cache policies bypass L1.
It's a **k-way set-associative** cache: each memory address can live in only a few specific slots, and when those fill up, an old line is evicted.

![A cached global load needs a lookup; a shared-memory access names its storage directly.](/gpu-matmul-assets/figures/l1.svg)
*Figure 4.8. A cached global load needs a lookup; a shared-memory access names its storage directly.*

<details>
<summary>Walk through Figure 4.8</summary>

1. Start at a scheduler on the left. MIO is the queue drawn for memory instructions, and LSUIN is the routing stage. The diagram separates the shared-memory path from the global-load path that uses L1.

2. Follow a global load through the tag stage: a hit goes to the data array; a miss requests data from L2, fills the cache, then returns the data along the top arrow. L2 itself may satisfy the miss without an HBM access.

3. Follow the green shared-memory path instead: it bypasses the cache tag lookup. This is a simplified routing diagram, not a cycle-accurate pipeline; cache-bypassing instructions and bank conflicts need separate consideration.

[Open the full-size figure](/gpu-matmul-assets/figures/l1.svg).

</details>

![A set-associative cache narrows the lookup to a few candidate lines.](/gpu-matmul-assets/figures/kway.svg)
*Figure 4.9. A set-associative cache narrows the lookup to a few candidate lines.*

<details>
<summary>Walk through Figure 4.9</summary>

1. Read the address fields from right to left: offset selects a byte within a line, set index selects one set, and tag identifies which memory line is stored there. In this illustrative layout, 7 offset bits cover 128 bytes and 10 set bits cover 1024 sets.

2. The blue arrow selects set 1, which has four possible locations called ways. Compare the requested tag with the tags in those four ways. A valid matching entry is a hit; otherwise the cache needs a refill and may replace a line.

3. The inset shows four 32-byte sectors inside a line. The bit split and replacement example teach the mechanism; they are not a published exact H100 address hash, replacement algorithm, or list of cache-control flags.

[Open the full-size figure](/gpu-matmul-assets/figures/kway.svg).

</details>

| | L1 cache | Shared memory |
|---|---|---|
| Who decides what's stored? | the hardware | **you** |
| Who controls lifetime? | hardware replacement policy | program, subject to correct synchronization |
| Best for | irregular access | known reuse patterns, like matmul tiles |

Matmul's reuse pattern is perfectly predictable, so fast kernels manage it explicitly with shared memory.

#### 11.5 L2: the shared storeroom

L2 (50 MB) is shared by all SMs. Physically it's split into **two partitions**, each wired to half of the GPCs through a **crossbar**.
If SM 5 loaded a piece of B a moment ago and SM 80 needs the same piece now, SM 80 gets an L2 hit instead of a trip to HBM.
This becomes important in [§15.9](#159-smarter-tile-order-hilbert-curves--764-tflops).

#### 11.6 Separate three reasons a memory access can be expensive

| Problem | What goes wrong | First experiment |
|---|---|---|
| Poor coalescing | Lanes request too many sectors for the useful bytes | Change the lane-to-address mapping |
| Poor cache locality | Needed values are absent or evicted before reuse | Change working-set size or traversal order |
| Shared-memory bank conflicts | Different words compete for the same bank in an access | Change the shared-memory layout |

These are related through layout, but they are not interchangeable. A fully
coalesced load may still miss the cache; a cache hit does not guarantee useful
arithmetic; a shared-memory array can still have bank conflicts.

This is where Drepper's locality argument meets the GPU execution model. On a
CPU, we first studied addresses over time. On a GPU, also inspect addresses
across the lanes of each issued instruction.

---

### 12. The "speed of light"

#### 12.1 Definition

GPU engineers use **speed of light (SoL)** for a hardware throughput ceiling. There are different ceilings for different units and data types. For a particular Tensor Core arithmetic mode:

$$
\text{peak FLOP/s} = \text{clock frequency} \times \text{number of Tensor Cores} \times \text{FLOPs per Tensor Core per clock}
$$

**Worked example (H100 SXM, dense bf16):** 132 SMs × 4 Tensor Cores = 528 Tensor Cores, each doing 1024 bf16 FLOPs per clock, at ~1.83 GHz:

$$
528 \times 1024 \times 1.83 \times 10^{9} \approx 989 \text{ TFLOP/s}
$$

That matches NVIDIA's spec sheet (~989 dense bf16 TFLOP/s).

![The three factors count operations per clock across the chip, then clocks per second.](/gpu-matmul-assets/figures/h100_sol.svg)
*Figure 4.10. The three factors count operations per clock across the chip, then clocks per second.*

<details>
<summary>Walk through Figure 4.10</summary>

1. Read the boxes left to right. The clock is 1.83 billion cycles per second. The chip has 132 SMs×4 Tensor Cores = 528 Tensor Cores in this H100 SXM example.

2. The third box counts 1024 BF16 FLOPs per Tensor Core per cycle. Multiplying gives approximately 989×10¹² FLOP/s; the cycle and Tensor Core units cancel.

3. This is the dense BF16 Tensor Core ceiling at the stated clock, not an ordinary FP32-kernel rate. The bottom sparsity note concerns a different supported arithmetic mode, and the throttling note explains why the clock assumption matters.

[Open the full-size figure](/gpu-matmul-assets/figures/h100_sol.svg).

</details>

The **H100 PCIe** has 114 SMs (456 Tensor Cores). At its maximum clock of 1755 MHz that gives 456 × 1024 × 1.755 GHz ≈ **819 TFLOP/s**,
which is the number the article uses. Published product ratings may use different clock assumptions. Label a clock-based derivation separately from a product rating or an observed sustained rate.

#### 12.2 The clock isn't fixed: power throttling

A GPU must stay inside **power and thermal limits**. When all Tensor Cores are busy, power draw rises, and the GPU may **lower its clock** to stay within budget.

> **If the clock drops, the speed of light drops with it.**

![A longer clock period lowers the arithmetic-throughput ceiling even when the work is unchanged.](/gpu-matmul-assets/figures/clk.svg)
*Figure 4.11. A longer clock period lowers the arithmetic-throughput ceiling even when the work is unchanged.*

<details>
<summary>Walk through Figure 4.11</summary>

1. Each red square-wave period represents one clock cycle. Compare the horizontal brackets: about 0.55 ns per cycle at 1830 MHz versus 1 ns at 1000 MHz.

2. The same count of operations per cycle then produces fewer operations per second: 989×1000/1830 is about 541 TFLOP/s. The boxes are calculated ceilings, not two measured kernel results.

3. The drawing illustrates a possible lower clock, not a claim that every H100 drops to 1000 MHz. Voltage, power, temperature, and workload determine actual operating conditions.

[Open the full-size figure](/gpu-matmul-assets/figures/clk.svg).

</details>

So the *real* ceiling during a heavy matmul is often below the spec-sheet number. The achieved fraction depends on shape, arithmetic mode, clocks, and implementation; no fixed percentage is guaranteed.
(Horace He wrote about a fun consequence: matmuls on *random* data can run slower than on *zeros*, because flipping more bits burns more power and triggers more throttling.)

**Takeaway:** compare your kernel against the *achievable* ceiling under real clocks, not just the marketing number.

**Check yourself:** If the H100's BF16 matrix ceiling is about 989 TFLOP/s,
should a scalar FP32 kernel be judged against it?

<details>
<summary>Answer</summary>

No. Use the throughput ceiling for the arithmetic instructions and types the
kernel actually executes. Switching to Tensor Cores and different input precision
changes the comparison.

</details>

---

### 13. Talking to the hardware: CUDA, PTX, SASS

Your CUDA C++ goes through several compilation stages:

```
CUDA C++  ──nvcc──▶  PTX  ──ptxas/driver──▶  SASS  ──▶  GPU executes
(you write)        (virtual ISA)            (real machine code)
```

| Layer | What it is | Analogy |
|---|---|---|
| **CUDA C++** | C++ with GPU extensions | your source code |
| **PTX** | NVIDIA's *virtual* instruction set, compiled for a compatible target; individual features have architecture requirements | Java bytecode |
| **SASS** | the *actual* machine instructions for one specific architecture (e.g. `sm_90a` for Hopper) | x86 machine code |

![One CUDA program contains host code and device code, which follow different compilation paths.](/gpu-matmul-assets/figures/ptx_sass_hierarchy.svg)
*Figure 4.12. One CUDA program contains host code and device code, which follow different compilation paths.*

<details>
<summary>Walk through Figure 4.12</summary>

1. Start at CUDA C++ and follow the branch to the right for CPU code: a host compiler produces the executable’s CPU instructions. Follow the downward branch for GPU code: PTX describes a virtual instruction set, and ptxas produces target-specific machine code, SASS.

2. Inside the executable, the dashed fatbin box can hold device binaries for several architectures and PTX for later compilation by a compatible driver. A cubin is a packaged GPU binary, not a CPU function.

3. Arrows show build and packaging relationships, not the order of kernel execution. PTX compatibility has target and feature constraints; architecture-specific Hopper instructions are not made universally portable by being written in PTX.

[Open the full-size figure](/gpu-matmul-assets/figures/ptx_sass_hierarchy.svg).

</details>

(**ISA** = Instruction Set Architecture: the list of instructions a processor understands.)

**Why look at assembly?**

1. **To check what the compiler actually did.** Did it unroll the loop? Use 128-bit vector loads? Keep values in registers?
   The article finds the compiler unrolling a loop 4× in PTX and **16×** in SASS. You only learn that by looking.
   Tools: `cuobjdump -sass`, `nvdisasm`, or [godbolt.org](https://godbolt.org).
2. **Inspect low-level operations** such as `wgmma`, TMA, `mbarrier`, and `setmaxnreg` when their behavior matters. They may be exposed through CUDA APIs, libraries, or **inline PTX** (`asm volatile("...")`), depending on the feature and toolkit. Start with a supported high-level interface when one fits the task.

**Loop unrolling and ILP.** *Unrolling* means rewriting `for (k...) acc += a[k]*b[k];` as 4 or 16 copies of the body.
This can reduce loop overhead and expose independent loads or calculations. **ILP (instruction-level parallelism)** means overlapping independent instructions. Repeating updates to the same `acc` still forms a dependency chain; unrolling alone does not make those updates independent. Multiple accumulators are one way to expose more arithmetic independence.

> **Source code expresses intent. Assembly shows what actually happens.**

Hardware reference: the [Hopper Tuning Guide](https://docs.nvidia.com/cuda/hopper-tuning-guide/index.html) describes resource limits; the [Hopper architecture overview](https://developer.nvidia.com/blog/nvidia-hopper-architecture-in-depth/) distinguishes product configurations. Use the [CUDA Best Practices Guide](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html) for coalescing and shared-memory access rules.

---

## Part 5: Advanced matrix multiplication on Hopper


Advanced case study. You should understand shared-memory tiling, barriers, warps, arithmetic intensity, and register budgets. These chapters explain designs and invariants, not a complete runnable Hopper implementation. The early CUDA example does not require Hopper; executing these specific advanced instructions does.

- [14. Hopper hardware: TMA, swizzling, and WGMMA](#14-hopper-hardware-tma-swizzling-and-wgmma)
- [15. Building an asynchronous pipeline](#15-building-an-asynchronous-pipeline)
- [16. Reading the optimization results](#16-reading-the-optimization-results)


---

### 14. Hopper hardware: TMA, swizzling, and WGMMA

The kernels so far use ordinary instructions for address calculations, loads, stores, synchronization, and arithmetic.
Hopper (H100) provides hardware for bulk tensor transfers and matrix arithmetic. The reported rates in this part come from the source case study, not runs of our example. Chapter 16 explains the comparison limits.

#### 14.1 TMA: a delivery robot for tiles

**TMA = Tensor Memory Accelerator**, a dedicated copy engine in each SM.

**With ordinary loads and stores:** threads compute addresses and move pieces of the tile into SMEM. This spends instructions and registers on movement. Earlier GPU architectures also provide asynchronous-copy capabilities; TMA extends the approach with descriptor-based bulk tensor transfers.

**With TMA:**

1. On the CPU side, you create a **tensor map** (descriptor) once. It records the matrix's shape and strides in GMEM, the tile ("box") size, and the swizzle mode.
2. In the kernel, **one thread** says: *"copy the tile at coordinates (x, y) into this SMEM buffer."*
3. The TMA hardware does the whole copy **asynchronously**, handling addresses, bounds, and swizzling.

```
thread 0:  "TMA, please fetch tile (3, 7) into buffer 2."   → returns immediately
TMA:       ...moving bytes in the background...
thread 0:  (free to do other work)
```

**How do consumers know the data has arrived?** With an **mbarrier**, a shared-memory synchronization object. For a TMA load it tracks expected transaction bytes as well as participating arrivals and a reusable phase:

```
Conceptual sequence, not literal PTX:
1. initialize the barrier's arrival count and make initialization visible
2. producer: register expected bytes and perform the required arrival
3. producer: issue the TMA copy tied to this barrier phase
4. TMA: report transaction completion
5. consumer: wait for this phase (arrivals AND expected bytes complete)
```

Synchronization now tracks **data arrival**, which fits asynchronous hardware.

> 🔎 **Advanced sidebar: memory "proxies."** TMA and Tensor Cores access memory through a different path (the "async proxy")
> than normal thread loads and stores (the "generic proxy"). If threads write SMEM and then TMA reads it (e.g. for async stores, [§15.8](#158-micro-optimizations-and-async-stores--747--758-tflops)),
> you need a special fence (`fence.proxy.async`) so TMA sees the writes. The required ordering depends on which agents read and write the data; consult the PTX memory model for the exact instructions.
> You don't need to master it now, but know it exists.

#### 14.2 Swizzling: shuffling addresses to dodge bank conflicts

Recall from [§11.3](#113-smem-32-banks): reading a **column** of a row-major tile hits the same bank 32 times.
Padding fixes that teaching example. TMA and matrix instructions impose layout requirements, so we need a compatible arrangement for those operations. **Swizzling** instead **permutes where each element is physically stored**, without changing what the matrix means.

**Toy example (32×32 floats):** store logical element `(r, c)` at physical column `c XOR r`:

```
physical_col = c ^ r      // ^ = bitwise XOR
```

- **Read a column c** (thread t reads row t): physical columns are `c^0, c^1, ..., c^31`, which are all different banks ✅
- **Read a row r** (thread t reads column t): physical columns are `0^r, 1^r, ..., 31^r`, also all different ✅
- **Recover the logical position:** `(c ^ r) ^ r = c`. XOR undoes itself, so the mapping loses nothing.

```
Logical (row-major)             Physical (swizzled, 4×4 toy, col' = c ^ r)
row 0: a0 a1 a2 a3               row 0: a0 a1 a2 a3
row 1: b0 b1 b2 b3               row 1: b1 b0 b3 b2
row 2: c0 c1 c2 c3               row 2: c2 c3 c0 c1
row 3: d0 d1 d2 d3               row 3: d3 d2 d1 d0
column 0 (a0,b0,c0,d0) now sits in physical columns 0,1,2,3 → different banks ✅
```

![The labels identify logical chunks; their positions on the right identify physical storage slots.](/gpu-matmul-assets/figures/swizzle_example.svg)
*Figure 5.1. The labels identify logical chunks; their positions on the right identify physical storage slots.*

<details>
<summary>Walk through Figure 5.1</summary>

1. Each cell is a 16-byte chunk, not one BF16 or FP32 value. The left matrix labels chunks by (row, chunk-column). The right matrix contains the same labels in different positions.

2. Follow logical chunk (3,0): it moves to physical slot 0 XOR 3 = 3 of row 3. Its data still represents logical chunk (3,0). Colors help follow chunk identities across the copy.

3. Within this aligned eight-row example, row r uses slot c XOR r. Row 0 stays put and row 7 reverses. This is an address permutation, not arithmetic on matrix values and not a matrix transpose.

[Open the full-size figure](/gpu-matmul-assets/figures/swizzle_example.svg).

</details>

**What Hopper actually does.** Hardware swizzling works on **16-byte chunks** rather than single elements. Modes are **32B, 64B, and 128B**.
In **128B mode** (CuTe notation `Swizzle<3,4,3>`), within each 1024-byte group of eight 128-byte rows:

```
chunk_index (bits 4–6 of the address)  ^=  row_index mod 8 (bits 7–9)
```

So each row's eight chunks are permuted. This distributes the intended chunk-level access pattern across banks. It does not make every possible scalar column access conflict-free; analyze the actual instruction and its access width.

![The swizzle changes the chunk-position bits while preserving the byte position inside a chunk.](/gpu-matmul-assets/figures/swizzle_function_intuition.svg)
*Figure 5.2. The swizzle changes the chunk-position bits while preserving the byte position inside a chunk.*

<details>
<summary>Walk through Figure 5.2</summary>

1. Bits are numbered from the least significant bit on the right. Gray bits 0–3 select one of 16 bytes inside a chunk; blue bits 4–6 select a chunk within a 128-byte row; green bits 7–9 select a row in the eight-row group.

2. Follow the purple arrows: XOR the green row bits into the blue chunk bits. For row 3, the row bits are 011, so the byte-address mask is 3<<4 = 48.

3. The lower boxes give masks for all eight rows. Higher address bits and the four within-chunk bits stay unchanged. This explains why data remains within its row and why the relative layout pattern repeats every 1024 bytes.

[Open the full-size figure](/gpu-matmul-assets/figures/swizzle_function_intuition.svg).

</details>

![For row 3, one XOR mask maps each logical chunk to its destination slot.](/gpu-matmul-assets/figures/swizzle_apply.svg)
*Figure 5.3. For row 3, one XOR mask maps each logical chunk to its destination slot.*

<details>
<summary>Walk through Figure 5.3</summary>

1. The upper row is logical order; the lower row is shared-memory storage order. Follow the blue arrow from chunk (3,0), byte offsets 384–399, to slot 3, offsets 432–447.

2. Follow the red arrow from chunk (3,1) to slot 2: 1 XOR 3 = 2. The crossing arrows depict a permutation; no values are combined or lost.

3. The numbers beneath cells are byte offsets in the corresponding layout, not values stored in the matrix. XORing the same mask again reverses the mapping, which lets the consumer recover the logical positions.

[Open the full-size figure](/gpu-matmul-assets/figures/swizzle_apply.svg).

</details>

![A swizzled column of chunks spreads its requests across bank groups.](/gpu-matmul-assets/figures/swizzle_property.svg)
*Figure 5.4. A swizzled column of chunks spreads its requests across bank groups.*

<details>
<summary>Walk through Figure 5.4</summary>

1. The left panel marks logical chunk-column 2 in green. Trace those same (r,2) labels in the middle panel: their physical slots are 2,3,0,1,6,7,4,5.

2. Each 16-byte slot covers four four-byte banks. The eight different slots therefore distribute this illustrated collection of chunks across all 32 banks. On the right, without swizzling, all eight chunks stay in slot 2 and repeatedly use banks 8–11.

3. The comparison assumes the pictured chunk-level access. It does not say that any arbitrary scalar column read becomes conflict-free. Check the actual instruction’s access width and grouping before applying the pass counts.

[Open the full-size figure](/gpu-matmul-assets/figures/swizzle_property.svg).

</details>
TMA **writes** tiles into SMEM in this swizzled layout, and Tensor Core instructions are told the swizzle mode so they **read** it correctly.
You choose the mode once in the tensor map and the hardware handles the rest.

- At the math level, it's the same matrix.

- At the address level, it's rearranged.

- At the performance level, there are far fewer bank conflicts.

#### 14.3 Tensor Cores and WGMMA

**Ordinary cores** do one scalar FMA per thread per instruction. **Tensor Cores** do a whole **small matrix multiply-accumulate** in one operation:

$$
D = A \times B + D
$$

The ~989 TFLOP/s figure describes the dense BF16 Tensor Core path on H100 SXM. Ordinary FP32 instructions have their own, much lower throughput ceiling.

**Hopper's instruction: `wgmma.mma_async`** (*warp-group matrix multiply-accumulate*)

- Issued by a **warp group**: 4 warps = **128 threads** cooperating.

- Shape **`m64nNk16`** for bf16: an (M=64 × K=16) piece of A times a (K=16 × N) piece of B, where **N can be 8, 16, 24, …, 256**.
- **A** can come from registers or SMEM. **B** must be in SMEM. The accumulator **D** lives in **registers**, spread across the 128 threads.

**How many registers does the accumulator need?** The output has 64·N fp32 values spread over 128 threads:

$$
\text{regs per thread} = \frac{64 \times N}{128}
\qquad\Rightarrow\qquad
N = 64: 32 \text{ regs}, \quad N = 256: 128 \text{ regs}
$$

Remember this formula. It explains a key design choice in [§15.4](#154-multiple-consumer-warp-groups--610-tflops).

The first Hopper kernel keeps the same block-tiling structure as §9, just with bigger K steps (BM = BN = BK = 64):

![The Hopper kernel retains the block-tile decomposition but uses 64-wide K chunks.](/gpu-matmul-assets/figures/high_level_block_structure.svg)
*Figure 5.5. The Hopper kernel retains the block-tile decomposition but uses 64-wide K chunks.*

<details>
<summary>Walk through Figure 5.5</summary>

1. Locate the amber 64×64 C tile. Its rows select the blue A panel and its columns select the red B panel. The small active inputs are both 64×64 for one K step.

2. Move the A slice right and the B slice down together. There are 4096/64=64 such steps, all adding to the same output tile. The arrows indicate the reduction loop, not motion of the output tile.

3. A 64×64 input tile is still larger along K than one m64n64k16 matrix instruction accepts. The next picture splits each of these steps into four instruction-sized contributions.

[Open the full-size figure](/gpu-matmul-assets/figures/high_level_block_structure.svg).

</details>

**Example:** a 64×64 output tile with BK = 64 takes **4 WGMMA calls**, one per k16 slice:

```
D  = 0   // conceptual initialization before accumulating
D += A[:, 0:16]  @ B[0:16, :]
D += A[:, 16:32] @ B[16:32, :]
D += A[:, 32:48] @ B[32:48, :]
D += A[:, 48:64] @ B[48:64, :]
```

![Every WGMMA call updates the entire 64×64 output tile with another 16-wide K contribution.](/gpu-matmul-assets/figures/4_wgmma_calls.svg)
*Figure 5.6. Every WGMMA call updates the entire 64×64 output tile with another 16-wide K contribution.*

<details>
<summary>Walk through Figure 5.6</summary>

1. The top A tile is divided into four vertical strips, and B into four matching horizontal strips. Pair the same color: 64×16 multiplied by 16×64 produces a 64×64 contribution.

2. Read the four steps downward. Step 1 uses k=0…15; step 2 uses k=16…31. Each adds to all output positions in D. The amber square is full-sized at every step because these are partial sums for the whole tile, not finished subsets of output rows.

3. The slice labels denote logical matrix ranges. Actual WGMMA operands use register fragments or shared-memory descriptors with the required layout; the diagram is not literal pointer arithmetic. D remains in registers across all four calls.

[Open the full-size figure](/gpu-matmul-assets/figures/4_wgmma_calls.svg).

</details>

**Asynchronous:** issuing WGMMA starts work without waiting for its completion. Keep its operands valid until that work completes:

```
wgmma.fence                // order earlier register writes before the MMAs
wgmma.mma_async ...  ×4    // launch several MMAs (they run in the background)
wgmma.commit_group         // bundle them into a group
wgmma.wait_group 0         // wait before using results or reusing operand storage
```

> Issue independent work early, and wait before consuming results or reusing storage. A late wait is useful only if it still preserves every dependency.

**Result:** TMA + Tensor Cores with a simple 64×64×64 tiling took throughput from **~32 → ~317 TFLOP/s** (also switching fp32 → bf16).
Much of the hand-written choreography from §9 becomes a few hardware-assisted operations. You still design tile shapes, layouts, and synchronization yourself.

---

### 15. Building an asynchronous pipeline

TMA and Tensor Cores are both very fast, but in the basic kernel they **take turns**:

![Overlap shortens elapsed time by running independent loads and arithmetic together.](/gpu-matmul-assets/figures/better_pipeline.svg)
*Figure 5.7. Overlap shortens elapsed time by running independent loads and arithmetic together.*

<details>
<summary>Walk through Figure 5.7</summary>

1. Read time left to right. The two lanes name resources: TMA loads above and matrix arithmetic below. Blue boxes are loads, red boxes are compute, and hatching marks idle intervals.

2. In the top schedule, load k1 waits until computation on k0 finishes. In the lower schedule, load k1 overlaps computation on k0, using a different available buffer. Computation on a chunk must still wait for that chunk’s load.

3. Compare the green new end marker with the old red end marker. The boxes illustrate equal-duration stages here, not measured timing. Overlap cannot remove the first load, the final drain, or competition for a shared bottleneck.

[Open the full-size figure](/gpu-matmul-assets/figures/better_pipeline.svg).

</details>

The rest of the article removes waits one at a time.

Before reading the implementation, try an idealized timing example. Suppose
loading a tile takes 3 time units and computing it takes 5. Processing four tiles
serially takes `4 × (3 + 5) = 32` units. With separate buffers and perfect overlap,
the first load takes 3 units, then four computations take 20 more: 23 units total.
Loads for later tiles fit behind earlier computations. The improvement comes from
overlap; neither the individual load nor the computation became faster.

This assumes independent engines, enough buffers, and no extra contention or
synchronization cost. It also includes the initial fill. A pipeline does not
eliminate all waiting, and its steady rate cannot exceed its slowest stage.

#### 15.1 Bigger output tiles (317 → 423 TFLOP/s)

From [§9.3](#93-why-bigger-tiles-mean-more-reuse-worked-out): a bigger output tile means more reuse per byte loaded.
The cost is more registers (accumulators) and more SMEM (input tiles). Too small gives poor reuse. Too big runs out of registers or SMEM.
Tile size is always a balancing act.

![One warp group owns both row halves of a 128×128 output tile.](/gpu-matmul-assets/figures/kernel4_pipeline_2.svg)
*Figure 5.8. One warp group owns both row halves of a 128×128 output tile.*

<details>
<summary>Walk through Figure 5.8</summary>

1. The top row states the desired product: 128×64 A times 64×128 B. The dashed horizontal split in A separates its upper and lower 64 rows.

2. The middle row computes the first 64 output rows with four k16 contributions. The bottom row computes the last 64 rows with four more. Both use the same B tile, and the same consumer warp group owns both accumulator sets.

3. Unlike the preceding K-slice figure, the amber half here really is a subset of output rows. The two accumulator halves together contain 128×128 FP32 values, or 128 values per thread across a 128-thread warp group.

[Open the full-size figure](/gpu-matmul-assets/figures/kernel4_pipeline_2.svg).

</details>

#### 15.2 Circular buffering: the producer–consumer pipeline (→ 498 TFLOP/s)

Split SMEM into several **slots** (also called stages), each holding one A tile and one B tile. A **producer** fills slots while a **consumer** computes on already-full ones:

```
time ──▶
TMA (producer):  [load 0][load 1][load 2][load 3][load 4][load 5] ...
Tensor (consumer):        [comp 0][comp 1][comp 2][comp 3][comp 4] ...
                 ↑ both units busy at the same time
```

Slots are reused in a ring: 0, 1, 2, 3, 0, 1, 2, … so this is a **circular buffer**.

Each slot has **two mbarriers**:

| Barrier | Meaning | Who waits on it | Who signals it |
|---|---|---|---|
| `full[i]` | "slot i has data" | consumer | TMA (byte count reached) |
| `empty[i]` | "slot i is free" | producer | consumer (done reading) |

```text
Conceptual producer:
    wait until slot i is empty for this reuse phase
    register expected bytes and the required barrier arrival
    issue TMA loads into slot i, associated with its full barrier

Conceptual consumer warp group:
    wait until slot i is full for this reuse phase
    issue the WGMMAs that read slot i
    commit their WGMMA group
    wait until all WGMMA operations reading slot i have completed
    signal that slot i is empty
```

**Issuing an asynchronous operation is not finishing it.** Signaling `empty`
immediately after issuing WGMMA could let the producer overwrite a tile while
the matrix unit is still reading it. A simple design can wait for all committed
groups; a more advanced design tracks which groups still use each slot.

This sketch omits PTX syntax, barrier initialization, arrival counts, phase
tracking, and proxy fences. A ring reuses its barriers, so consumers must
distinguish the current reuse from a previous completion. The slots begin
logically empty, and the initial barrier protocol must permit their first fill.
With multiple consumers, a slot becomes empty only when **all** relevant readers
are finished. This is a design explanation, not a paste-ready implementation.

![A slot can be reused only after its data has arrived and all readers have finished.](/gpu-matmul-assets/figures/kernel4_pipeline.svg)
*Figure 5.9. A slot can be reused only after its data has arrived and all readers have finished.*

<details>
<summary>Walk through Figure 5.9</summary>

1. Follow slot 0 first. A blue TMA box fills it, then a green full[0] arrow permits the red consumer box to begin. The purple empty[0] arrow occurs after the consumer’s asynchronous reads complete.

2. Now follow slot 1, then the next use of slot 0. The numeric label is a buffer identity reused around a ring, not a fixed k value. Repeated barrier uses must track the correct completion phase.

3. Loads are slower than compute in this particular drawing, so the consumer still has hatched idle gaps. More buffers cannot make the slow stage faster. The green arrow assumes the barrier’s required arrivals as well as transaction completion are satisfied.

[Open the full-size figure](/gpu-matmul-assets/figures/kernel4_pipeline.svg).

</details>

The producer works ahead on tomorrow's data while the consumer finishes today's. Enough stages can cover part of the latency, but throughput is still limited by the slower stage, resource contention, and the pipeline's initial fill and final drain.

**Check yourself:** A consumer has issued its last matrix instruction for slot 0.
Can the producer immediately refill slot 0?

<details>
<summary>Answer</summary>

Only after all asynchronous operations that read slot 0 have completed and the
required completion protocol permits reuse. Issuing the last read is not evidence
that the read has finished.

</details>

#### 15.3 Warp specialization

Notice that different warp groups now do **different jobs**:

- **Producer warp group:** only issues TMA loads, using one thread.
- **Consumer warp group(s):** only run WGMMA and the math.

This is **warp specialization**. Instead of every warp doing a bit of everything, each specializes, like an assembly line.

#### 15.4 Multiple consumer warp groups (→ 610 TFLOP/s)

We want an even bigger tile, say **128×256**. Could one consumer warp group own it?

$$
\frac{128 \times 256}{128 \text{ threads}} = 256 \text{ fp32 accumulator registers per thread}
$$

A thread can address at most **255 registers**, and other state needs registers too. Ordinary compiler-managed values can spill into local memory backed by device memory and caches. That can be expensive. A fixed WGMMA register operand layout must itself satisfy the instruction constraints; spilling is not a way to make an oversized WGMMA accumulator legal.

**Fix:** use **two consumer warp groups**, each owning a 64×256 half, so each needs 128 accumulator registers. That fits.

![Two consumer warp groups split the accumulator storage for a 128×256 output tile.](/gpu-matmul-assets/figures/2wgs.svg)
*Figure 5.10. Two consumer warp groups split the accumulator storage for a 128×256 output tile.*

<details>
<summary>Walk through Figure 5.10</summary>

1. The top row shows the full product. The middle row highlights the upper 64 output rows owned by consumer group 0, and the bottom row the lower 64 rows owned by group 1.

2. Both groups use the same B tile but different A rows. Each group holds 64×256 output values distributed over 128 threads: 128 FP32 accumulator registers per thread instead of the 256 needed if one group owned the full tile.

3. Separate output ownership avoids conflicting accumulator writes. It does not remove coordination over the shared input buffers: the producer must wait for both consumers to finish before overwriting a slot.

[Open the full-size figure](/gpu-matmul-assets/figures/2wgs.svg).

</details>

> **Split work not only for parallelism, but also to fit within hardware resource limits.**

#### 15.5 Persistent kernels (→ 660 TFLOP/s)

**Normal kernel:** launch thousands of blocks. Each computes one tile and exits, and the scheduler starts the next.

**Persistent kernel:** launch a limited set of long-lived blocks, each processing multiple tiles. In this design the launch is sized for approximately one resident block per SM:

```cuda
for (tile = blockIdx.x; tile < num_tiles; tile += gridDim.x) {
    load inputs → compute → store output
}
```

Benefits:

- No repeated block startup and teardown (barrier init, tensor map prefetch, etc.).
- **You** assign the logical tile order, which enables the L2 trick in [§15.9](#159-smarter-tile-order-hilbert-curves--764-tflops).

- Work from **neighboring tiles can overlap**: the producer can start loading tile t+1 while consumers are still finishing and storing tile t.

> The kernel becomes a **continuously running assembly line** instead of a series of separate jobs.

![A persistent block can prepare its next output tile before its current tile is fully retired.](/gpu-matmul-assets/figures/overlap_stores.svg)
*Figure 5.11. A persistent block can prepare its next output tile before its current tile is fully retired.*

<details>
<summary>Walk through Figure 5.11</summary>

1. The repeated labels t0 in the upper schedule are different K chunks contributing to one output tile. After its last arithmetic step, the block stores results and exits; another block initializes to handle t1.

2. In the lower schedule, the same block continues. Follow load t1: it starts while arithmetic or stores for t0 are still in progress. The green dashed marker highlights this overlap across output tiles.

3. The lower lane groups consumer work; a store is not literally Tensor Core arithmetic. These timelines illustrate one design with suitable buffering and completion checks. Persistence changes scheduling opportunities, not memory-dependency rules.

[Open the full-size figure](/gpu-matmul-assets/figures/overlap_stores.svg).

</details>

#### 15.6 Cheaper synchronization (→ 704 TFLOP/s)

When big bottlenecks are gone, small ones show up. The barrier operations themselves start to cost something measurable.
The fix was to use leaner PTX-level barrier instructions and remove **redundant** arrivals and waits (e.g. having one thread arrive on behalf of a whole warp instead of all 32).

```
fix biggest bottleneck → next one appears → fix it → next one appears → ...
```

> Keep **exactly** the synchronization needed for correctness, and no more. Removing barriers blindly causes race conditions.

#### 15.7 Clusters and TMA multicast (→ 734 TFLOP/s)

Hopper adds **thread block clusters**: a group of blocks guaranteed to run **at the same time on SMs in the same GPC**.
Blocks in a cluster can access each other's shared memory, a feature called **DSMEM (Distributed Shared Memory)**.

**TMA multicast:** suppose 2 blocks in a cluster compute tiles stacked on top of each other in C (the same columns, different rows).
They need **different A tiles** but the **same B tile**. Without multicast, both fetch B from L2. With multicast, one TMA load is **delivered to both SMs' SMEM at once**:

![Two vertically adjacent C tiles can share delivery of B while requiring different A rows.](/gpu-matmul-assets/figures/clusters.svg)
*Figure 5.12. Two vertically adjacent C tiles can share delivery of B while requiring different A rows.*

<details>
<summary>Walk through Figure 5.12</summary>

1. On the left, tiles ① and ② occupy the same output columns but different rows. The red B column panel is common to both; the two blue A row panels differ.

2. On the right, the red arrow branches from one multicast operation into two separate B buffers, one in each SM’s shared memory. The blue arrows deliver distinct A data.

3. This creates two destination copies rather than a single shared physical B buffer. Both destinations must be ready before their next refill. The dashed cluster outline denotes blocks co-scheduled within a supported cluster, not any arbitrary pair of SMs.

[Open the full-size figure](/gpu-matmul-assets/figures/clusters.svg).

</details>

The arithmetic is unchanged. The same bytes just move fewer times.

#### 15.8 Micro-optimizations and async stores (→ 747 → 758 TFLOP/s)

**Register rebalancing with `setmaxnreg`.** The producer barely needs registers (it issues TMA commands). The consumers need a lot (accumulators). Hopper lets warp groups **hand registers to each other** at runtime.
Illustrative budget for 1 producer + 2 consumer warp groups (384 threads, 65,536 registers):

$$
\underbrace{128 \times 40}_{\text{producer}} + \underbrace{256 \times 232}_{\text{consumers}} = 5{,}120 + 59{,}392 = 64{,}512 \le 65{,}536 \;\checkmark
$$

Fewer desks for the delivery robot, bigger desks for the chefs.

**Skip zero-initialization.** Instead of setting accumulators to 0 and then computing `D += A·B`, the **first** WGMMA uses a flag (`scale-d = 0`) meaning *"ignore old D"*: `D = A·B`. That saves a pass of zeroing registers.

**Async stores: pipeline the output too.** Results must eventually go back to GMEM. Direct stores add work to the consumer instruction stream. An alternative is to stage output for a bulk asynchronous store:

```
registers ──▶ SMEM ──(TMA store, async)──▶ GMEM
                       ↑ overlap work while preserving the source buffer until the read completes
```

With the required fences and completion tracking, the pipeline can overlap three stages:

```
store tile t−1   ║   compute tile t   ║   load tile t+1     ← all at once
```

#### 15.9 Smarter tile order: Hilbert curves (→ 764 TFLOP/s)

With a persistent kernel, **you** assign tile sequences to blocks. Blocks can advance at different rates, so a “wave” is a scheduling model, not a global synchronization step. Assignments that keep nearby work together can still improve locality.

To compute one output tile, an SM needs one **row-panel of A** and one **column-panel of B**. Tiles running at the same moment (one **wave**) that sit in the
same rows or columns of C can share those panels through L2. Tiles scattered all over C can't. Each one drags in its own panels, and L2 overflows.

The article uses a toy example: C is cut into **8×8 tiles**, there are **10 SMs**, and the matrices are 4096×4096 fp32 (**64 MiB each**, while H100 L2 is specified as **50 MB**).

**Naive schedule:** walk the tiles in raster order and give each SM a run of consecutive tiles (SM1 takes the first 7, SM2 the next 7, …).
The first tile of each SM, which is wave 1, ends up spread over the whole matrix:

![The first assigned tiles touch many input panels because they are scattered across C.](/gpu-matmul-assets/figures/naive_schedule.svg)
*Figure 5.13. The first assigned tiles touch many input panels because they are scattered across C.*

<details>
<summary>Walk through Figure 5.13</summary>

1. Every square is one output tile. Color identifies the assigned SM; the number inside is that SM’s processing round, called a wave in this model. Black borders mark the ten tiles labeled 1, not every tile of one color.

2. Count distinct matrix rows and columns touched by the black-bordered tiles. They touch all eight tile rows and six tile columns, selecting 8/8 of A and 6/8 of B. At 64 MiB per input matrix, that is 64+48=112 MiB of panels.

3. These are full-K panel footprints across the selected outputs, not bytes loaded simultaneously in one instruction. The picture assigns contiguous runs to SMs, unlike the round-robin assignments below; both tile order and assignment affect locality.

[Open the full-size figure](/gpu-matmul-assets/figures/naive_schedule.svg).

</details>

**Block-wise (cache-aware) schedule:** group tiles into small 4×2 blocks and hand them out so each wave is compact:

![Grouping nearby output tiles reduces the input-panel footprint of the first round.](/gpu-matmul-assets/figures/blockwise_schedule.svg)
*Figure 5.14. Grouping nearby output tiles reduces the input-panel footprint of the first round.*

<details>
<summary>Walk through Figure 5.14</summary>

1. Use the same legend: color is SM, numeral is round, and the black outline selects round 1. The dashed path visits tiles in small spatial groups before moving to the next group.

2. The first ten tiles touch four of the eight tile rows and four tile columns. Their needed panels are 4/8 of A plus 4/8 of B: 32+32=64 MiB. The blue and red panels on the right show those fractions.

3. Look at tiles numbered 2 to see potential reuse of nearby panels in the next round. The footprint still exceeds the stated L2 capacity, so compactness is an opportunity for reuse, not a guarantee that every access hits the cache.

[Open the full-size figure](/gpu-matmul-assets/figures/blockwise_schedule.svg).

</details>

**Hilbert-curve schedule:** a **Hilbert curve** is a space-filling path through a grid that only ever steps to a **neighbor**,
so any run of consecutive tiles along it forms a compact blob. There are no jumps back across the matrix at the end of a row.

```
Hilbert curve on a 4×4 grid (visit order):
 0  1 14 15
 3  2 13 12
 4  7  8 11
 5  6  9 10
```

![The Hilbert path keeps nearby traversal positions spatially close, improving opportunities for panel reuse.](/gpu-matmul-assets/figures/hilbert_schedule.svg)
*Figure 5.15. The Hilbert path keeps nearby traversal positions spatially close, improving opportunities for panel reuse.*

<details>
<summary>Walk through Figure 5.15</summary>

1. Follow the gray path from the start at the top left. Each step enters an adjacent tile. Do not read the numerals as consecutive Hilbert positions: they still label processing rounds, while colors identify SM assignments.

2. Select the ten black-bordered round-1 tiles. They occupy three tile rows and four tile columns, needing 3/8 of A plus 4/8 of B: 24+32=56 MiB.

3. That is smaller than the earlier 112 and 64 MiB footprints, but still larger than the stated L2 capacity. The real benefit depends on temporal reuse, cache behavior, and how quickly blocks advance; a “wave” here is not a hardware-wide synchronization barrier.

[Open the full-size figure](/gpu-matmul-assets/figures/hilbert_schedule.svg).

</details>

The real kernel applies locality-aware ordering at a larger scale. Compact tile groups can increase panel reuse, but these footprint calculations do not predict an exact hit rate. Even the 56 MiB toy footprint exceeds the stated L2 capacity. Also, the contiguous assignment in this illustration differs from the cyclic assignment in the earlier persistent-loop sketch; traversal and assignment must be considered together.

> **Even the order you walk across the output matrix changes performance.** Same matrix, same arithmetic, same hardware, different order: more cache hits and more TFLOP/s.

---

### 16. Reading the optimization results

The rates below are reported results from the source article's kernel progression,
not measurements made by this tutorial. They describe selected shapes and
configurations. The FP32 baseline and BF16 matrix kernels use different arithmetic
paths; the original naive results also come from a different H100 configuration.
Do not combine them into one controlled “240×” experiment.

For your own comparisons, keep the GPU, shapes, input precision, accumulator
precision, timing method, and correctness criteria fixed. Treat each optimization
as a hypothesis to test, not a guaranteed increment in TFLOP/s.

| # | Step | Main idea | ~TFLOP/s |
|---|---|---|---|
| 0 | Warp-tiled baseline | reuse via SMEM + registers | 32 |
| 1 | + TMA + Tensor Cores (WGMMA), bf16 | hardware-assisted movement and matrix math | 317 |
| 2 | + bigger output tile | more reuse per byte | 423 |
| 3 | + circular-buffer pipeline | overlap loads with compute | 498 |
| 4 | + 2 consumer warp groups (128×256) | bigger tile without blowing the register budget | 610 |
| 5 | + persistent kernel | blocks stay alive and overlap across tiles | 660 |
| 6 | + cheaper (PTX) barriers | strip redundant synchronization | 704 |
| 7 | + clusters + TMA multicast | fewer duplicate transfers across SMs | 734 |
| 8 | + micro-optimizations | `setmaxnreg`, skip zero-init, cleanup | 747 |
| 9 | + async TMA stores | overlap the output write with future work | 758 |
| 10 | + Hilbert-curve scheduling | better L2 reuse through tile order | **764** |

(A later community contribution using the `stmatrix` instruction for the store path reportedly added about 1% more.)

There is **no single magic trick**. The progression addresses several kinds of cost, including changes to the arithmetic hardware:

```
bad address patterns → no reuse → slow memory → scalar math → load/compute serialization
 → register limits → block setup overhead → barrier overhead → duplicate transfers
 → store stalls → cache misses
```

Implementation reference: consult the [PTX ISA](https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#asynchronous-warpgroup-level-matrix-instructions-wgmma-wait-group) for WGMMA completion, barrier phases, and memory-ordering requirements, and the [Hopper Tuning Guide](https://docs.nvidia.com/cuda/hopper-tuning-guide/index.html) for architecture-specific limits.

---

## Part 6: Other kernels and the whole system


Broaden the ideas to reductions, fusion, transfers, address translation, and multiple GPUs. You may read this part directly after Part 3; the asynchronous pipeline comparisons refer forward to the optional Hopper case study.

- [17. Beyond matrix multiplication](#17-beyond-matrix-multiplication)
- [18. Addresses, transfers, and multiple processors](#18-addresses-transfers-and-multiple-processors)
- [19. A method you can reuse](#19-a-method-you-can-reuse)

---

### 17. Beyond matrix multiplication

**Learning goal:** transfer the reasoning to kernels whose bottlenecks differ
from a large, dense matrix multiplication. Read this chapter after Part 3 if you
want a broader view before studying Hopper.

#### 17.1 Vector addition: little opportunity for reuse

For `C[i] = A[i] + B[i]` with FP32 arrays, useful work is one addition per output.
The simple traffic model reads eight input bytes and writes four output bytes,
giving `1/12` FLOP per byte. Cache and transaction behavior can change physical
traffic, but there is little algorithmic reuse to exploit in this one operation.

Copying every input into shared memory would add work without creating reuse.
Instead, start with coalesced accesses, enough parallel work, and avoiding
unnecessary transfers between host and device. This is why the matmul recipe
“make bigger tiles” is not a universal GPU optimization.

#### 17.2 Transpose: layout can dominate arithmetic

For `B[col,row] = A[row,col]`, the mathematical work is mostly moving data.
If lanes read neighboring input elements, their direct output writes may be
far apart. A shared-memory tile lets threads cooperate: read a contiguous tile,
synchronize, then read it in a different arrangement for contiguous output writes.

Now the column reads inside shared memory may conflict. Padding or an appropriate
swizzle solves a different problem from global coalescing. A transpose is a good
small exercise because it separates layout from matrix arithmetic.

#### 17.3 Reduction: many inputs, one result

A **reduction** combines values, such as adding an array. Unlike our first
matmul kernel, outputs cannot all be computed independently by assigning one
thread to each input and writing a shared total.

```text
inputs:       a  b  c  d  e  f  g  h
first sums:   a+b   c+d   e+f   g+h
next sums:    a+b+c+d     e+f+g+h
result:       a+b+c+d+e+f+g+h
```

A tree exposes parallel work at the beginning, then has less work near the root.
GPU reductions combine local partial sums, cooperate within blocks, and may use
another kernel to combine block results. An **atomic** update makes a supported
read-modify-write operation indivisible with respect to competing updates, but
many updates to the same location can contend.

Changing the reduction tree changes the order of floating-point additions, which
can change rounding. Correctness includes a numerical accuracy requirement, not
just absence of races.

#### 17.4 Fusion: remove an intermediate array

Consider two kernels:

```text
kernel 1: T[i] = A[i] + B[i]
kernel 2: C[i] = max(T[i], 0)
```

In a simple global-traffic count, separate kernels read A and B, write T, read T,
and write C: 20 bytes per FP32 output. A **fused** kernel can keep the sum in a
register and write only C: 12 bytes per output. Fusion also removes a launch.

This is a requested-traffic model, not a claim that the separate kernels always
transfer all 20 bytes across HBM. T may be cached. Fusion can also increase
register use or constrain scheduling, so measure whether the tradeoff helps.

#### 17.5 Irregular work: when neighboring lanes disagree

Graph traversal and sparse computations can follow indices to unrelated addresses.
They may have little locality, many dependent loads, and uneven work per thread.
Simply adding threads does not guarantee high useful throughput.

Possible changes include grouping similar work, changing data layout, or assigning
work dynamically. Each has a setup cost. Compare the entire operation, including
reordering or packing, rather than timing only its best inner loop.

**Check yourself:** Why might shared memory help transpose but not a single
vector addition?

<details>
<summary>Answer</summary>

Transpose uses shared memory to change which thread owns each value between
global reads and writes. Vector addition already has straightforward neighboring
accesses and no repeated use that justifies staging each value.

</details>

---

### 18. Addresses, transfers, and multiple processors

**Learning goal:** understand why a kernel's local efficiency is only one part of
application performance. This chapter introduces system-level topics; it is not
a complete guide to operating systems or distributed GPU programming.

#### 18.1 A pointer names an address, not a physical location

Programs generally use **virtual addresses**. Address translation maps those
addresses to physical storage in units called **pages**. A **TLB**, or translation
lookaside buffer, caches translations. A data-cache hit and a translation-cache
hit answer different questions: “Do we have the value?” and “Where is its page?”

Working across many pages can stress translation resources as well as data
caches. Contiguous allocation, page size, and access pattern can therefore affect
performance in ways not visible in a simple FLOP/byte model. Exact translation
behavior is architecture- and system-dependent.

Drepper's §4 provides background on virtual memory. Use it to learn the role of
translation, rather than assuming its CPU page-table details describe a GPU.

#### 18.2 Unified addressing does not make all memory equally close

An address being representable in one address space does not mean every processor
can access its data at the same cost. Distinguish:

- **Address naming:** how an allocation is identified.
- **Accessibility:** which processor is permitted and able to access it.
- **Placement:** which physical memory currently holds it.
- **Movement and visibility:** how data arrives and when another agent may use it.

CUDA Unified Memory provides a programming model for memory accessible to the
CPU and GPU, with behavior that depends on platform capabilities. It can involve
page migration or remote access. It does not remove placement costs or program
synchronization requirements. Consult the [Unified Memory guide](https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/unified-memory.html)
for the particular system; do not assume one migration policy applies everywhere.

Our first example uses explicit allocation and copies so the movement is visible
in the code. That is a teaching choice, not a claim that explicit copies are
always the best interface.

#### 18.3 Overlap across kernels and transfers

The producer-consumer idea also applies outside a kernel. Divide a large input
into independent chunks and try to overlap their transfers and computation:

```text
time →
input copies:   [chunk 0][chunk 1][chunk 2]
computation:            [chunk 0][chunk 1][chunk 2]
output copies:                   [chunk 0][chunk 1][chunk 2]
```

This is a desired schedule, not a guarantee. Dependencies, copy engines, host
memory properties, stream configuration, and the physical links determine what
can overlap. **Pinned host memory** is host memory kept resident for operations
that require it; it is often used for asynchronous host/device transfers.

Use events or other supported dependencies before consuming a result or reusing
a transfer buffer. “The copy was submitted” is not the same as “the copy is done.”
That is the same lifetime rule we encountered with asynchronous matrix operations.

#### 18.4 NUMA: locality beyond a single chip

**NUMA**, non-uniform memory access, means the cost of reaching memory depends
on where the requesting processor and memory are located. Drepper's §§5 and 6.5
describe this for CPU systems. The broader lesson is to consider placement and
the links a transfer crosses.

On a system with several CPU sockets and GPUs, a GPU may have a shorter path to
some host memory than to other host memory. GPU-to-GPU paths can also differ.
Inspect the actual topology before assuming all pairs have equal bandwidth.
NUMA is useful background, but CPU cache-coherence protocols should not be
treated as a description of GPU shared memory or arbitrary GPU-to-GPU access.

#### 18.5 Splitting one multiplication across two GPUs

Suppose we split A by rows:

```text
GPU 0: upper rows of A × B → upper rows of C
GPU 1: lower rows of A × B → lower rows of C
```

The outputs are independent, but each GPU needs access to B. We must account
for distributing inputs, replicating or accessing B, and collecting outputs.
For a small multiplication, those costs can exceed the arithmetic savings.

Alternatively, split the K dimension. Each GPU computes a partial contribution
to **all** of C, and the partial results must be added together. This introduces
a reduction across processors. The split changes the communication problem, not
just the amount of local work.

Before implementing either design, draw the required transfers and estimate:

```text
transfer-time lower bound = bytes crossing a link / usable link bandwidth
```

Then add dependencies: an operation cannot start until its required input is
available. Overlap can help, but cannot erase the slowest required transfer or
a dependency that serializes stages.

**Check yourself:** Why does splitting rows avoid a final sum of partial C
matrices, while splitting K does not?

<details>
<summary>Answer</summary>

Row splitting assigns each output to one GPU, which computes its full dot product.
K splitting assigns parts of each dot product to different GPUs, so their partial
sums must be combined.

</details>

---

### 19. A method you can reuse

For the matrix-multiplication case study, one recurring objective was:

> **Keep the math units fed.**

| Strategy | Techniques |
|---|---|
| **Move less data** | tiling, bigger/squarer tiles, register blocking, multicast |
| **Move data efficiently** | coalescing, vectorized loads, TMA, swizzling (no bank conflicts) |
| **Keep hot data close** | registers ▶ SMEM ▶ L2 ▶ HBM; smart tile order for L2 hits |
| **Overlap everything** | async TMA, async WGMMA, circular buffers, persistent kernels, async stores |
| **Respect resource limits** | occupancy trade-offs, splitting work across warp groups, `setmaxnreg` |

#### The most useful question in performance engineering

Not *"how many instructions am I running?"* but:

> **"What hardware is waiting right now, and why?"**

- Are the Tensor Cores waiting on shared memory?

- Is shared memory waiting on HBM?

- Are threads waiting at a barrier?

- Are SMs idle because the last wave is mostly empty?

- Is a warp stalled because a bank conflict serialized its accesses?

- Is data being loaded again even though another SM already loaded it?

Every wait is a clue. Profilers like **Nsight Compute** (`ncu`) exist to answer exactly these questions.

#### The kitchen picture

| GPU concept | Kitchen |
|---|---|
| HBM | the warehouse across town (huge, slow) |
| L2 | the pantry shared by the whole kitchen |
| Shared memory | ingredients laid out on your workstation |
| Registers | ingredients in the chef's hands |
| TMA | a delivery robot that keeps bringing the next ingredients |
| Tensor Cores | the chefs: extremely fast if ingredients are ready |
| mbarriers | "ingredients ready!" / "station free!" signals |
| Circular buffer | several prep tables, one filled while another is used |
| Warp specialization | some staff only fetch, others only cook |
| Persistent kernel | chefs stay at their stations instead of clocking out after each plate |
| Clusters + multicast | neighboring kitchens share one delivery |
| Hilbert scheduling | cook dishes in an order that reuses what's already on the counter |

> **Never make the chefs wait.**

For a new kernel, begin with correctness, map the work and data, predict a bottleneck, and measure. Change one important factor, then check both the answer and the timing again. Memory movement is a recurring concern, but the limiting resource depends on the workload.

---

## Exercises, glossary, and sources


Use the chapter checkpoints as you read. These additional exercises and definitions provide a place to revisit the main ideas.

- [20. Exercises](#20-exercises)
- [21. Glossary](#21-glossary)
- [22. Sources and further study](#22-sources-and-further-study)

---

### 20. Exercises

Try these before peeking at the answers.

1. **FLOP counting.** How many FLOPs is a matmul with M=2048, N=8192, K=1024? How long would it take at 600 TFLOP/s?
2. **Coalescing.** A warp reads `x[threadIdx.x * 2]` (fp32). How many bytes are fetched and how many are used? (Assume 32-byte sectors and a 32-byte-aligned base address.)
3. **Banks.** Threads in a warp read `float s[64][64]` at `s[t][0]` for t = 0..31. How many ways is the bank conflict? Would `s[64][65]` fix it?
4. **Arithmetic intensity.** What's the input-tile intensity (FLOP/byte, excluding output stores and cache reuse) of a 256×128 bf16 tile? Compare it with 128×256 and with 192×192.
5. **Registers.** A warp group does `m64n192k16` WGMMAs with fp32 accumulators. How many accumulator registers per thread?
6. **Waves.** 1000 equal blocks, 132 SMs, 1 block per SM. How many waves, and what fraction of SM-time is wasted in the last one?
7. **Thinking.** Why does the pipeline need *both* `full` and `empty` barriers? What breaks if you remove `empty`?

<details>
<summary><b>Answers</b></summary>

1. 2·2048·8192·1024 ≈ 3.44×10¹⁰ FLOPs → ≈ 57 µs.
2. The accessed words occupy eight 32-byte sectors, so 256 bytes are fetched and only 128 are used: 50% efficiency.
3. Address = t·64·4 bytes → bank = (t·64) mod 32 = 0 for every t, so a **32-way** conflict. With 65 columns, bank = (t·65) mod 32 = t mod 32, all different, so it's fixed.
4. 2·256·128/(384·2) ≈ 85 FLOP/byte, the same as 128×256 (only the shape matters, not which side is longer).
   192×192: 2·36864/(384·2) = 96. It's square with a bigger area (36,864 vs 32,768 elements) for the same perimeter, so it gets more reuse.
5. 64·192/128 = 96 registers.
6. ⌈1000/132⌉ = 8 waves. 7 full waves = 924 blocks, last wave has 76 blocks, so 56/132 ≈ 42% of the last wave is idle (56/1056 ≈ 5.3% of total SM capacity over the eight idealized waves).
7. `full` stops the consumer from reading a slot before its data has arrived. `empty` stops the producer from overwriting a slot the consumer is still reading.
   Without `empty`, a fast producer laps the consumer and corrupts tiles still in use. That's a race condition, which gives wrong results, not just slowness.

</details>

---

### 21. Glossary

| Term | Meaning |
|---|---|
| **Arithmetic intensity (AI)** | FLOPs per byte transferred across a specified memory boundary |
| **Bank conflict** | several threads hitting different addresses in the same SMEM bank, so their accesses are serialized |
| **bf16** | 16-bit float with fp32's exponent range and fewer mantissa bits. Standard for AI |
| **Broadcast** | many threads reading the same address, served in one go |
| **Cluster** | group of thread blocks co-scheduled on nearby SMs (same GPC) that can share SMEM |
| **Coalescing** | merging a warp's memory accesses into a few large transactions |
| **CTA** | Cooperative Thread Array, another name for a thread block |
| **cuBLAS** | NVIDIA's highly optimized linear algebra library, the usual benchmark baseline |
| **CUTLASS / CuTe** | NVIDIA's open-source C++ template libraries for writing high-performance matmuls |
| **DSMEM** | Distributed Shared Memory, letting SMs in a cluster access each other's SMEM |
| **FMA** | fused multiply-add (`a*b+c`), counted as 2 FLOPs |
| **GMEM / HBM** | Global memory is an address space; HBM is the physical memory technology used on H100 |
| **GPC** | Graphics Processing Cluster, a physical group of SMs |
| **Hilbert curve** | space-filling path that keeps consecutive points spatially close |
| **ILP** | instruction-level parallelism, independent instructions in flight at once |
| **Kernel** | a function that runs on the GPU |
| **Latency hiding** | doing other useful work while waiting for slow operations |
| **mbarrier** | Shared-memory barrier object; tracks arrivals and, for relevant operations, asynchronous transaction completion |
| **Multicast** | one TMA load delivered to several SMs in a cluster |
| **Occupancy** | active warps ÷ maximum warps per SM |
| **Persistent kernel** | A limited set of long-lived blocks processes multiple work items |
| **PTX** | NVIDIA's virtual assembly language |
| **Roofline** | Upper bound: performance ≤ min(compute peak, AI × bandwidth), using matching types and memory boundary |
| **SASS** | the real machine code for a specific GPU architecture |
| **`setmaxnreg`** | Hopper instruction to shift register budget between warp groups |
| **SIMT** | single instruction, multiple threads (issued warp instructions operate on participating lanes) |
| **SM** | Streaming Multiprocessor, an execution unit hosting blocks and warps; its count depends on the GPU |
| **SMEM** | shared memory, a fast on-chip scratchpad managed by your code |
| **Speed of light (SoL)** | theoretical peak throughput |
| **Spilling** | registers overflowing to slow local memory |
| **Swizzling** | XOR-based permutation of SMEM addresses to avoid bank conflicts |
| **Tensor Core** | hardware unit that does small matrix multiply-accumulates |
| **Tile / wave quantization** | waste from work coming in fixed-size chunks (partial tiles, partial last wave) |
| **TMA** | Tensor Memory Accelerator, Hopper's async bulk-copy engine |
| **Warp** | 32 threads scheduled together |
| **Warp group** | 4 warps (128 threads), the unit that issues WGMMA |
| **Warp specialization** | different warps doing different roles (producer vs consumer) |
| **WGMMA** | warp-group matrix multiply-accumulate (`wgmma.mma_async`), Hopper's Tensor Core instruction |
| **Bandwidth** | Bytes delivered per unit time |
| **Latency** | Time from a request to its result |
| **Working set** | Data needed during a chosen portion of execution |
| **Spatial locality** | Accessing nearby addresses |
| **Temporal locality** | Reusing data soon after an earlier access |
| **Cache line / sector** | Storage or transfer granules in a cache; size depends on the level and architecture |
| **Host / device** | CPU side / GPU side of this tutorial's CUDA program |
| **Lane** | A thread's position within a warp |
| **Stream** | An ordered sequence of GPU operations |
| **Reduction** | Combining many values into fewer results, such as summing an array |
| **Atomic operation** | An indivisible supported update with respect to competing accesses at its scope |
| **Fusion** | Combining operations to avoid intermediate storage or separate launches |
| **Virtual address** | A program-visible address mapped to physical storage |
| **TLB** | Cache of address translations |
| **NUMA** | Memory access cost depends on processor and memory placement |

---

### 22. Sources and further study

This tutorial combines a GPU matrix-multiplication case study with a broader
explanation of memory and program execution. It does not reproduce either source
in full, and neither source is a specification for every GPU.

| Source | How it is used here |
|---|---|
| Ulrich Drepper, [*What Every Programmer Should Know About Memory*](/gpu-matmul-assets/cpumemory.pdf), November 21, 2007 | §§2–3: DRAM, caches, and locality; §3.3.2: the working-set experiment method; §6.2.1: matrix locality and blocking; §§4–5 and §6.5: translation and NUMA background |
| Aleksa Gordić, [*Inside NVIDIA GPUs: Anatomy of High Performance Matmul Kernels*](https://www.aleksagordic.com/blog/matmul) | H100 architecture, warp tiling, Hopper pipelines, and the reported optimization progression |
| Simon Boehm, [*How to Optimize a CUDA Matmul Kernel for cuBLAS-like Performance*](https://siboehm.com/articles/22/CUDA-MMM) | Further step-by-step study of conventional CUDA matrix multiplication |

Drepper's CPU experiments are historical examples. Carry forward the reasoning
about locality, working sets, and measurement; verify platform-specific cache
behavior, instructions, and timing on the system you actually use. CPU coherence
and GPU shared-memory synchronization are different subjects.

Several of his sections are worth reading on your own but are not drawn on in
this tutorial: §6.1 on bypassing the cache, §6.3 on hardware and software
prefetching and helper threads, §6.4 on multi-threaded access, and §7 on CPU
measurement tools. Two are close relatives of material here. §6.1 addresses the
write side of a matrix kernel, where storing an output can occupy cache space
that will not be read again. §6.3.4 splits a lookahead iteration into its own
thread because interleaving it with the working loop becomes too complex, which
is the argument for warp specialization in
[§15.3](#153-warp-specialization).

Most architecture and optimization diagrams in [figures](/gpu-matmul-assets/figures/) were adapted
from the GPU source article, with labels and explanations revised for this tutorial.
The four `beginner_*.svg` figures are original illustrations of this tutorial’s
worked matrix, memory-layout, thread-indexing, and tiling examples.
They are simplified models, not complete chip schematics. Colors generally use
blue for A or memory, red for B or compute, amber for C, and green for synchronization;
follow the labels because matrix roles and hardware roles are different contexts.

For implementation details, use the primary documentation:

- [CUDA Programming Guide](https://docs.nvidia.com/cuda/cuda-programming-guide/): programming model, launches, memory, and synchronization.

- [CUDA Best Practices Guide](https://docs.nvidia.com/cuda/cuda-c-best-practices-guide/index.html): coalescing, numerical validation, timing, and performance reasoning.

- [Hopper Tuning Guide](https://docs.nvidia.com/cuda/hopper-tuning-guide/index.html): resource limits and Hopper-specific behavior.

- [NVIDIA Hopper Architecture In-Depth](https://developer.nvidia.com/blog/nvidia-hopper-architecture-in-depth/): architecture and the distinction between H100 configurations.

- [PTX ISA: WGMMA completion](https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#asynchronous-warpgroup-level-matrix-instructions-wgmma-wait-group): exact instruction semantics; also consult its TMA and memory-model sections.

- [CUTLASS documentation](https://docs.nvidia.com/cutlass/): library implementations and layout abstractions for advanced kernels.

- [Nsight Compute Profiling Guide](https://docs.nvidia.com/nsight-compute/ProfilingGuide/index.html) and [Nsight Systems User Guide](https://docs.nvidia.com/nsight-systems/UserGuide/index.html): kernel analysis and application timelines.

To continue practicing, implement a transpose and a reduction, then return to
matrix multiplication with the same discipline: a reference answer, a stated
traffic model, an explicit timing boundary, and one change per experiment.
