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

RUN --mount=type=bind,from=ghcr.io/php/pie:bin,source=/pie,target=/usr/local/bin/pie \
     PHP_MAJOR_VERSION="$(echo $PHP_VERSION | cut -d '.' -f 1)" \
  && PHP_MINOR_VERSION="$(echo $PHP_VERSION | cut -d '.' -f 2)" \
  && if [ ! -z "$(echo $PHP_VERSION | cut -d "." -f 3 | grep -P '(alpha|beta|rc)')" ]; then PHP_IS_PRERELEASE=true; else PHP_IS_PRERELEASE=false; fi \
  \
  # Update package list.
  && apt update \
  \
  # Install git and unzip used by PIE/composer when fetching dependencies.
  && apt install --assume-yes --no-install-recommends --quiet git unzip \
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
  # Install mbstring PHP extension (not installed by default since PHP 8.6).
  && apt install --assume-yes --no-install-recommends --quiet libonig-dev \
  && docker-php-ext-install mbstring \
  \
  # Install memcached PHP extension.
  && apt install --assume-yes --no-install-recommends --quiet libmemcached-dev \
  && if [ "$PHP_IS_PRERELEASE" = true ]; then \
    # For PHP prereleases, install from the repository to get the latest commit
    mkdir -p /tmp/memcached \
    && (curl --fail --silent --show-error --location https://github.com/php-memcached-dev/php-memcached/archive/refs/heads/master.tar.gz | tar --extract --ungzip --verbose --directory="/tmp/memcached" --strip 1) \
    && docker-php-ext-install /tmp/memcached \
    && rm -rf /tmp/memcached \
  ; elif [ "$PHP_MAJOR_VERSION" -ge "8" ] && [ "$PHP_MINOR_VERSION" -ge "1" ]; then \
    # For PHP >= 8.1, use PIE
    pie install php-memcached/php-memcached \
  ; else \
    # For PHP < 8.1, use PECL
    pecl install memcached \
  ; fi \
  && docker-php-ext-enable memcached \
  \
  # Install mysqli PHP extension.
  && docker-php-ext-install mysqli \
  \
  # Install bcmath PHP extension.
  && docker-php-ext-install bcmath \
  \
  # Install opcache PHP extension (it is already enabled in PHP 8.5+ images).
  && if [ "$(echo $PHP_VERSION | cut -d '.' -f 1,2)" != "8.5" ] && [ "$(echo $PHP_VERSION | cut -d '.' -f 1,2)" != "8.6" ]; then \
    docker-php-ext-install opcache \
  ; fi \
  \
  # Install pcntl PHP extension (required for composer-require-checker).
  && docker-php-ext-install pcntl \
  \
  # Install redis PHP extension.
  && if [ "$PHP_IS_PRERELEASE" = true ]; then \
    # For PHP prereleases, install from the repository to get the latest commit
    mkdir -p /tmp/redis \
    && (curl --fail --silent --show-error --location https://github.com/phpredis/phpredis/archive/refs/heads/develop.tar.gz | tar --extract --ungzip --verbose --directory="/tmp/redis" --strip 1) \
    && docker-php-ext-install /tmp/redis \
    && rm -rf /tmp/redis \
  ; elif [ "$PHP_MAJOR_VERSION" -ge "8" ] && [ "$PHP_MINOR_VERSION" -ge "1" ]; then \
    # For PHP >= 8.1, use PIE
    pie install phpredis/phpredis \
  ; else \
    # For PHP < 8.1, use PECL
    pecl install redis \
  ; fi \
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
    && (curl --fail --silent --show-error --location https://github.com/xdebug/xdebug/archive/6e86e8602ddacf3f7473c3bd14c0c8b57d64c10c.tar.gz | tar --extract --ungzip --verbose --directory="/tmp/xdebug" --strip 1) \
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
  ; elif [ "$(echo $PHP_VERSION | cut -d '.' -f 1,2)" != "8.6" ]; then \
    # For PHP 8+, install from Github (extension should be available on PECL but is not)
    #
    # PHP 8.6 is not supported by GLPI 10, the last GLPI version using this extension.
    # Therefore, no need to install this extension for PHP 8.6.
    mkdir -p /tmp/xmlrpc \
    && (curl --fail --silent --show-error --location https://github.com/php/pecl-networking-xmlrpc/archive/ea3c8b6a902a1b24f543aef035edb594211a05b3.tar.gz | tar --extract --ungzip --verbose --directory="/tmp/xmlrpc" --strip 1) \
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
  && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
  && apt update \
  && apt install --assume-yes --no-install-recommends --quiet nodejs \
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
  # Install libcap2-bin for setcap
  && apt install --assume-yes --no-install-recommends --quiet libcap2-bin \
  \
  # Clean sources list
  && rm -rf /var/lib/apt/lists/*

# Allow apache process to bind to port 80 as non-root user
RUN setcap cap_net_bind_service=+ep /usr/sbin/apache2

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
