# Alpine Linux + Docker Authentication with pass

This repo demonstrates how you can programatically automate securely logging into Docker in an Alpine Linux Dockerfile.

Blog post going into further details about this repository https://jer-k.github.io/apline-linux-docker-authentication-with-pass/

## Usage

Begin by adding your Docker password to `docker_password.txt` and any password of your liking to `gpg_password.txt`.

Build the image

```
$ DOCKER_BUILDKIT=1 docker build -t alpine_docker_pass --secret id=gpg_password,src=gpg_password.txt --secret id=docker_password,src=docker_password.txt --build-arg DOCKER_USER=your_docker_username .
```

Tag the image and push it to Dockerhub. To prove the authentication works, make sure you create the repository as private.

```
$ docker tag alpine_docker_pass:latest {your_docker_username}/alpine_docker_pass:latest
$ docker push {your_docker_username}/alpine_docker_pass:latest
```

Next, tag the image on a local repository. You don't actually need a registry running but this allows us to reference the image
in the `docker-compose.yml`.

```
$ docker tag alpine_docker_pass:latest localhost:5000/alpine_docker_pass:latest
```

Finally we can run the `docker-compose` file, shell into the running container, and pull down our private image.

```
$ docker-compose up
$ docker exec -it alpine_docker_pass_alpine_docker_pass_1 /bin/bash
$ docker pull {your_docker_username}/alpine_docker_pass:latest
```
