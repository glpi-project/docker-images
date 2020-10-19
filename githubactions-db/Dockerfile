ARG BASE_IMAGE=mysql:latest

FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI Github Actions database container" \
  org.opencontainers.image.description="This container is used to run GLPI test suite on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

COPY ./files/etc/mysql/conf.d/custom.cnf /etc/mysql/conf.d/custom.cnf

HEALTHCHECK --interval=10s --retries=5 --timeout=5s \
  CMD mysqladmin ping
