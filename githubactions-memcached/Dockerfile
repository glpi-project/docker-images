ARG BASE_IMAGE=memcached:latest

FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI Github Actions Memcached container" \
  org.opencontainers.image.description="This container is used to run GLPI test suite on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

# Install netcat for healthcheck
USER root
RUN apt-get update \
  && apt-get install --assume-yes --no-install-recommends --quiet netcat \
  && rm -rf /var/lib/apt/lists/*

# Switch back to memcache user
USER memcache

HEALTHCHECK --interval=10s --retries=5 --timeout=5s \
  CMD /bin/nc -z 127.0.0.1 11211
