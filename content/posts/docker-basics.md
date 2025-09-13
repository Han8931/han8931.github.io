---
weight: 1
title: "Docker Tutorial Part 1: Basics"
date: 2025-09-13
draft: false
hiddenFromHomePage: true
author: Han
description: "A Docker tutorial."
tags: ["Docker", "Programming", "DevOps", "Tutorial"]
categories: ["Docker", "DevOps", "Programming"]
---

# Docker Fundamentals (Part 1)

Software systems frequently exhibit environment-dependent behavior: dependency versions drift, filesystem paths diverge, and minor operating-system differences produce major failures. **Containerization** addresses this by packaging an application together with its runtime dependencies so that a single artifact executes consistently across development laptops, continuous-integration pipelines, and production clusters. Formally: same package $\rightarrow$ same behavior across environments.


### A Minimal Example:

To build intuition, consider the following command:
```sh
docker run hello-world
```
At high level, `docker run` performs the following steps:
- **Pull the image**: If the specified image is not available locally, Docker pulls it from the configured container registry (e.g., Docker Hub).
- **Create a container**: Docker creates a new container from the specified image.
- **Allocate resources**: Docker allocates necessary resources for the container (e.g., network, storage).
- **Start the container**: Docker starts the container, running the specified command within it.
- **Attach the container**: If specified, Docker attaches your terminal to the container's input, output, and error streams.

> **Key terms**: *Docker images are the blueprints, then containers are the actual buildings*

## Virtualization (the classic approach)

*Virtualization is a technique of running a complete simulated computer within another computer.* The simulated computer—called a **virtual machine (VM)**—emulates the components of a physical system: CPU, memory, motherboard/firmware, disks, and peripheral buses. A **hypervisor** (the software) manages one or more VMs on a **host** (the real machine).
- **Complete**: It mimics everything a physical computer would have: CPU, memory, motherboard, BIOS, disks, USB ports, and so on.
- **Simulated**: The machine exists entirely in software. It doesn't physically exist, which is why it's called virtual.

Virtualization is appropriate when one requires:
- A full operating system distinct from the host (e.g., Windows on a Linux workstation);
- Strong isolation for testing in a controlled environment;
- Execution of applications unavailable on the host OS; or
- Faithful reproduction of production-like environments for development and debugging.

## Containerization (the modern approach)

A Docker container is the same idea as a physical container 
- Think of it like a box with an application in it. 
- Inside the box, the application seems to have a computer all to itself: 
    - It has its own machine name and IP address
    - It also has its own disk drive. 

Those thing are all virtual resources that are created by Docker. The application inside the box can't see anything outside the box, but the box is running on a computer, and that computer can also be running lots of other boxes. The applications in those boxes have their own separate environments (managed by Docker), but they all share the CPU and memory of the computer, and they all share the computer's OS.

A **container** isolates an application and its immediate runtime, but it does not simulate a complete computer. Processes run on the host kernel with restricted views of resources (filesystem, processes, network) and with only the libraries required by the application.

A container has properties:
- Containers are lightweight, isolated environments designed to run a single process.
    - Containers typically start as quickly as the application itself, as they avoid firmware checks and OS boot
    - Container images remain compact by excluding unnecessary software.
- Each container includes only the libraries and dependencies necessary for the application to function.
    - Containers are treated as disposable units rather than long-lived systems.
    - Instead of patching or upgrading software inside a container, you simply build a new image and redeploy it.
