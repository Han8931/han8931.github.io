---
weight: 1
title: "Docker Tutorial Part 1: Basics"
date: 2025-09-13
draft: false
author: Han
description: "A Docker tutorial."
tags: ["Docker", "Programming", "DevOps", "Tutorial"]
keywords: ["docker tutorial", "docker basics"]
categories: ["Docker", "DevOps", "Programming"]
---

# Introduction

## Virtualization

*Virtualization is a technique of running a complete simulated computer within another computer.* 
- **Complete**: It mimics everything a physical computer would have: CPU, memory, motherboard, BIOS, disks, USB ports, and so on.
- **Simulated**: The machine exists entirely in software. It doesn't physically exist, which is why it's called virtual.

The simulated computer is called a **virtual machine (VM)**, and it needs a real, physical computer to run on. This real machine is known as the **host**, while the software that manages VMs is the **hypervisor**.

So, I have a physical computer. It is powerful. Why would I want to run a VM in it? Because VMs unlock powerful use cases:
- Running a full operating system that's different from your host (e.g., Windows VM on Linux).
- Testing software in a controlled, isolated environment.
- Running applications that are not available on your host OS.
- Recreating a production-like environment locally for development and debugging.

## Containerization

### Containers
- Containers are lightweight, isolated environments designed to run a single process.
- Each container includes only the libraries and dependencies necessary for the application to function.
- The host operating system handles hardware access, memory, and peripheral management.
- Unlike virtual machines, containers don't pretend to be full operating systems. Processes inside can detect they are running in a container.
- Limitation: containers cannot emulate hardware (e.g., you can't test a new device driver).
- Advantage: containers can be extremely small (just a few MB) and consume only the memory needed by the running process.

### Fast Startup & Portability

- A container launches as quickly as the application itself, since it skips BIOS checks, hardware initialization, and OS booting.
- Container images remain compact by excluding unnecessary software.
- Small images bring multiple benefits:
    - Rapid download and distribution.
    - Near-instant startup times.
    - Faster build and deployment cycles.
- As a result:
    - Development and test environments are easy to reproduce.
    - New versions of software can be deployed frequently (even thousands of times per day).
    - Applications can be scaled up or down quickly.

### Deployment Model

- Containers are treated as disposable units rather than long-lived systems.
- Instead of patching or upgrading software inside a container, you simply build a new image and redeploy it.
- This design assumes that:
    - Application data is not stored inside containers.
    - Persistent data should be managed through volumes or external storage attached at runtime.

### Docker and its Ecosystem
- Docker is the most popular container platform, largely because of the ecosystem it created.
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

