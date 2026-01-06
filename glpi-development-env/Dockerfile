ARG BASE_IMAGE=php:apache-trixie


#####
# Fetch composer latest build
#####
FROM composer:latest AS composer

#####
# Build main image
#####
FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI development environment" \
  org.opencontainers.image.description="This container can be used to serve GLPI in a development environment." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

RUN apt update \
  && PHP_MAJOR_VERSION="$(echo $PHP_VERSION | cut -d '.' -f 1)" \
  && PHP_MINOR_VERSION="$(echo $PHP_VERSION | cut -d '.' -f 2)" \
  \
  # Install bz2 extension (for marketplace).
  && apt install --assume-yes --no-install-recommends --quiet libbz2-dev \
  && docker-php-ext-install bz2 \
  \
  # Install exif extension.
  && docker-php-ext-install exif \
  \
  # Install GD PHP extension.
  && apt install --assume-yes --no-install-recommends --quiet libfreetype6-dev libjpeg-dev libpng-dev libwebp-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
  && docker-php-ext-install gd \
  \
  # Install intl PHP extension.
  && apt install --assume-yes --no-install-recommends --quiet libicu-dev \
  && docker-php-ext-install intl \
  \
  # Install ldap PHP extension.
  && apt install --assume-yes --no-install-recommends --quiet libldap2-dev \
  && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
  && docker-php-ext-install ldap \
  \
  # Install memcached PHP extension.
  && apt install --assume-yes --no-install-recommends --quiet libmemcached-dev \
  && pecl install memcached \
  && docker-php-ext-enable memcached \
  \
  # Install mysqli PHP extension.
  && docker-php-ext-install mysqli \
  \
  # Install bcmath PHP extension.
  && docker-php-ext-install bcmath \
  \
  # Install opcache PHP extension (it is already enabled in PHP 8.5+ images).
  && if [ "$PHP_MINOR_VERSION" -ne "8.5" ]; then \
    docker-php-ext-install opcache \
  ; fi \
  \
  # Install pcntl PHP extension (required for composer-require-checker).
  && docker-php-ext-install pcntl \
  \
  # Install redis PHP extension.
  && pecl install redis \
  && docker-php-ext-enable redis \
  \
  # Install Zip PHP extension.
  && apt install --assume-yes --no-install-recommends --quiet libzip-dev \
  && docker-php-ext-install zip \
  \
  # Install xdebug PHP extension.
  && if [ "$PHP_MAJOR_VERSION" -lt "8" ]; then \
    pecl install xdebug-3.1.6 \
  ; else \
    # xdebug 3.5.0 is not available on PECL, its distribution is now made through PIE
    mkdir -p /tmp/xdebug \
    && (curl --fail --silent --show-error --location https://github.com/xdebug/xdebug/archive/refs/tags/3.5.0.tar.gz | tar --extract --ungzip --verbose --directory="/tmp/xdebug" --strip 1) \
    && docker-php-ext-install /tmp/xdebug \
    && rm -rf /tmp/xdebug \
  ; fi \
  && docker-php-ext-enable xdebug \
  \
  # Install XMLRPC PHP extension.
  && apt install --assume-yes --no-install-recommends --quiet libxml2-dev \
  && if [ "$PHP_MAJOR_VERSION" -lt "8" ]; then \
    # For PHP < 8.x, install bundled extension
    docker-php-ext-install xmlrpc \
  ; else \
    # For PHP 8+, install from Github (extension should be available on PECL but is not)
    mkdir -p /tmp/xmlrpc \
    && (curl --fail --silent --show-error --location https://github.com/php/pecl-networking-xmlrpc/archive/0f782ffe52cebd0a65356427b7ab72d48b72d20c/xmlrpc-0f782ff.tar.gz | tar --extract --ungzip --verbose --directory="/tmp/xmlrpc" --strip 1) \
    && docker-php-ext-configure /tmp/xmlrpc --with-xmlrpc \
    && docker-php-ext-install /tmp/xmlrpc \
    && rm -rf /tmp/xmlrpc \
  ; fi \
  \
  # Enable apache mods.
  && a2enmod rewrite \
  \
  # Install nodejs and npm.
  && apt install --assume-yes --no-install-recommends --quiet gnupg \
  && mkdir -p /etc/apt/keyrings \
  && curl --fail --silent --show-error --location https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor --output /etc/apt/keyrings/nodesource.gpg \
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
  && apt update \
  && apt install --assume-yes --no-install-recommends --quiet nodejs \
  \
  # Install git and zip used by composer when fetching dependencies.
  && apt install --assume-yes --no-install-recommends --quiet git unzip \
  \
  # Install gettext used for translation files.
  && apt install --assume-yes --no-install-recommends --quiet gettext \
  \
  # Install Cypress dependencies
  && apt install --assume-yes --no-install-recommends --quiet libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2 libxtst6 xauth xvfb \
  \
  # Install dependencies for plugin release tool
  && apt install --assume-yes --no-install-recommends --quiet gpg python3 python3-git python3-gitdb python3-github python3-lxml python3-termcolor \
  && ln -s /usr/bin/python3 /usr/bin/python \
  \
  # Install transifex client
  && (cd /usr/local/bin/ && curl --silent --location https://raw.githubusercontent.com/transifex/cli/master/install.sh | bash) \
  \
  # Install misc util packages commonly used by developers
  && apt install --assume-yes --no-install-recommends --quiet htop jq nano sudo vim zsh \
  \
  # Clean sources list
  && rm -rf /var/lib/apt/lists/*

# Copy composer binary
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Copy default PHP development configuration
RUN cp "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

# Copy files to container.
RUN mkdir /etc/apache2/vhosts
COPY ./files/etc/apache2/ports.conf /etc/apache2/ports.conf
COPY ./files/etc/apache2/vhosts/glpi-common.conf /etc/apache2/vhosts/glpi-common.conf
COPY ./files/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./files/etc/apache2/sites-available/glpi-10.x.conf /etc/apache2/sites-available/glpi-10.x.conf
COPY ./files/etc/php/conf.d/glpi.ini $PHP_INI_DIR/conf.d/glpi.ini

# Define GLPI environment variables
ENV \
  GLPI_ENVIRONMENT_TYPE=development \
  GLPI_URI=http://localhost:8080

USER www-data
WORKDIR /var/www/glpi