- The host operating system handles hardware access, memory, and peripheral management.
- Unlike virtual machines, containers don't pretend to be full operating systems. Processes inside can detect they are running in a container.
- Limitation: 
    - Containers cannot emulate hardware (e.g., you can't test a new device driver).
    - Application data is not stored inside containers.
    - Persistent data should be managed through volumes or external storage attached at runtime.
- Advantage: containers can be extremely small (just a few MB) and consume only the memory needed by the running process.

As a result:
- Development and test environments are easy to reproduce.
- New versions of software can be deployed frequently (even thousands of times per day).
- Applications can be scaled up or down quickly.

### Docker and its Ecosystem
Docker Hub is a cloud-based registry where you can find and share Docker images_. It contains a vast collection of images, ranging from official base images like Ubuntu and Node.js to custom images created by the community.


Docker is the most popular container platform, largely because of the ecosystem it created.
- A Docker image is essentially:
    - A compact archive with all binaries, libraries, and minimal configuration needed to run an application.
    - Stateless and easily shareable.
- Docker Hub provides:
    - A public registry for storing and discovering images.
    - Command-line and web tools for uploading, searching, rating, and giving feedback.
- This ecosystem made it easy to share and reuse container images, accelerating container adoption across the industry.
 
# Anatomy of Docker

Docker is made up of several core components:
- Command-line utility (docker)
- Host machine
- Objects (images, containers, volumes, networks)
- Registries (where images are stored and shared)

## Docker The Docker CLI tool – `docker`

- The `docker` command is the primary way to manage containers and images.
- With it, you can:
    - Build images.
    - Pull images from registries.
    - Push images to registries.
    - Run and manage containers.
    - Set runtime options.
    - Remove containers and images.
- The CLI communicates with the Docker host using an API.
- One CLI client can also manage multiple hosts, not just the local one.

## Docker Host & Daemon (`dockerd`)

- The host machine runs the Docker daemon (`dockerd`).
- Responsibilities of dockerd:
    - Stores images locally.
    - Creates and manages containers.
    - Provides resources such as networking and volumes.
    - Offers an API for interacting with containers and images.
    - Maintains metadata (container state, logs, configs).
    - Handles communication in Docker Swarm mode.
- Think of `dockerd` (daemon) as the engine that powers all Docker operations.

## OverlayFS

- **OverlayFS** is the modern storage driver Docker uses on Linux (default since v1.9.0).
- It replaced the older AUFS driver with a faster, more flexible approach.
- Works by layering directories:
    - Lower directory: base files (e.g., the image layers).
    - Upper directory: changes made by the container (new or modified files).
- File lookup process:
    - If a file exists in the upper layer, it's used.
    - Otherwise, Docker falls back to the lower layer.
- This model allows:
    - Containers to run on top of base images without modifying them.
    - Efficient use of storage (only differences are stored).
    - Fast image distribution and reuse in Kubernetes, OpenShift, etc.


## What is an image?

- A **Docker image** is a packaged filesystem + configuration that contains everything needed to run an application:
    - App code or binaries.
    - Required libraries and runtimes.
    - System tools and minimal OS dependencies.
    - Configurations (ports, environment defaults, entrypoint).
- Characteristics:
    - Immutable: once built, it doesn't change.
    - Reusable: can spawn multiple containers.
    - Identified by a unique hash (SHA-256) and often tagged with human-readable labels.
- Built using a Dockerfile, which specifies:
    - Base image.
    - Packages to install.
    - Files to copy.
    - Commands to run.
- Workflow:
    - docker build: reads instructions and creates image layers.
    - docker run: starts a container from the image with a chosen process.
    - If the primary process ends, the container stops.
```sh
docker pull ubuntu
docker inspect ubuntu
```

## What is a container runtime?

- The **container runtime (engine)** is what actually runs containers on a system.
- Tasks:
    - Load images from a registry.
    - Allocate resources (CPU, RAM, storage).
    - Start, monitor, and stop containers.
- Popular runtimes:
    - containerd: high-performance, widely used (default for Kubernetes).
    - LXC: older, very lightweight, but less user-friendly.
    - CRI-O: Kubernetes-native runtime, fully OCI-compliant.

## cgroups

- `cgroups` (control groups) are a Linux kernel feature that lets you manage and isolate system resources for groups of processes.
- With cgroups, an administrator can:
    - Allocate CPU, memory, and network bandwidth.
    - Monitor resource usage.
    - Enforce limits to prevent one workload from starving others.
- This makes cgroups ideal for isolating different workloads on a shared system.

### Docker and cgroups

- By default, Docker does not restrict CPU or memory usage for containers — a process can consume as much as the host allows.
- However, Docker integrates directly with cgroups, making it easy to apply resource limits without manually configuring kernel settings.
- Limits can be applied at container startup with flags in docker run.

You can limit the amount of memory a Docker container can use by using the `--memory` or `-m` option with the `docker run` command.

For example, use the following to run the alpine image with a memory limit of 500 MB:
```
docker run --memory 500m alpine /bin/sh
```
You can specify the memory limit in bytes, kilobytes, megabytes, or gigabytes by using the appropriate suffix (b, k, m, or g).

