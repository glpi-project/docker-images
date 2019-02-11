ARG BASE_IMAGE=circleci/php:latest-node
FROM $BASE_IMAGE

# Switch to root user for installation commands
USER root

RUN apt-get update \
  \
  # Install MySQL client.
  && apt-get install --assume-yes --no-install-recommends --quiet mysql-client \
  \
  # Install GD PHP extension.
  && apt-get install --assume-yes --no-install-recommends --quiet libfreetype6-dev libjpeg-dev libpng-dev \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install gd \
  \
  # Install mysqli PHP extension (required only for GLPI prior to 10.0).
  && docker-php-ext-install mysqli \
  \
  # Install PDO MySQL PHP extension.
  && docker-php-ext-install pdo pdo_mysql \
  \
  # Install XMLRPC PHP extension.
  && apt-get install --assume-yes --no-install-recommends --quiet libxml2-dev \
  && docker-php-ext-install xmlrpc \
  \
  # Install APCU PHP extension.
  # apcu-4.0.11 is the fallback version for PHP prior to 7.0
  && pecl install apcu || pecl install apcu-4.0.11 \
  && docker-php-ext-enable apcu \
  && echo "apc.enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  && echo "apc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  \
  # Update PHP configuration.
  && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
  \
  # Update composer to latest version.
  && composer self-update --no-interaction --no-progress \
  \
  # Clean sources list.
  && rm -rf /var/lib/apt/lists/*

# Switch back to circleci user
USER circleci
