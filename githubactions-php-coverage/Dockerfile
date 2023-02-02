ARG BASE_IMAGE=ghcr.io/glpi-project/githubactions-php:8.0

FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI Github Actions PHP container (with code coverage tools)" \
  org.opencontainers.image.description="This container is used to get code coverage from GLPI test suite on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

USER root

RUN \
  # Update APK package list.
  apk update \
  \
  # Install PHP build dependencies.
  && apk add --virtual .build-deps $PHPIZE_DEPS linux-headers \
  \
  # Install xdebug extension.
  && pecl install xdebug \
  && docker-php-ext-enable xdebug \
  && echo "xdebug.mode=coverage" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
  \
  # Remove PHP build dependencies.
  && apk del -f .build-deps \
  \
  # Clean sources list.
  && rm -rf /var/cache/apk/*

USER glpi
