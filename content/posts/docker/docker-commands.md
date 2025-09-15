---
weight: 1
title: "Docker Tutorial Part 2: Basic Commands"
date: 2025-09-13
draft: false
author: Han
description: "A Docker tutorial. " 
tags: ["Docker", "Containers", "Programming", "DevOps", "Tutorial"]
categories: ["Docker", "DevOps", "Programming"]
---

This is part of my **Docker Basics** series — introductory guides to help you get started with Docker, learn key concepts, and build your skills step by step.

* **Part 1: [Understanding Container](https://han8931.github.io/docker-basics/)**
* **Part 2: [Basic Commands](https://han8931.github.io/docker-commands/)** 
* **Part 3: [Dockerfile](https://han8931.github.io/docker-dockerfile/)**
* **Part 4: [Networks](https://han8931.github.io/docker-networks/)**

## Common Commands
This is a no-frills cheat sheet for the Docker commands you'll reach for most of the time, with tiny runnable examples you can copy/paste.

The most common commands you can use are the following:
- `build`: This allows you to build a new Docker image using a Dockerfile
- `run`: This starts a new container
- `start`: This restarts one or more stopped containers
- `stop`: This will stop one or more running containers
- `login`: This is used to gain access to private registries
- `pull`: This downloads an image or a repository from a registry
- `push`: This uploads an image or a repository to a registry
- `images`: This lists all images on your machine
- `ps`: This lists all running containers
- `exec`: This executes a command in a running container
- `logs`: This shows the logs of a container
- `network`: This is used to manage Docker networks
- `volume`: This is used to manage volumes

## docker build

`docker build` turns a Dockerfile + build context into an image.
```sh
docker build [OPTIONS] PATH | URL | -
```
- `PATH` is the path to the directory containing the Dockerfile.
- `URL` is the URL to a Git repository containing the Dockerfile.
- `-` (a dash) is used to build an image from the contents of stdin, so you could pipe Dockerfile content to it from the output of some previous command that would build a Dockerfile, for example, generate it from a template.

To build from the current directory:
```sh
docker build .
```
You can also use a specific tag for the build image:
```sh
docker build -t my-image:1.0 .
```
- `-t my-image:1.0`: This assigns the tag `my-image:1.0` to the image you're building.

You can pass build-time variables by `--build-arg`
```sh
docker build --build-arg VAR1=value1 -t my-image:1.0 .
```

## docker run

When you run a container, you're taking a Docker image (a snapshot blueprint with all the software and configuration baked in) and launching a process inside it.
- An image is read-only. Think of it as the recipe.
- A container is a running instance of that image, with its own writable layer and runtime state.

The docker run command starts a new container from an image. For example:
```sh
docker run myimage /bin/bash
```
- This starts a container based on `myimage`.
- Once inside, you're running a bash shell inside the container's isolated environment.

You can pass additional options to control how the container behaves. Example:
```bash
docker run -d -p 8080:80 --name mynginx nginx
```
- Docker downloads the official **nginx** image if not present.
- Starts it in the **background** (in detached mode) (`-d`).
- Maps port 80 in the container to port 8080 on the host (`-p 8080:80`), 
- You can now visit `http://localhost:8080` in your browser.
- The container has the **name `mynginx`**, so you can later run:
```bash
docker logs mynginx   # see what's happening inside
docker stop mynginx   # stop it
docker start mynginx  # start it again
docker exec -it mynginx bash  # Run a shell inside the container # Run a shell inside the container
```

<p style="text-align:center;"> 
  <img src="/posts/docker/images/container_network.png" alt="Container Example" height="400">
</p>


### environment variables
You can also pass environment variables to the container:
```sh
docker run -e VAR1=value1 -e VAR2=value2 myimage:latest
```
- Set environment variables inside the container. Inside the container, any process can read them like:
```sh
echo $VAR1   # prints value1
echo $VAR2   # prints value2
```

## docker volume

By default, Docker containers are **ephemeral** — once a container is stopped and removed, all data stored inside its writable layer is lost. To persist data beyond the lifecycle of a container, you need to store it outside the container's filesystem.

Docker provides two main ways to do this:
- **Volumes**: storage fully managed by Docker.
- **Bind mounts**: directly map a host directory into a container.

### Docker Volume

A volume is storage created and managed by Docker.
- Volumes live under Docker's data directory, usually:
```
/var/lib/docker/volumes/
```
- Volumes are independent of containers, meaning you can delete and recreate containers without losing data.
- Multiple containers can share the same volume.

You can create a volume by
```sh
docker volume create myvolume
```

To start a container with that volume mounted:
```sh
docker run -it --name test1 -v myvolume:/data busybox
```
- `myvolume`: the name of the Docker-managed volume
- `/data`: mount point inside the container
Inside the container:
```sh
echo "hello world" > /data/hello.txt
```
Exit and remove the container:
```sh
exit
docker rm -f test1
```
Now run another container with the same volume:
```sh
docker run -it --name test2 -v myvolume:/data busybox
cat /data/hello.txt
```
You'll see hello world persisted across containers.

### Bind Mount (using a host directory)

A **bind mount** links a folder on your host machine directly into the container. Useful for development or when you need full control over where data lives.
- This is very useful for development (live-editing code on your host and seeing changes inside the container).
- Unlike volumes, you control the exact path where the data is stored.
```sh
docker run -it --name test3 -v /home/admin/data:/app/data busybox
```
- `/home/admin/data`: directory on your host
- `/app/data`: directory inside the container
Anything written to `/app/data` inside the container appears in `/home/admin/data` on the host.

### Inspecting Volumes

List volumes:
```sh
docker volume ls
```
Inspect a specific volume:
```sh
docker volume inspect myvolume
```
Remove a volume (when no container uses it):
```sh
docker volume rm myvolume
```

## docker start
The `docker start` command is used to restart containers that were previously created but are currently stopped.
- Unlike `docker run`, which creates a new container from an image, docker start simply restarts an existing container.
- This means the container's state (its filesystem, volumes, and configuration) is preserved.
```sh
docker start mycontainer
docker start mycontainer othercontainer lastcontainer ## To stop multiple containers
```
- Here, `mycontainer, othercontainer`, and `lastcontainer` can be either container names or IDs.
- You can check all running and stopped containers using the `docker ps` or `docker ps -a` (all running + stopped containers) command. 

By default, `docker start` runs containers in the background (detached). If you want to see the logs and interact with the process, add the `-a` flag:
```sh
docker start -a mycontainer
```

## docker stop

This command is used to stop containers running in the background. 
```sh
docker stop mycontainer
docker stop mycontainer othercontainer lastcontainer
```
- By default, Docker sends a `SIGTERM` signal to allow the process inside the container to exit gracefully.
- If the process does not exit within 10 seconds, Docker sends a `SIGKILL` to force termination.

You can change the timeout with `-t`:
```sh
docker stop -t 10 mycontainer
```
This waits up to 10 seconds before forcing a kill.

## docker ps

This command is used to list the running or stopped containers. When you run the `docker ps` command without any options, it will show you the list of running containers along with their container ID, names, image, command, created time, and status:
```sh
docker ps
docker ps -a # To view all containers (running + stopped)
```
You can use the `--quiet` or `-q` option to display only the container IDs, which might be useful for scripting:
```sh
docker ps --quiet
```
There are some useful options:
- `-q, --quiet`: show only container IDs (handy in scripts)
- `-f, --filter`: filter by conditions (e.g., name, status, ancestor image)
```sh
docker ps --filter "name=nginx"
```
- `-s`: show container disk usage (size of writable layer)
```sh
docker ps -s
```

## docker login
The docker login command is used to log in to a *Docker registry*. 
- A registry is a place where you can store and distribute Docker images. 
- The default registry is *Docker Hub*, but you can specify a custom registry. 
```sh
docker login quay.io
```

To avoid typing passwords interactively (safer for automation), you can use the `--password-stdin` or `-P` option to pass your password via `stdin`:
```sh
echo "mypassword" | docker login --username myusername --password-stdin
```

## docker pull
To pull a Docker image, you can use the `docker pull <image-name>:<tag>`. By default, `pull` will pull an image with a tag `latest`.

For example, 
```sh
docker pull alpine
```

To pull a specific version of the alpine image,
```sh
docker pull alpine:3.12
```

You can also pull an image from a different registry by specifying the registry URL in the image name.
```
docker pull myregistry.com/myimage:latest
```

## docker push

By default, push will try to upload an image to the Docker Hub registry:
```sh
docker push myimage
```

Typically, you tag your image first:
```sh
docker tag myimage:latest myimage:1.0
docker push myimage:1.0
```
- `docker tag`: Creates an alias (new tag) for an existing image.
- `myimage:latest`: The source image. This is the local image you already built (with tag latest).
- `myimage:1.0`: The new tag (alias).

## docker image

To list available images on your machine, you can use the `docker image ls` command:
```sh
docker image ls
```
To pull an image from the Docker registry,
```sh
docker image pull ubuntu
```

To build an image:
```sh
docker image build -t <image_name> .
```

To create a tag for an image
```sh
docker image tag <image> <new_img_name>
```

To remove,
```sh
docker image rm <image>
```

### Save Docker Image as a File

To save,
```sh
docker save -o <file-name>.tar <docker-image>
```

To load,
```sh
docker load -i <file-name>.tar
```

### Dangling images

A dangling image is an image that:
- Has no tag (shows up as `<none>` in docker images).
- Is not referenced by any container.

They're usually created when:
- You build a new image with the same tag — the old image becomes untagged.
- A build fails or is interrupted, leaving partial image layers.

For instance, 
```
$ docker images
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
myapp        latest    1a2b3c4d5e6f   2 minutes ago  130MB
<none>       <none>    7g8h9i0j1k2l   3 minutes ago  129MB   # dangling image
```
They waste disk space but are safe to delete.

You can list dangling images by
```sh
docker images -f dangling=true
```
- This shows all `<none>` images.


To remove dangling images (unused images):
```sh
docker image prune
```
- This command will remove all unused images (dangling images).

Docker will ask for confirmation. Add `-f` to skip the prompt:
```sh
docker image prune -f
```

Remove all unused images (not just dangling ones):
```sh
docker image prune -a
```

If you want to remove everything unused (e.g., containers, networks, images, build cache)
```sh
docker system prune
```

## docker exec

`docker exec` allows you to run a command in a running Docker container. For example,
```sh
docker exec mycontainer ls
```

You can run a interactive shell:
```sh
docker exec -it mycontainer bash
```

## docker logs

`docker logs` is used to view logs generated by a Docker container:
```sh
docker logs CONTAINER_NAME_OR_ID
```
Additional options you can pass to the command are as follows:
- `--details`, `-a`: Show extra details provided to logs
- `--follow`, `-f`: Follow log output
- `--since`, `-t`: Only display logs since a certain date (e.g., 2013-01-02T13:23:37)
- `--tail`, `-t`: Number of lines to show from the end of the logs (default all)

For example,
```sh
docker logs -f --tail 50 mycontainer
```
