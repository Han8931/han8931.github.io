---
weight: 1
title: "Docker Tutorial Part 4: Networks"
date: 2025-09-13
draft: false
author: Han
description: "A Docker tutorial."
tags: ["Docker", "network", "Programming", "DevOps", "Tutorial"]
categories: ["Docker", "DevOps", "Programming"]
---

This is part of my **Docker Basics** series — introductory guides to help you get started with Docker, learn key concepts, and build your skills step by step.

* **Part 1: [Understanding Container](https://han8931.github.io/docker-basics/)**
* **Part 2: [Basic Commands](https://han8931.github.io/docker-commands/)** 
* **Part 3: [Dockerfile](https://han8931.github.io/docker-dockerfile/)**
* **Part 4: [Networks](https://han8931.github.io/docker-networks/)**


# Docker Networking

Docker offers four built-in network drivers: **none, bridge, host,** and **overlay.**

- **Bridge (default)**: Creates an isolated, software-defined network. Containers on the same bridge get private IPs and can communicate with each other, while anything outside can't reach them unless you explicitly publish ports.
- **Host**: Removes the isolation layer and uses the host's network stack directly. The container shares the host's IP address and network interfaces.
- **Overlay**: Builds a virtual network that spans multiple Docker hosts, so containers on different machines can talk as if they're on the same one—handy for Docker Swarm.
- **None**: Disables networking (other than loopback) for the container.

You can create and manage custom networks of any of these types with the Docker CLI.

## None Network

A **none network** in Docker is a special type of network mode that disables all networking for a container. When a container is run in none network mode, it does not have access to any network resources and cannot communicate with other containers or the host machine. In short, *the container is completely isolated from external networks.*

The following command will fail because the container has no access to external networks.
```sh
docker run --network none alpine ping google.com
```
The none network is useful for running workloads that aren't supposed to use any network connections, for example, for offline data processing on mounted volumes.

## Bridge mode

In **bridge mode** (Docker's default), Docker creates a virtual Ethernet interface for each container and plugs it into a Linux bridge on the host (the default device is `docker0`). Each container receives a private IP on that subnet (`commonly 172.17.0.0/16`).

The host machine acts as a gateway for the containers, routing traffic between the containers and the outside network. When a container wants to communicate with another container or the host machine, it sends the packet to the virtual network interface. The virtual network interface then routes the packet to the correct destination.

By default, it's a `172.17.0.0/16` network and it's connected to a **virtual bridge network**, `docker0`, in your machine. Within this network, all traffic between containers and the host machine is allowed. 

By default, external systems cannot directly access containers unless you publish ports. It means containers in a given bridge network can only talk to other containers on the same bridge network by default.

- When Docker creates a bridge (`docker0` or a user-defined one), it sets up a virtual subnet with its own IP range (e.g., `172.18.0.0/16`).
- Containers attached to that bridge get IPs in that subnet.
- Docker also adds `iptables rules` to restrict traffic so only containers on the same bridge can reach each other.

All containers are attached to the default bridge network if no network was selected. You can create use a user-defined bridge by using the `--network` option when executing the docker run command. 

```sh
docker network create mybridge
docker run -d --network mybridge --name c1 alpine sleep 3600
docker run -it --network mybridge alpine ping c1
```

You can list all available networks using the following command:
```sh
docker network ls
```

## Host mode

In **host networking mode**, the container exploits the host's network stack and network interfaces directly. This means that the container shares your machine's IP address and network settings, and can directly access the same network resources. As a result, it can bind straight to host ports (no -p needed), but also competes with other processes for the same ports.

One of the main advantages of host networking mode is that it provides slightly better latency/throughput as the container doesn't have to go through an additional network stack. Also, it simplifies routing and debugging as everything appears on the host network. 

However, this mode is less secure than the other networking mode as the container has direct access to the host's network resources and can listen to connections on the host's interface. 

Example:
```sh
docker run --network host nginx
```
The Nginx server will be directly available on the host's IP without `-p` port mapping.

## Overlay

An **overlay network** is created by a manager node, which is responsible for maintaining the network configuration and managing the membership of worker nodes. The manager node creates a virtual network switch and assigns IP addresses to each container on the network. **It spans multiple Docker hosts, creating a distributed virtual network so containers on different machines can communicate as if they are on the same host.**

In Docker, this is typically used with Swarm: managers maintain network state; workers join and connect containers to the overlay. Under the hood, Docker uses **VXLAN** encapsulation to carry container traffic between nodes.

Example,
```sh
# Initialize Swarm on a manager node
docker swarm init

# Create an attachable overlay so both services and 'docker run' can join
docker network create -d overlay --attachable myoverlay

# Deploy a service onto the overlay
docker service create --name web --network myoverlay -p 80:80 nginx

# (Optional) Attach a regular container to the same overlay
docker run -d --name util --network myoverlay busybox sleep 1d
```

# docker network command

The `docker network` command is used to manage container networking. With it, you can create, inspect, list, remove, and connect/disconnect containers to networks.

By default, Docker creates a few networks automatically, but you can also define your own for better control and isolation.

It provides several benefits:
- Containers are isolated, but they often need to communicate with each other.
- Docker networks provide controlled connectivity: you can group containers, control who can talk to whom, and even connect containers across multiple hosts (with Swarm or Kubernetes).

- Creating a new network:
```sh
docker network create mynetwork
```
- Inspecting a network:
```sh
docker network inspect mynetwork
```
- Removing a network:
```sh
docker network rm mynetwork
```
- Listing networks:
```sh
docker network ls
```
- Connecting a container to a network:
```sh
docker network connect mynetwork CONTAINER_NAME_OR_ID
```
- Disconnecting a container from a network:
```sh
docker network disconnect mynetwork CONTAINER_NAME_OR_ID
```

## References

- The Linux DevOps Handbook, Damian Wojsław and Grzegorz Adamowicz

