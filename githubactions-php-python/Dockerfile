ARG BASE_IMAGE=ghcr.io/glpi-project/githubactions-php:8.2


#####
# Build main image
#####
FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI Github Actions PHP container (with Python tools)" \
  org.opencontainers.image.description="This container is used to run GLPI plugin release tools on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

USER root

RUN \
  # Update package list (base image cleans it at build time)
  apt update --quiet \
  \
  # Install Python and dependencies used by https://github.com/glpi-project/tools (soon to be DEPRECATED)
  && apt install --assume-yes --no-install-recommends --quiet python3 python3-git python3-gitdb python3-github python3-lxml python3-termcolor \
  && ln -sf /usr/bin/python3 /usr/bin/python \
  \
  # Clean sources list.
  && rm -rf /var/lib/apt/lists/*

USER glpi
