ARG BASE_IMAGE=redis:latest

FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI Github Actions Redis container" \
  org.opencontainers.image.description="This container is used to run GLPI test suite on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

HEALTHCHECK --interval=10s --retries=5 --timeout=5s \
  CMD redis-cli ping
