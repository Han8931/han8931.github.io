# Docker Tutorial Part 3: Dockerfile


## Dockerfile

A `Dockerfile` is essentially a text file with a predetermined structure that contains a set of instructions for building a Docker image. The instructions in the Dockerfile specify what base image to start with (for example, Ubuntu 20.04), what software to install, and how to configure the image. The purpose of a Dockerfile is to automate the process of building a Docker image so that the image can be easily reproduced and distributed.

The structure of a Dockerfile is a list of commands (one per line) that Docker (containerd to be exact) uses to build an image. Each command creates a new layer in the image in UnionFS, and the resulting image is the union of all the layers. The fewer layers we manage to create, the smaller the resulting image.

The most frequently used commands in a Dockerfile are the following:
- `FROM`
- `COPY`
- `ADD`
- `EXPOSE`
- `CMD`
- `ENTRYPOINT`
- `RUN`
- `LABEL`
- `ENV`
- `ARG`
- `VOLUME`
- `USER`
- `WORKDIR`

### FROM

A Dockerfile starts with a FROM command, which specifies the base image to start with:
```Dockerfile
FROM ubuntu:20.04
```
You can also name this build using as keyword followed by a custom name:
```Dockerfile
FROM ubuntu:20.04 as builder1
```
`docker build` will try to download Docker images from the public Docker Hub registry, but it's also possible to use other registries out there, or a private one.

### COPY and ADD

The `COPY` command is used to copy files or directories from the host machine to the container file system. Take the following example:

```Dockerfile
COPY . /var/www/html
```
You can also use the `ADD` command to add files or directories to your Docker image. `ADD` has additional functionality beyond `COPY`. It can extract a TAR archive file automatically and check for the presence of a URL in the source field, and if it finds one, it will download the file from the URL. Finally, the `ADD` command has a `--chown` option to set the ownership of the files in the destination. 

**In general, it is recommended to use `COPY` in most cases**, and only use `ADD` when the additional functionality it provides is needed.

### EXPOSE

The `EXPOSE` command in a Dockerfile informs Docker that the container listens on the specified network ports at runtime. It does not actually publish the ports. It is used to provide information to the user about which ports are intended to be published by the container.

For example, if a container runs a web server on port `80`, you would include the following line in your Dockerfile:
```Dockerfile
EXPOSE 80
```
You can specify whether the port listens on TCP or UDP – after specifying the port number, add a slash and a TCP or UDP keyword (for example, `EXPOSE 80/udp`). The default is TCP if you specify only a port number.

The `EXPOSE` command does not publish the ports. To make ports available, you will need to publish them with the use of the `-p` or `--publish` option when running the docker run command:

```sh
docker run -p 8080:80 thedockerimagename:tag
```
This will map port `8080` on the host machine to port `80` in the container so that any incoming traffic on port `8080` will be forwarded to the web server running in the container on port `80`.

Regardless of the `EXPOSE` command, you can publish different ports when running a container. `EXPOSE` is used to inform the user about which ports are intended to be published by the container.

### ENTRYPOINT and CMD

The `ENTRYPOINT` instruction defines the command that will always be executed when the container starts. It essentially turns the container into an executable that behaves like a binary or script. Unlike `CMD`, which can be fully replaced by arguments at runtime, `ENTRYPOINT` is fixed, and arguments you pass with docker run are simply appended to it.

You usually use `ENTRYPOINT` when you want your container to act like a single-purpose tool.
```Dockerfile
ENTRYPOINT ["curl"]
```
- Running `docker run mycurl https://example.com` executes`curl https://example.com`
    - `docker run`: start a new container.
    - `mycurl`: the image name.
    - `https://example.com`: arguments passed to the container.

Docker does the following internally:
1. Looks at the image `mycurl`.
2. Sees that the `ENTRYPOINT` is set to `["curl"]`.
3. Appends your command-line arguments (`https://example.com`) to the `ENTRYPOINT`.
4. It become `curl https://example.com`

If you want to provide default arguments that can be overridden, you combine it with `CMD`.

```Dockerfile
ENTRYPOINT ["python"]
CMD ["app.py", "--debug"]
```
- Running `docker run myapp`:`python app.py --debug` 
- Running `docker run myapp server.py`: `python server.py`

Meanwhile, if you only use `CMD`, it's fully replaceable at runtime.
```Dockerfile
CMD ["nginx", "-g", "daemon off;"]
```
- Running `docker run webserver`: runs nginx
- Running `docker run webserver bash`: runs bash instead (overrides `CMD`)

Rule of thumb:
- Use `ENTRYPOINT` if the container should always execute a specific binary.
- Use `CMD` for providing defaults that the user might want to override.
- Combine both if you want an executable with flexible arguments.

### RUN

The `RUN` instruction is executed at build time and creates a new layer in the image. It's used to install software, configure the environment, or set up files. Once executed, its results are part of the final image.

