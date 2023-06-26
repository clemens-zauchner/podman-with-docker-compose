# Using rootless podman with docker compose

Podman is a nice tool, that simplifies running rootless containers without the need for a separate, rootfull daemon. One of the tools that you might miss when migrating from docker to podman is docker compose, which provides an easy-to-use, declarative approach to building and running containers.

Since the podman API is compatible with the docker API, we can use docker compose with podman. This 
post shows you how you can get started.

## Host setup

On the host, you need 3 things: podman, docker compose, and a non-root user.

### Prerequisites

In this post it is assumed that
you have a system user set up already and podman installed. It is recommended to use a podman version 4, 
which ships with RHEL.

### Installing docker compose
You can download the latest version of docker compose directly from Github. In this case, we will simply 
use it from the home directory of the non-root user:

```bash
wget https://github.com/docker/compose/releases/latest/download/docker-compose-linux-$(uname -m) -O $HOME/bin/docker-compose
chmod +x $HOME/bin/docker-compose
export PATH="/home/$USER/bin:$PATH"
```


### Starting the podman API socket

Note: if you are using a system account, you need to export the `XDG_RUNTIME_DIR` to prevent the error
`Failed to connect to bus: No medium found`:

```bash
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
```

You can start the rootless podman API socket using:

```bash
systemctl --user start podman.socket
```

### Setting the DOCKER_HOST

You need to tell docker compose where to find the socket. 

If you skip this step and don't have docker installed, you will get an error like this:

> Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?

You can fix it by setting the `DOCKER_HOST` environment variable:

```bash
export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"
```

## The example application

Let's take a look at the `docker-compose.yml` file:

```yml
version: "3"
services:
  flask:
    build: .
    ports:
      - 5000:5000
```

We specify one service, called flask. For the image, the build context is the current directory. We also specify to expose a port, so we can see the output of flask.


### Building the image

You can build the image using `docker-compose build`. The build tool for podman is usually [buildah](https://buildah.io/), but if you use docker-compose, a builtkit container is started that build the image. 

When you look at the output of `podman ps`, you can see a container `buildx_buildkit_default` running. This is the container that builds the image.

### Starting and stopping the containers
To create and start the container, you can use `docker-compose up`. This command will create a network and start the flask container.

You can verify that everything works as expected using `curl`:

```bash
curl localhost:5000 && echo
Hello from Flask!
```

To stop the containers, you can use `docker-compose down`.

## Drawbacks

Podman has some features, that are not supported by docker-compose, e.g. pods or secrets. Although you can 
define secrets in the `docker-compose.yml`, this is only supported in swarm mode: 

```yml
version: "3"
services:
  flask:
    build: .
    ports:
      - 5000:5000
    secrets:
      - my_secret

secrets:
  my_secret:
    external: true
```

If you try that, you will get an error message `unsupported external secret mysecret`.

## Summary

Podman really does play nicely with docker compose. For simple applications or local development, it is
certainly an alternative. However, if you want to or need to use more advanced features, you will soon be
limited by the features of docker and docker compose. 
