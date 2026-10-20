ARG BASE_IMAGE=php:apache-trixie
# Flavor of the PHP image: "apache" or "fpm".
ARG FLAVOR=apache


#####
# Fetch composer latest build
#####
FROM composer:latest AS composer

#####
# Shared base of the GLPI PHP images (Github Actions and development environment).
# It is not published, it is consumed by the other images through `docker-bake.hcl`.
#####
FROM $BASE_IMAGE

ARG FLAVOR

COPY --chmod=755 ./scripts/install-php-extensions.sh /usr/local/bin/install-php-extensions

RUN --mount=type=bind,from=ghcr.io/php/pie:bin,source=/pie,target=/usr/local/bin/pie \
  \
  # Install git used by PIE/composer when fetching dependencies.
  apt-get update \
  && apt-get install --assume-yes --no-install-recommends --quiet git \
  \
  # Install PHP extensions.
  && install-php-extensions exif gd intl ldap mbstring memcached mysqli bcmath pcntl redis zip xmlrpc apcu \
  \
  # Update PHP configuration.
  && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
  \
  # Enable apache mods (only for apache based images).
  && if [ "$FLAVOR" = "apache" ]; then a2enmod rewrite; fi \
  \
  # Install nodejs and npm.
  && apt-get install --assume-yes --no-install-recommends --quiet gnupg \
  && mkdir -p /etc/apt/keyrings \
  && curl --fail --silent --show-error --location https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor --output /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
  && apt-get update \
  && apt-get install --assume-yes --no-install-recommends --quiet nodejs \
  \
  # Install gettext used for translation files.
  && apt-get install --assume-yes --no-install-recommends --quiet gettext \
  \
  # Clean sources list
  && rm -rf /var/lib/apt/lists/*

# Copy composer binary
COPY --from=composer /usr/bin/composer /usr/bin/composer
