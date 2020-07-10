# syntax = docker/dockerfile:experimental
FROM alpine

ENV USER=docker_user
ENV HOME=/home/$USER

RUN addgroup -S appgroup && adduser -u 1001 -S $USER -G appgroup

RUN apk --update upgrade && apk add --update  docker \
                                              gnupg \
                                              pass \
                                              busybox

# As of 7/10/2020 the latest release of docker-credential-helpers is 0.6.3
RUN wget https://github.com/docker/docker-credential-helpers/releases/download/v0.6.3/docker-credential-pass-v0.6.3-amd64.tar.gz \
    && tar -xf docker-credential-pass-v0.6.3-amd64.tar.gz \
    && chmod +x docker-credential-pass \ 
    && mv docker-credential-pass /usr/local/bin/ \
    && rm docker-credential-pass-v0.6.3-amd64.tar.gz

# Create the .docker directory, copy in the config.json file which sets the credential store as pass, and set the correct permissions
RUN mkdir -p $HOME/.docker/
COPY config.json $HOME/.docker/
RUN chown -R $USER:appgroup $HOME/.docker
RUN chmod -R 755 $HOME/.docker

# Create the .gnupg directory and set the correct permissions
RUN mkdir -p $HOME/.gnupg/
RUN chown -R $USER:appgroup $HOME/.gnupg
RUN chmod -R 700 $HOME/.gnupg

WORKDIR $HOME

COPY gpg_file.txt .

USER $USER

# Edit the gpg file to add our password and generate the key
RUN --mount=type=secret,id=gpg_password,uid=1001 cat gpg_file.txt | sed 's/gpg_password/'"`cat /run/secrets/gpg_password`"'/g' | gpg --batch --generate-key

# Generate the pass store by accessing and passing the gpg fingerprint
RUN pass init $(gpg --list-secret-keys dockertester@docker.com | sed -n '/sec/{n;p}' | sed 's/^[ \t]*//;s/[ \t]*$//')

# Login to Docker
ARG DOCKER_USER
RUN --mount=type=secret,id=docker_password,uid=1001 cat /run/secrets/docker_password | docker login --username $DOCKER_USER --password-stdin

# Using cat with busybox will keep the container running
CMD ["cat"]
