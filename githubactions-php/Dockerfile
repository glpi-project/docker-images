ARG BASE_IMAGE=php:fpm-alpine


#####
# Fetch composer latest build
#####
FROM composer:latest AS composer

#####
# Build main image
#####
FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI Github Actions PHP container" \
  org.opencontainers.image.description="This container is used to run GLPI test suite on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

RUN \
  # Update APK package list.
  apk update \
  \
  # Install PHP build dependencies.
  && apk add --virtual .build-deps $PHPIZE_DEPS \
  \
  # Install exif extension.
  && docker-php-ext-install exif \
  \
  # Install GD PHP extension.
  && apk add freetype-dev libjpeg-turbo-dev libpng-dev libwebp-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
  && docker-php-ext-install gd \
  \
  # Install intl PHP extension.
  && apk add icu-dev icu-data-full \
  && docker-php-ext-install intl \
  \
  # Install ldap PHP extension.
  && apk add --virtual .ldap-build-deps openldap-dev \
  && apk add libldap \
  && docker-php-ext-install ldap \
  && apk del -f .ldap-build-deps \
  \
  # Install memcached PHP extension.
  && apk add libmemcached-dev \
  && pecl install memcached \
  && docker-php-ext-enable memcached \
  \
  # Install mysqli PHP extension.
  && docker-php-ext-install mysqli \
  \
  # Install pcntl PHP extension (required for composer-require-checker).
  && docker-php-ext-install pcntl \
  \
  # Install redis PHP extension.
  && pecl install redis \
  && docker-php-ext-enable redis \
  \
  # Install Zip PHP extension.
  # Zip extension configuration changed on PHP 7.4
  # see https://www.php.net/manual/en/zip.installation.php
  && apk add libzip-dev \
  && docker-php-ext-install zip \
  \
  # Install XMLRPC PHP extension.
  # Install from Github (extension should be available on PECL but is not)
  && apk add libxml2-dev \
  && mkdir -p /tmp/xmlrpc \
  && (curl -LsfS https://github.com/php/pecl-networking-xmlrpc/archive/0f782ffe52cebd0a65356427b7ab72d48b72d20c/xmlrpc-0f782ff.tar.gz | tar xvz -C "/tmp/xmlrpc" --strip 1) \
  && docker-php-ext-configure /tmp/xmlrpc --with-xmlrpc \
  && docker-php-ext-install /tmp/xmlrpc \
  && rm -rf /tmp/xmlrpc \
  \
  # Install APCU PHP extension.
  && pecl install apcu \
  && docker-php-ext-enable apcu \
  && echo "apc.enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  && echo "apc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  \
  # Update PHP configuration.
  && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
  \
  # Disable sodium PHP extension (Test should validate that polyfill works).
  && rm /usr/local/etc/php/conf.d/docker-php-ext-sodium.ini \
  \
  # Install nodejs and npm.
  && apk add nodejs npm \
  \
  # Install git and zip used by composer when fetching dependencies.
  && apk add git unzip \
  \
  # Install gettext and perl used to validate locales extraction.
  && apk add gettext \
  && apk add perl \
  \
  # Install sudo that may be usefull to temporarly install upcoming required system components.
  && apk add sudo \
  && (echo "glpi  ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/glpi) \
  \
  # Install bash that is used in some GLPI scripts.
  && apk add bash \
  \
  # Install patch utility that may be usefull to patch dependencies.
  && apk add patch \
  \
  # Remove PHP build dependencies.
  && apk del -f .build-deps \
  \
  # Clean sources list.
  && rm -rf /var/cache/apk/*

# Copy composer binary
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Create application volume (used to share data across jobs),
# give its ownage to glpi user (1000:1000) and define it as base working dir
RUN addgroup -g 1000 glpi \
  && adduser -D -h /home/glpi -G glpi -u 1000 glpi \
  && mkdir -p /var/glpi \
  && chown glpi:glpi /var/glpi
USER glpi
VOLUME /home/glpi
VOLUME /var/glpi
WORKDIR /var/glpi
