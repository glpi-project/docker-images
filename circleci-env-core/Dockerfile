ARG BASE_IMAGE=circleci/php:latest-node
FROM $BASE_IMAGE

# Switch to root user for installation commands
USER root

RUN \
  # Clean APT sources list to prevent packages list update error:
  # E: Could not open file /var/lib/apt/lists/deb.debian.org_debian_dists_buster_main_binary-amd64_Packages.diff_Index - open (2: No such file or directory)
  rm -rf /var/lib/apt/lists/* \
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
  # GD extension configuration parameters changed on PHP 7.4
  # see https://www.php.net/manual/en/image.installation.php#image.installation
  && apt-get install --assume-yes --no-install-recommends --quiet libfreetype6-dev libjpeg-dev libpng-dev \
  && PHP_MAJOR_VERSION="$(echo $PHP_VERSION | cut -d '.' -f 1)" \
  && PHP_MINOR_VERSION="$(echo $PHP_VERSION | cut -d '.' -f 2)" \
  && if [ $PHP_MAJOR_VERSION -le "5" ] || ([ $PHP_MAJOR_VERSION -eq "7" ] && [ $PHP_MINOR_VERSION -le "3" ]); then \
    # For PHP <= 5.x or PHP 7 <= 7.3, use old parameters
    docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  ; else \
    docker-php-ext-configure gd --with-freetype --with-jpeg \
  ; fi \
  && docker-php-ext-install gd \
  \
  # Install mysqli PHP extension (required only for GLPI prior to 10.0).
  && docker-php-ext-install mysqli \
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

# Install gettext 0.21
RUN apt-get remove --assume-yes --no-install-recommends --quiet gettext \
  && curl https://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.gz --location --output /tmp/gettext.tar.gz \
  && mkdir /tmp/gettext \
  && tar --extract --ungzip --strip 1 --file /tmp/gettext.tar.gz --directory /tmp/gettext \
  && (cd /tmp/gettext/ && ./configure --prefix=/usr/local/gettext) \
  && (cd /tmp/gettext/ && make --quiet) \
  && (cd /tmp/gettext/ && make --quiet install) \
  && rm -rf /tmp/gettext.tar.gz /tmp/gettext
ENV PATH=/usr/local/gettext/bin:$PATH

# Copy files to container.
COPY ./files/etc/dovecot/local.conf /etc/dovecot/local.conf
COPY ./files/etc/dovecot/passwd /etc/dovecot/passwd

# Switch back to circleci user
USER circleci