For example, you can use the `RUN` command to install system dependencies and clean up:
```Dockerfile
RUN apt-get update && \
    apt-get install -y git curl && \ # install required tools
    rm -rf /var/lib/apt/lists/* # Cleanup reduces image size.
```

You can use the RUN command to create a directory:
```Dockerfile
RUN mkdir -p /data/logs
```

or prepare a non-root user:
```Dockerfile
RUN useradd -ms /bin/bash appuser
```
It's worth noting that the order of the `RUN` commands in the Dockerfile is important, as each command creates a new layer in the image, and the resulting image is the union of all the layers. So, if you're expecting some packages to be installed later in the process, you need to do it before using them.

### LABEL

The `LABEL` instruction attaches metadata to an image in the form of key-value pairs. This can include maintainer info, version, licensing, or anything meaningful to your workflow.
```Dockerfile
LABEL maintainer="Alice Lee <alice@example.com>" \
      version="1.4" \
      description="Lightweight API server image"
```
This metadata can later be queried:
```Dockerfile
docker inspect myimage | grep version
```
Labeling images makes them easier to manage, track, and audit in CI/CD pipelines.

### ENV and ARG

Both define variables, but their lifetimes differ:
- `ARG`: available only at build time. Used to pass values when running docker build.
- `ENV`: It creates an environment variable that is accessible to all processes running inside the container.

```Dockerfile
ARG APP_VERSION=latest
RUN echo "Building version $APP_VERSION"
```
You can override it at build:
```Dockerfile
docker build --build-arg APP_VERSION=2.0 .
```

The `ENV` command is used to set environment variables:
```Dockerfile
ENV PORT=8080
EXPOSE $PORT
```
Now any process inside the container can access $PORT.

Rule of thumb:
- Use `ARG` for build-time options (e.g., base image tag, dependency version).
- Use `ENV` for runtime configuration (e.g., service port, API key).

### VOLUME


The `VOLUME` instruction in a Dockerfile defines a mount point where data can be stored outside the container's writable layer. 
- This means that the data will persist even if the container is removed or rebuilt.
- Volumes are managed by Docker, or you can bind them to host directories.
- They're especially important for databases, logs, or user-generated content.

When you run a container without volumes, everything is stored in its writable layer.
- That writable layer is destroyed when you remove the container (`docker rm`).
- That's why data disappears.

When you declare a `VOLUME` in the Dockerfile (or with `-v` at `docker run`), Docker does something special:
- It says: "Don't keep this folder (/var/lib/mysql) inside the container's temporary writable layer."
- Instead, it mounts an external storage location (on the host) to that folder.
- The container sees `/var/lib/mysql` as normal, but under the hood, all files actually live in:
```
/var/lib/docker/volumes/<volume_id>/_data   (if Docker-managed volume)
```
or
```
/my/local/db   (if you used -v /my/local/db:/var/lib/mysql)
```

Imagine you're building a Docker image for MySQL. You don't want your database data to disappear every time the container restarts.
```Dockerfile
FROM mysql:8.0

## Define where MySQL stores its data
VOLUME ["/var/lib/mysql"]

EXPOSE 3306
```
- `VOLUME ["/var/lib/mysql"]` tells Docker that `/var/lib/mysql` should be stored outside the container layer system.
You can see the volume with 
```sh
docker volume ls
docker volume inspect <volume_name>
```

### USER

By default, containers run as **root**, which is risky. The `USER` instruction sets a non-root user for better security.
- If there's a Docker or kernel vulnerability, a process running as root inside the container could potentially escape and gain root access on the host.
- This is the main worry in multi-tenant environments (like shared servers or Kubernetes clusters).

```Dockerfile
RUN useradd -ms /bin/bash appuser
USER appuser
```
- Now every process inside the container runs as `appuser`.
- `-m`: create the user's home directory (e.g., `/home/appuser`).
- `-s /bin/bash`: set the user's login shell to `/bin/bash`.

You can still override:
```sh
docker run --user root myimage
```

### WORKDIR

The `WORKDIR` instruction sets the **current working directory** inside the container. Every subsequent `RUN, CMD, ENTRYPOINT, COPY`, or `ADD` will be executed relative to this directory.

You can use the `WORKDIR` command to set the working directory to `/usr/local/app`:
```Dockerfile
WORKDIR /usr/local/app
```

```Dockerfile
WORKDIR /usr/src/app
COPY . .
RUN pip install -r requirements.txt
```
- `COPY . .`: copies files into`/usr/src/app` 
- `RUN pip install -r requirements.txt`: runs inside `/usr/src/app`

The `WORKDIR` can be changed multiple times during an image build.
```Dockerfile
FROM ubuntu:22.04

# First working directory
WORKDIR /app
RUN echo "Hello" > hello.txt

# Change to another directory
WORKDIR /app/subdir
RUN echo "World" > world.txt

# Copy from build context relative to new WORKDIR
COPY main.py .
```

