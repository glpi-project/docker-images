FROM composer:latest AS composer
FROM php:8.1.4-apache

# Workaround to make apache use same UID/GID as host user.
ARG HOST_GROUP_ID=1000
RUN groupmod --gid ${HOST_GROUP_ID} www-data
ARG HOST_USER_ID=1000
RUN usermod --uid ${HOST_USER_ID} www-data

# Make www-data user home persistent for cache purpose.
RUN mkdir --parents /home/www-data \
  && chown www-data:www-data /home/www-data \
  && usermod --home /home/www-data www-data
VOLUME /home/www-data

RUN apt-get update \
  \
  # Install bz2 extension (for marketplace).
  && apt-get install --assume-yes --no-install-recommends --quiet libbz2-dev \
  && docker-php-ext-install bz2 \
  \
  # Install exif extension.
  && docker-php-ext-install exif \
  \
  # Install gd PHP extension.
  # GD extension configuration parameters changed on PHP 7.4
  # see https://www.php.net/manual/en/image.installation.php#image.installation
  && apt-get install --assume-yes --no-install-recommends --quiet libfreetype6-dev libjpeg-dev libpng-dev \
  && docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install gd \
  \
  # Install intl PHP extension.
  && apt-get install --assume-yes --no-install-recommends --quiet libicu-dev \
  && docker-php-ext-configure intl \
  && docker-php-ext-install intl \
  \
  # Install ldap PHP extension.
  && apt-get install --assume-yes --no-install-recommends --quiet libldap2-dev \
  && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
  && docker-php-ext-install ldap \
  \
  # Install memcached PHP extension.
  && apt-get install --assume-yes --no-install-recommends --quiet libmemcached-dev \
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
  # Install soap PHP extension (required for some plugins).
  && apt-get install --assume-yes --no-install-recommends --quiet libxml2-dev \
  && docker-php-ext-install soap \
  \
  # Install XMLRPC PHP extension.
  # For PHP 8+, install from Github (extension should be available on PECL but is not)
  && apt-get install --assume-yes --no-install-recommends --quiet libxml2-dev \
  && mkdir -p /tmp/xmlrpc \
    && curl -LsfS https://github.com/php/pecl-networking-xmlrpc/archive/0f782ffe52cebd0a65356427b7ab72d48b72d20c/xmlrpc-0f782ff.tar.gz | tar xvz -C "/tmp/xmlrpc" --strip 1 \
    && docker-php-ext-configure /tmp/xmlrpc --with-xmlrpc \
    && docker-php-ext-install /tmp/xmlrpc \
    && rm -rf /tmp/xmlrpc \
  \
  # Install zip PHP extension (for marketplace).
  # Zip extension configuration parameters changed on PHP 7.3
  # see https://www.php.net/manual/en/zip.installation.php#zip.installation
  && apt-get install --assume-yes --no-install-recommends --quiet libzip-dev zip \
  && docker-php-ext-install zip \
  \
  # Enable apache mods.
  && a2enmod rewrite \
  \
  # Install cron service.
  && apt-get install --assume-yes --no-install-recommends --quiet cron \
  \
  # Install nodejs and npm.
  && apt-get install --assume-yes --no-install-recommends --quiet gnupg \
  && curl --silent --location https://deb.nodesource.com/setup_16.x | bash - \
  && apt-get install --assume-yes --no-install-recommends --quiet nodejs \
  \
  # Install git and zip used by composer when fetching dependencies.
  && apt-get install --assume-yes --no-install-recommends --quiet git unzip \
  \
  # Install gettext used for translation files.
  && apt-get install --assume-yes --no-install-recommends --quiet gettext \
  \
  # Clean sources list
  && rm -rf /var/lib/apt/lists/*

# Copy composer binary
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Copy files to container.
COPY ./files/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./files/etc/cron.d/glpi /etc/cron.d/glpi
COPY ./files/opt/startup.sh /opt/startup.sh
COPY ./files/opt/download_glpi.sh /opt/download_glpi.sh
COPY ./files/opt/install_glpi.sh /opt/install_glpi.sh

# Install GLPI crontab.
RUN crontab -u www-data /etc/cron.d/glpi

WORKDIR /var/www/glpi

# Download GLPI Files
ARG GLPI_RELEASE
RUN chmod u+x /opt/download_glpi.sh
RUN /opt/download_glpi.sh ${GLPI_RELEASE}

# Make startup script executable and executes it as default command.
RUN chmod u+x /opt/startup.sh
CMD /opt/startup.sh