ARG BASE_IMAGE=php:fpm-alpine


#####
# Fetch composer latest build
#####
FROM composer:latest AS composer


#####
# Build main image
#####
FROM $BASE_IMAGE

RUN \
  # Install PHP build dependencies.
  apk add --update --virtual .build-deps $PHPIZE_DEPS \
  \
  # Install exif extension.
  && docker-php-ext-install exif \
  \
  # Install GD PHP extension.
  && apk add --update freetype-dev libjpeg-turbo-dev libpng-dev \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install gd \
  \
  # Install intl PHP extension.
  && apk add --update icu-dev \
  && docker-php-ext-install intl \
  \
  # Install ldap PHP extension.
  && apk add --update --virtual .ldap-build-deps openldap-dev \
  && apk add --update libldap \
  && docker-php-ext-install ldap \
  && apk del -f .ldap-build-deps \
  \
  # Install mysqli PHP extension.
  && docker-php-ext-install mysqli \
  \
  # Install XMLRPC PHP extension.
  && apk add --update libxml2-dev \
  && docker-php-ext-install xmlrpc \
  \
  # Install APCU PHP extension.
  # pecl is not installed on phpdaily/php:8.0.0-dev-fpm-alpine image
  && (pecl version || (wget http://pear.php.net/go-pear.phar && php go-pear.phar)) \
  # apcu-4.0.11 is the fallback version for PHP prior to 7.0
  && (pecl install apcu || pecl install apcu-4.0.11) \
  && docker-php-ext-enable apcu \
  && echo "apc.enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  && echo "apc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  \
  # Update PHP configuration.
  && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
  \
  # Install nodejs and npm.
  # On alpine 3.7 (for PHP 7.0 and lower), npm is named nodejs-npm.
  && (apk add --update nodejs npm || apk add --update nodejs nodejs-npm) \
  \
  # Install git and zip used by composer when fetching dependencies.
  && apk add --update git unzip \
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
VOLUME /var/glpi
WORKDIR /var/glpi

# Define composer environment variables
ENV \
  COMPOSER_HOME=/home/glpi/composer \
  PATH=/home/glpi/composer/vendor/bin:$PATH

# Install hirak/prestissimo composer plugin to speedup dependencies installation
RUN \
  composer global require hirak/prestissimo \
  && composer clear-cache
