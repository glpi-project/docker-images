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
  org.opencontainers.image.title="GLPI Github Actions PHP container" \
  org.opencontainers.image.description="This container is used to run GLPI test suite on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

RUN \
     PHP_MAJOR_VERSION="$(echo $PHP_VERSION | cut -d '.' -f 1)" \
  && PHP_MINOR_VERSION="$(echo $PHP_VERSION | cut -d '.' -f 2)" \
  \
  # Update package list.
  && apt update \
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
  # Install Playwright dependencies
  && npx playwright install-deps \
  \
  # Install ldap utils used by plugin CI workflows.
  && apt install --assume-yes --no-install-recommends --quiet ldap-utils \
  \
  # Install acl and sudo that will be used to give correct rights in the Gihub Actions runner context.
  # sudo may also be usefull to temporarly install upcoming required system components.
  && apt install --assume-yes --no-install-recommends --quiet acl sudo \
  \
  # Install jq that is used for JSON files manipulations.
  && apt install --assume-yes --no-install-recommends --quiet jq \
  \
  # Clean sources list
  && rm -rf /var/lib/apt/lists/*

# Copy composer binary
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Copy files to container
RUN mkdir /etc/apache2/vhosts
COPY ./files/etc/apache2/ports.conf /etc/apache2/ports.conf
COPY ./files/etc/apache2/vhosts/glpi-common.conf /etc/apache2/vhosts/glpi-common.conf
COPY ./files/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf

RUN \
  # Workaround to make apache use same UID/GID as usual host user.
  # It permit to prevent rights issues when executing tests from the `tests/run_tests.sh` script.
  groupmod --gid 1000 www-data \
  && usermod --uid 1000 www-data \
  \
  # Allow executing commands as www-data with `sudo -l www-data`
  && usermod --shell /bin/bash www-data \
  \
  # Create home volume, to be able to share home data data across jobs.
  && mkdir --parents /home/www-data \
  && chown www-data:www-data /home/www-data \
  && usermod --home /home/www-data www-data \
  \
  # Create application volume.
  && mkdir --parents /var/www/glpi \
  && chown www-data:www-data /var/www/glpi

RUN \
  # Create a user with UID=1001 (the UID used by Github Actions runner) and add it to sudoers.
  # This is mandatory to bypass rights issues during checkout and to be able to then execute scripts as www-data user.
  useradd -m -d /home/github-actions-runner -g www-data -u 1001 github-actions-runner \
  && (echo "github-actions-runner ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/glpi)

VOLUME /home/www-data
VOLUME /var/www/glpi

USER www-data
WORKDIR /var/www/glpi

# Define GLPI environment variables
ENV \
  GLPI_ENVIRONMENT_TYPE=testing
