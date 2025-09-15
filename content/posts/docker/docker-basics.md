---
weight: 1
title: "Docker Tutorial Part 1: Basics"
date: 2025-09-13
draft: false
hiddenFromHomePage: false
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

Before diving into Docker, let's first contrast it with the traditional isolation model: **virtual machines (VMs)**. *Virtualization is a technique of running a complete simulated computer within another computer.* The simulated computer—called a **virtual machine (VM)**—emulates the components of a physical system: CPU, memory, motherboard/firmware, disks, and peripheral buses. A **hypervisor** (the software) manages one or more VMs on a **host** (the real machine).
- **Complete**: It mimics everything a physical computer would have: CPU, memory, motherboard, BIOS, disks, USB ports, and so on.
- **Simulated**: The machine exists entirely in software. It doesn't physically exist, which is why it's called virtual.

Virtualization is a great fit when you need:
- A full operating system distinct from the host (e.g., Windows on a Linux workstation);
- Strong isolation for testing in a controlled environment;
- Execution of applications unavailable on the host OS; or
- Faithful reproduction of production-like environments for development and debugging.

## Containerization (the modern approach)

A **Docker container** is like a shipping container for software—a self-contained "*box*" that carries an application and just what it needs to run. From inside, the app feels as if it has a whole computer to itself: its own hostname/IP, its own filesystem "*drive*", and its own process space.

Those are virtual resources that Docker creates and manages. Processes inside the box can't see beyond it, while the box runs on a real machine that can host many boxes at once. Each container has its own isolated environment, yet all containers share the host's CPU, memory, and kernel (on macOS/Windows, Docker supplies a lightweight Linux VM).

A **container** isolates an application and its immediate runtime; it does not simulate a complete computer. Processes execute on the host kernel with restricted views of the filesystem, process table, and network, and the image includes only the user-space libraries the application requires.

**Key properties:**
- **Lightweight, single-process by design:** Containers start fast (no firmware checks or OS boot) and images stay compact by excluding extras.
- **Minimal dependencies:** Each container bundles only the libraries it needs; treat containers as disposable—rebuild and redeploy instead of patching in place.
- **Host-managed hardware:** The host OS handles CPU, memory, devices, and peripherals.
- **Not a full OS:** Containers don't pretend to be virtual machines; processes can detect they're containerized.

**Limitations**

- No hardware emulation (e.g., you can't test a device driver).
- Container filesystems are ephemeral; persistent data should live in **volumes** or external storage attached at runtime.

**Benefits**

- Extremely small footprint (often just a few MB) and only the memory the process needs.
- Reproducible environments, frequent safe releases, and rapid horizontal scaling.

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

Docker is a packaging and runtime system for applications. Docker is made up of several core components:
- Command-line utility (docker)
- Host machine
- Objects (images, containers, volumes, networks)
- Registries (where images are stored and shared)

Let's take a look one by one

## Docker The Docker CLI tool – `docker`

The Docker CLI is your front door to the platform. The CLI communicates with the Docker host through an API exposed by the daemon (`dockerd`) to manage containers and images. The `docker` command is the primary way to manage containers and images. With `docker`, you can
- Build images.
- Pull images from registries.
- Push images to registries.
- Run and manage containers.
- Set runtime options.
- Remove containers and images.
- 
## Docker Host & Daemon (`dockerd`)

`dockerd` is the long-running engine that does the real work: it stores images, creates and supervises containers, wires up networks and volumes, and serves the Docker API. Internally it leans on standards-based runtimes (`containerd/runc`) to execute containers reliably.

- The host machine runs the Docker daemon (`dockerd`).
- Responsibilities of dockerd:
    - Stores images locally.
    - Creates and manages containers.
    - Provides resources such as networking and volumes.
    - Offers an API for interacting with containers and images.
    - Maintains metadata (container state, logs, configs).
    - Handles communication in Docker Swarm mode.
- Think of `dockerd` (daemon) as the engine that powers all Docker operations.

## What is an image?

An image is an immutable, layered snapshot of an app's user-space: binaries, libs, and config, plus metadata like entrypoint and exposed ports (everything needed to run an application). Built from a Dockerfile and identified by a content hash and tags, one image can spawn many identical containers.

Characteristics:
- Immutable: once built, it doesn't change.
- Reusable: can spawn multiple containers.
- Identified by a unique hash (SHA-256) and often tagged with human-readable labels.
Built using a Dockerfile, which specifies:
    - Base image.
    - Packages to install.
    - Files to copy.
    - Commands to run.
Workflow:
- `docker build`: reads instructions and creates image layers.
- `docker run`: starts a container from the image with a chosen process.
- If the primary process ends, the container stops.


## cgroups

`cgroups` (control groups) are a Linux kernel feature that lets you manage and isolate system resources for groups of processes. With cgroups, an administrator can:
- Allocate CPU, memory, and network bandwidth.
- Monitor resource usage.
- Enforce limits to prevent one workload from starving others.
This makes `cgroups` ideal for isolating different workloads on a shared system.

### Docker and cgroups

By default, Docker does not restrict CPU or memory usage for containers — a process can consume as much as the host allows. However, Docker integrates directly with cgroups, making it easy to apply resource limits without manually configuring kernel settings. Limits can be applied at container startup with flags in docker run.

You can limit the amount of memory a Docker container can use by using the `--memory` or `-m` option with the `docker run` command.

For example, use the following to run the alpine image with a memory limit of 500 MB:
```
docker run --memory 500m alpine /bin/sh
```
You can specify the memory limit in bytes, kilobytes, megabytes, or gigabytes by using the appropriate suffix (b, k, m, or g).

