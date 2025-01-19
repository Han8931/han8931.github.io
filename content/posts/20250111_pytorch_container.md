---
weight: 1
title: "Run Pytorch Container in Arch Linux"
date: 2025-01-11
draft: false
author: Han
description: "Setting Up DL/ML Environments"
tags: ["pytorch", "arch", "container", "docker"]
categories: ["programming", "linux"]
---


# Setting Up DL Experiment Environments

## A Challenge for Arch Linux Users

If you've ever tried to set up a new experiment environment for deep learning on Arch Linux, you're probably familiar with the challenges involved. Arch Linux, renowned for its rolling-release model and cutting-edge updates, provides unparalleled flexibility and control over your system. However, this same flexibility can often lead to headaches when setting up complex environments for machine learning or deep learning experiments. Dependency conflicts, missing libraries, and version mismatches are all too common.

One particular pain point is the setup of Python environments using tools like Conda or virtual environments. While these tools work seamlessly on many systems, Arch Linux users often encounter version conflicts. Installing Conda itself can be tricky and painful.

For researchers and developers, this process can feel like a significant barrier to productivity. Instead of focusing on model development or data analysis, hours are spent troubleshooting environment issues. On Arch Linux, where package versions are always at the bleeding edge, finding compatibility between your system and the tools required by frameworks like PyTorch can be very challenging.

**This is where Docker steps in to save the day.** By using Docker containers, you can create isolated, portable environments that encapsulate all the dependencies you need, regardless of the host operating system. For PyTorch users who rely on a CPU-only setup for studying DL/ML and testing PyTorch code, Docker offers a streamlined solution to avoid the usual hassle of configuring local environments on Arch Linux.

In this blog post, I will go over the process of setting up a PyTorch container using Docker, exploring how it simplifies the creation of a reproducible environment for your deep learning experiments.

## Install Docker on Arch

```
sudo pacman -S docker docker-compose docker-buildx
```

Then, 
```
sudo systemctl enable --now docker.service
```


## PyTorch Container 

### **Steps for Using PyTorch with CPU-Only Docker Image**

1. **Pull the CPU-Only PyTorch Docker Image**  
The latest PyTorch images without CUDA can be pulled using the following command:
```bash
docker pull pytorch/pytorch:latest
```

If you prefer a specific version, for example, PyTorch 1.13.1, use:
```bash
docker pull pytorch/pytorch:1.13.1-cpu
```


2. **Run the PyTorch Container**  
- Start the container interactively:
```bash
docker run -it --rm pytorch/pytorch:latest
```
- This will launch a Python environment with PyTorch installed.
- **Mount Your Project Files (Optional)**  
If you want to access your local project files inside the container, mount a directory:
```bash
docker run -it --rm -v $(pwd):/workspace pytorch/pytorch:latest
```
- `-it`
	- **`-i`**: Keeps STDIN open, allowing you to interact with the container (important for running interactive shells or REPLs).
	- **`-t`**: Allocates a pseudo-TTY, which is useful for interactive sessions.
- `--rm`: This flag automatically removes the container when it stops. It's useful to avoid cluttering your system with stopped containers.
- `-v $(pwd):/workspace`: This is the volume flag for mounting a directory. Here’s how it works:
	- `$(pwd)` refers to the current working directory on your **host machine** (outside the container).
	- `/workspace` is the directory **inside the container** where the mounted files will be accessible.
	- The files inside `/workspace` in the container are **directly linked** to the files in your host machine's current directory.
	- If you modify a script in your host machine, the changes will be visible inside the container immediately.
	- Similarly, if you create or edit a file inside the `/workspace` directory in the container, the changes will reflect on your host machine.


4. **Install Additional Python Libraries (If Needed)**  
Install any extra libraries required for your project:

```bash
pip install <package-name>
```

To save this setup for future use, create a custom Docker image with these dependencies pre-installed.


5. **Write and Test PyTorch Code**  
Create a simple PyTorch script (e.g., `test.py`):

```python
import torch

# Check if CUDA is available
print("CUDA Available:", torch.cuda.is_available())

# Perform a simple tensor operation
x = torch.tensor([5.0, 10.0, 15.0])
print("Tensor:", x)
```

Run it inside the container:

```bash
python test.py
```

The output should confirm that CUDA is not available and display the tensor.


6. **Save and Exit**  
To persist changes, save your code in the mounted directory (e.g., `/workspace`). You can also commit the container if you've made extensive modifications:

```bash
exit
docker ps -a # Find the container ID
docker commit <container_id> my_pytorch_cpu_image
```
- Note that the container would not appear if you run the container with `--rm`. 
