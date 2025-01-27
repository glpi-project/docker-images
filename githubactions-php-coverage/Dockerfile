ARG BASE_IMAGE=ghcr.io/glpi-project/githubactions-php:8.0

FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI Github Actions PHP container (with code coverage tools)" \
  org.opencontainers.image.description="This container is used to get code coverage from GLPI test suite on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

USER root

RUN \
  # Install pcov extension.
  pecl install pcov \
  && docker-php-ext-enable pcov \
  && echo "pcov.enabled=1" >> /usr/local/etc/php/conf.d/docker-php-ext-pcov.ini

USER glpi
