# Manage your task with TaskSpooler!



# What is [TaskSpooler](https://github.com/justanhduc/task-spooler)?

[TaskSpooler](https://github.com/justanhduc/task-spooler) (ts) is a lightweight job scheduler that allows you to queue up your tasks and execute them in order. It’s particularly useful for environments where tasks need to be managed sequentially or with a controlled degree of parallelism. Unlike more complex systems like SLURM, TaskSpooler is designed for simplicity and ease of use, making it accessible for individual researchers and small teams.

## Efficient Job Scheduling for ML/DL Researchers with Taskspooler
In the dynamic field of Machine Learning (ML) and Deep Learning (DL), managing and optimizing computational resources is crucial. For researchers frequently running numerous experiments, an efficient job scheduler can be a game-changer. Enter **Taskspooler**, a powerful yet user-friendly job scheduler for Linux, designed to help you manage and schedule your jobs in a queue. Taskspooler is a simpler alternative to SLURM, providing many benefits for ML/DL researchers, especially when it comes to utilizing GPUs efficiently.

### TL;DR
1. **Job Queuing**: Easily queue up multiple jobs, specifying the order of execution.
2. **Resource Management**: Find and allocate empty GPUs to your tasks, maximizing resource utilization.
3. **Monitoring**: Track the status of your jobs in real-time.
4. **Simplicity**: A straightforward command-line interface that requires minimal setup and configuration.
5. **Parallel Execution**: Control the number of jobs running simultaneously, which is essential for managing GPU workloads effectively.

## Dive into TaskSpooler

### Installation

First, clone the repository:

```sh
git clone https://github.com/justanhduc/task-spooler
```

#### Install GPU Version

To set up Task Spooler with GPU support, run the provided script:

```sh
./install_cmake
```

Alternatively, to use CMake:

```sh
./install_make
```

If Task Spooler is already installed, and you want to reinstall or upgrade, run:

```sh
./reinstall
```

#### Install CPU Version

If you would like to install only the CPU version, use the following commands (recommended):

```sh
make cpu
sudo make install
```

or via CMake:

```sh
mkdir build && cd build
cmake .. -DTASK_SPOOLER_COMPILE_CUDA=OFF -DCMAKE_BUILD_TYPE=Release
make
sudo make install
```

## Basic Usage

Let's first put your task into a queue:

```sh
ts python main.py
```

- This command queues up your `python main.py`.

Keeping track of running and pending jobs is crucial for optimizing your workflow. Taskspooler provides real-time updates on job status, allowing you to make informed decisions and adjustments on the fly. To check the overall queue status, simply type:

```sh
ts
```

This returns your jobs with the job ID, state, time, and the command you typed.

To track the status of your jobs:

```sh
ts -c <job-id>
```

You can delete finished jobs in the job list by:

```sh
ts -C
```

To set the size of your job queue (i.e., to limit/expand the number of parallel running processes):

```sh
ts -S <queue-size>
```

## GPU Utilization
For ML/DL researchers, GPUs are invaluable but often limited resources. Taskspooler helps you find available GPUs and assign tasks to them efficiently. This ensures that your experiments run smoothly without unnecessary delays due to resource contention.

To specify GPU indices for a job without checking whether they are free, use:

```sh
ts -g [id,...] python main.py
```

For instance:

```sh
ts -g 1 python main.py
```

This allows you to run your model on GPU 1.

To get the GPU usage:

```sh
ts -g
```

## Conclusion

Taskspooler offers a simple yet powerful solution for job scheduling and resource management, making it an excellent tool for ML/DL researchers. By effectively queuing your tasks and optimizing GPU usage, you can streamline your workflow and focus more on the research itself rather than managing computational resources. Whether you're working on a single machine or a small cluster, Taskspooler can significantly enhance your productivity and efficiency.

If you want to know more visit its official [github repo](https://github.com/justanhduc/task-spooler?tab=readme-ov-file)

Happy experimenting!

