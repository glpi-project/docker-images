ARG BASE_IMAGE=php:fpm-trixie


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
    && (curl --fail --silent --show-error --location https://github.com/php/pecl-networking-xmlrpc/archive/0f782ffe52cebd0a65356427b7ab72d48b72d20c/xmlrpc-0f782ff.tar.gz | tar --extract --ungzip --verbose --directory="/tmp/xmlrpc" --strip 1) \
    && docker-php-ext-configure /tmp/xmlrpc --with-xmlrpc \
    && docker-php-ext-install /tmp/xmlrpc \
    && rm -rf /tmp/xmlrpc \
  ; fi \
  \
  # Install APCU PHP extension.
  && if [ "$PHP_IS_PRERELEASE" = true ]; then \
    # For PHP prereleases, install from the repository to get the latest commit
    mkdir -p /tmp/apcu \
    && (curl --fail --silent --show-error --location https://github.com/krakjoe/apcu/archive/refs/heads/master.tar.gz | tar --extract --ungzip --verbose --directory="/tmp/apcu" --strip 1) \
    && docker-php-ext-install /tmp/apcu \
    && rm -rf /tmp/apcu \
  ; elif [ "$PHP_MAJOR_VERSION" -ge "8" ] && [ "$PHP_MINOR_VERSION" -ge "1" ]; then \
    # For PHP >= 8.1, use PIE
    pie install apcu/apcu \
  ; else \
    # For PHP < 8.1, use PECL
    pecl install apcu \
  ; fi \
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
  # Clean sources list
  && rm -rf /var/lib/apt/lists/*

# Copy composer binary
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Create application volume (used to share data across jobs),
# give its ownage to glpi user (1000:1000) and define it as base working dir
RUN addgroup -gid 1000 glpi \
  && useradd -m -d /home/glpi -g glpi -u 1000 glpi \
  && mkdir -p /var/www/glpi \
  && chown glpi:glpi /var/www/glpi
USER glpi
VOLUME /home/glpi
VOLUME /var/www/glpi
WORKDIR /var/www/glpi

# Define GLPI environment variables
ENV \
  GLPI_ENVIRONMENT_TYPE=testing
