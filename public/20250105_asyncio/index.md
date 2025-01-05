# Asyncio in Python: A Deep Dive into Asynchronous I/O


For the past few months, I've been working on an exciting internal project at my company: taking users' documents and running them through LLM APIs to translate and summarize their content, somewhat similar to [DeepL](https://www.deepl.com/). The output is a collection of translated documents, each overlaid with the newly translated text. Our goal is to provide a stable service that can handle large files efficiently for thousands of employees at Samsung—no small task! To achieve this, we needed a concurrency strategy that supports high throughput while remaining responsive. **That's where Asyncio comes in.**

In this post, we'll look at how Python tackles concurrency through **Asyncio**, a library designed to handle asynchronous I/O. We'll explore the concepts of concurrency, parallelism, multitasking, the difference between I/O-bound and CPU-bound tasks, and finally see how Asyncio harnesses cooperative multitasking to help your applications handle large-scale I/O more effectively. Whether you're building an internal service for employees or creating a high-performance web server, Asyncio's approach to concurrency might just be the key to unlocking the scalability you need.

# A Deep Dive into Asynchronous I/O

Modern software frequently needs to handle large volumes of input/output (I/O) operations. For instance, you might be retrieving data from web services, communicating with microservices over a network, or running multiple database queries simultaneously. These tasks can often take hundreds of milliseconds—or even seconds—if the network is under heavy load or the database is busy.

If you approach these operations in a strictly *synchronous* manner—doing one after another—each I/O request can block the execution of your entire application. When you have many such requests, total execution time can balloon significantly. Picture having to process 100 requests, each taking 1 second. Doing that sequentially results in a 100-second runtime. However, *if you can handle them concurrently*, you might complete all in roughly the same amount of time as a single request.

In this post, we’ll look at how Python tackles concurrency through **Asyncio**, a library designed to handle asynchronous I/O. We’ll explore the concepts of concurrency, parallelism, multitasking, the difference between I/O-bound and CPU-bound tasks, and finally see how Asyncio harnesses cooperative multitasking to help your applications handle I/O more efficiently.

---

## Why Concurrency Matters

### The Synchronous Bottleneck

In a **synchronous** application, each line of code must complete before moving on to the next. This is usually acceptable for simple tasks but becomes problematic if a single operation is slow or unresponsive. While any operation can block an application, many applications will be stuck waiting for I/O. _I/O refers to a computer's input and output devices such as a keyboard, hard drive, and, most commonly, a network card._ A classic example is a web server that processes each request in series; if one request takes longer than expected, all subsequent requests are delayed. Users of a slow website or client application may experience hang-ups, timeouts, or sluggish responsiveness due to this "queue" of operations.

### Concurrency as a Solution

**Concurrency** allows multiple tasks to be *in progress* simultaneously. In code terms, this often means starting multiple operations and then efficiently switching between them, so the application doesn't grind to a halt waiting on just one task. For I/O-bound tasks, concurrency can provide remarkable speedups because while one operation is waiting on a response, your program can continue working on other tasks.

### Concurrency vs. Parallelism

It’s important to distinguish **concurrency** from **parallelism**:

- **Concurrency** means you can have multiple tasks in progress at once, but they are not necessarily all running *at the exact same moment*.
- **Parallelism** means two or more tasks *truly run at the same time*, which requires at least as many CPU cores as the number of tasks you want to run in parallel.

Even on a single-core machine, you can achieve concurrency by rapidly switching (or *time slicing*) between tasks. However, *true* parallelism requires multiple CPU cores, letting tasks run simultaneously without interrupting each other.

---

## The I/O-Bound vs. CPU-Bound Distinction

When we label a particular operation as **I/O-bound** or **CPU-bound**, we're describing what fundamentally limits its performance.

- **I/O-Bound**: The operation spends most of its time waiting for I/O devices such as hard drives or network interfaces. Examples include fetching a remote web page, reading from a file, or waiting on a database query. These tasks can benefit significantly from concurrency, because while one operation waits, the program can do other work.
- **CPU-Bound**: The task is primarily gated by processor speed. Examples include computing the nth Fibonacci number using a recursive function, performing complex data analysis, or running CPU-intensive algorithms. *Concurrency alone may not help here, especially in Python, because of the* **Global Interpreter Lock (GIL)**.

---

## A Primer on Processes, Threads, and the GIL

### Processes

A **process** is a running instance of an application with its own memory space. An example of creating a Python process would be running a simple "hello world" application or typing python at the command line to start up the REPL (read eval print loop). Modern operating systems allow multiple processes to run at once. If your CPU has multiple cores, it can execute processes truly in parallel. Otherwise, the OS uses _time slicing_ to rapidly switch among processes.

### Threads

A **thread** is a more lightweight form of concurrency that runs within a single process, sharing the parent process's memory space. Threads have no their own memory. *A process will always have at least one thread associated with it, usually known as the main thread.* A process can also create other threads, which are more commonly known as *worker* or *background* threads. These threads can perform other work concurrently alongside the main thread. Threads, much like processes, can run alongside one another on a multi-core CPU, and the operating system can also switch between them via time slicing. When we run a normal Python application, we create a process as well as a **main thread** that will be responsible for running our Python application.

```
import os
import threading
	 
print(f'Python process with process id: {os.getpid()}')

num_threads = threading.active_count()
thread_name = threading.current_thread().name

print(f'{num_threads} thread(s) are running')
print(f'The current thread is {thread_name}')
```

#### Multithreading in Python

You might assume that starting multiple threads automatically takes advantage of multi-core systems. **However, Python has a key constraint called the Global Interpreter Lock (GIL).** The GIL ensures that only one thread can run one Python instruction at a time. This means that even on a multi-core machine, your Python code cannot run more than one CPU-bound thread simultaneously within the same process. 

**So, are threads useless in Python?** Far from it. Threads *do* provide genuine concurrency for I/O-bound tasks because Python releases the GIL during I/O operations. This allows you to overlap network calls, file reads, etc., effectively improving throughput. Yet for CPU-bound tasks, you won’t get true parallelism using just threads.

---

## The Global Interpreter Lock (GIL) in More Detail

The **Global Interpreter Lock** is often regarded as a tricky limitation in Python. At a high level, the GIL:

1. **Prevents multiple native threads from executing Python bytecode simultaneously**.
2. **Releases the lock** when code interacts with the operating system for I/O (e.g., network or disk).
3. **Reacquires the lock** once I/O completes and Python bytecode needs to be executed again.

Why does it exist? The main reason is memory safety in the **CPython** implementation, which relies heavily on *reference counting* to manage objects. While convenient, reference counting can become unsafe when multiple threads mutate the same objects without careful synchronization.

For I/O-bound code—like sending concurrent HTTP requests—this arrangement works well. You start multiple threads, each waiting on different I/O operations, and the GIL is periodically released while those operations happen, giving an overall speedup. For CPU-bound tasks—like computing Fibonacci numbers with a naive recursion—threads won’t help much because the lock is rarely released. Instead, you might use **multiprocessing** or specialized libraries that bypass the GIL for compute-intensive work.

---

## Enter Asyncio: Asynchronous I/O in a Single Thread

**Asyncio** is Python’s built-in library (introduced in Python 3.4 and improved in Python 3.5 with the `async` and `await` keywords) that focuses on concurrent I/O without the overhead of managing threads or processes. 

### Coroutines

The foundation of Asyncio is the concept of a **coroutine**—a special function that can pause itself (`await`) while waiting for an I/O operation, and then resume right where it left off once the operation completes. While one coroutine is waiting, other coroutines can continue running, effectively achieving concurrency *within a single thread*.

### Event Loop

At the core of every Asyncio program is the **event loop**. Think of it as a manager that schedules coroutines. The event loop steps through coroutines one by one:

1. A coroutine starts running until it hits an `await` for an I/O operation.  
2. The coroutine "pauses," returning control to the event loop.  
3. The event loop checks if there's another coroutine ready to run. If so, it switches to that coroutine immediately.  
4. Meanwhile, the operating system handles the actual I/O. Once the I/O is ready (e.g., the network has responded), the event loop "wakes up" the paused coroutine and resumes its execution.

Because **only one** thread is responsible for executing Python code, the GIL is never contended between multiple threads. 

---

## Where Asyncio Shines—and Where It Doesn't

### The Sweet Spot: I/O-Bound Work

Asyncio is *incredibly useful* when you’re dealing with a large number of concurrent I/O operations. Common examples include:

- Building high-performance web servers that handle thousands of simultaneous connections.  
- Writing web scrapers that fetch and parse dozens or hundreds of pages concurrently.  
- Coordinating multiple microservice requests in a single workflow without blocking.

In these scenarios, Asyncio’s single-threaded event loop can handle many I/O-bound coroutines, each pausing when it must wait for data. This often results in a dramatic improvement in throughput compared to a purely synchronous approach.

### Handling CPU-Bound Work

What if your task is mainly compute-heavy? Asyncio won't magically run CPU-bound code in parallel because the GIL still applies to Python bytecode, and you’re still on a single thread. For CPU-bound tasks—like image processing, machine learning, or large-scale data transformations—you'd likely want to offload work to another process or leverage special libraries that release the GIL. 

That said, Asyncio does provide *interoperability* with **threading** and **multiprocessing**; you can combine CPU-intensive tasks with your I/O-bound coroutines. For instance, you can use `asyncio.to_thread` (in Python 3.9+) to run a CPU-bound function in a separate thread or harness a process pool executor for true parallelism at the CPU level.

---

## Putting It All Together: An Example

Below is a simplified comparison of synchronous, multithreaded, and Asyncio-based approaches to fetching two web pages:

### Synchronous Approach

```python
import time
import requests

def fetch_example():
    response = requests.get('https://www.example.com')
    return response.status_code

def sync_fetch():
    start = time.time()
    status_one = fetch_example()
    status_two = fetch_example()
    end = time.time()
    print(f"Synchronous: {status_one}, {status_two}, time={end - start:.4f}s")

if __name__ == "__main__":
    sync_fetch()
```

**Synchronous** mode fetches one URL at a time. If each request blocks for one second, the total time is roughly two seconds.

Here, Python will release the GIL while waiting for the network, letting both threads run concurrently. The total time is potentially cut almost in half, assuming the responses come back quickly.

### Asyncio Approach

```python
import time
import asyncio
import aiohttp

async def async_fetch_example():
    async with aiohttp.ClientSession() as session:
        async with session.get('https://www.example.com') as response:
            status = response.status
            print(status)

async def main():
    start = time.time()
    await asyncio.gather(async_fetch_example(), async_fetch_example())
    end = time.time()
    print(f"Asyncio: time={end - start:.4f}s")

if __name__ == "__main__":
    asyncio.run(main())
```

With **Asyncio**, both fetch operations are initiated concurrently in the same thread, with the event loop switching between them whenever one is waiting for I/O. Like multithreading, you should see a meaningful speedup compared to the synchronous approach—but without the complexities of shared data across threads.



