ARG BASE_IMAGE=circleci/php:latest-node
FROM $BASE_IMAGE

# Switch to root user for installation commands
USER root

RUN \
  # Clean APT sources list to prevent packages list update error:
  # E: Could not open file /var/lib/apt/lists/deb.debian.org_debian_dists_buster_main_binary-amd64_Packages.diff_Index - open (2: No such file or directory)
  rm -rf /var/lib/apt/lists/* \
  \
  && if [ "$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '\"')" = "buster" ]; then \
    # On Buster, install the old freetype6 version to make freetype-config script available
    # see https://github.com/docker-library/php/issues/865
    # TODO This may be removed if future PHP versions fixes this
    echo "\033[0;31m Fallback to old version of freetype6 \033[0m" \
    && echo "deb http://deb.debian.org/debian stretch main" >> /etc/apt/sources.list.d/stretch.list \
    && apt-get update && apt-get install --assume-yes --allow-downgrades --no-install-recommends --quiet libfreetype6-dev=2.6.3-3.2 libfreetype6=2.6.3-3.2 \
    && rm /etc/apt/sources.list.d/stretch.list \
  ; else \
    # On Stretch, install the available freetype6 version that contains freetype-config script
    apt-get update && apt-get install --assume-yes --no-install-recommends --quiet libfreetype6-dev \
  ; fi \
  \
  # Update APT sources list
  && apt-get update \
  \
  # Install MySQL client.
  && apt-get install --assume-yes --no-install-recommends --quiet default-mysql-client \
  \
  # Install mail server and getmail utility.
  && apt-get install --assume-yes --no-install-recommends --quiet dovecot-imapd dovecot-pop3d getmail4 \
  && maildirmake.dovecot /home/circleci/Maildir circleci \
  \
  # Install exif extension.
  && docker-php-ext-install exif \
  \
  # Install GD PHP extension.
  && apt-get install --assume-yes --no-install-recommends --quiet libjpeg-dev libpng-dev \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install gd \
  \
  # Install imap PHP extension.
  && apt-get install --assume-yes --no-install-recommends --quiet libc-client-dev libkrb5-dev \
  && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
  && docker-php-ext-install imap \
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
  && (pecl install apcu || pecl install apcu-4.0.11) \
  && docker-php-ext-enable apcu \
  && echo "apc.enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  && echo "apc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  \
  # Update PHP configuration.
  && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
  \
  # Disable xdebug PHP extension.
  && rm /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
  \
  # Update composer to latest version.
  && composer self-update --no-interaction --no-progress \
  \
  # Clean sources list.
  && rm -rf /var/lib/apt/lists/*

# Copy files to container.
COPY ./files /

# Switch back to circleci user
USER circleci
