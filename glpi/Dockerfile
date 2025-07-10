
ARG BUILDER_IMAGE=php:cli-alpine
ARG APP_IMAGE=php:apache

#####
# Builder image
#####
FROM $BUILDER_IMAGE AS builder

# Copy composer binary from latest composer image.
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install required system packages.
RUN \
  # Update APK package list.
  apk update \
  \
  # Install bash that is used in for build script.
  && apk add bash \
  \
  # Install patch utility that may be usefull to patch dependencies.
  && apk add patch \
  \
  # Install gettext and perl required to compile locales.
  && apk add gettext perl \
  \
  # Install nodejs and npm.
  && apk add nodejs npm \
  \
  # Install git and zip used by composer when fetching dependencies.
  && apk add git unzip \
  \
  # Clean sources list.
  && rm -rf /var/cache/apk/*

 # Update PHP configuration.
RUN echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini

# Copy GLPI source.
COPY --chown=www-data:www-data ./sources /usr/src/glpi

# Build GLPI app
USER www-data
RUN /usr/src/glpi/tools/build_glpi.sh


#####
# Application image
#####
FROM $APP_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI nightly build" \
  org.opencontainers.image.description="This container contains Apache/PHP and a nightly build of GLPI. \
It can be used to test latest features and bug fixes." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

RUN apt-get update \
  \
  # Install APCU PHP extension.
  && pecl install apcu \
  && docker-php-ext-enable apcu \
  && echo "apc.enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  \
  # Install bz2 PHP extension.
  && apt-get install --assume-yes --no-install-recommends --quiet libbz2-dev \
  && docker-php-ext-install bz2 \
  \
  # Install exif extension.
  && docker-php-ext-install exif \
  \
  # Install gd PHP extension.
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
  # Install mysqli PHP extension.
  && docker-php-ext-install mysqli \
  \
  # Install bcmath PHP extension.
  && docker-php-ext-install bcmath \
  \
  # Install opcache PHP extension.
  && docker-php-ext-install opcache \
  \
  # Install soap PHP extension (required for some plugins).
  && apt-get install --assume-yes --no-install-recommends --quiet libxml2-dev \
  && docker-php-ext-install soap \
  \
  # Install zip PHP extension.
  && apt-get install --assume-yes --no-install-recommends --quiet libzip-dev \
  && docker-php-ext-configure zip \
  && docker-php-ext-install zip \
  \
  # Enable apache mods.
  && a2enmod rewrite \
  \
  # Install cron service.
  && apt-get install --assume-yes --no-install-recommends --quiet cron \
  \
  # Install acl to manage acl of writable directories.
  && apt-get install --assume-yes --no-install-recommends --quiet acl \
  \
  # Clean sources list.
  && rm -rf /var/lib/apt/lists/*

# Use the default production configuration
# ref: https://github.com/docker-library/docs/tree/master/php#configuration
RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini

# Copy services configuration files and startup script to container.
COPY ./files/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./tc/apache2/conf-available/zzz-glpi.conf /etc/apache2/conf-available/zzz-glpi.conf
COPY ./files/etc/cron.d/glpi /etc/cron.d/glpi
COPY ./files/etc/php/conf.d/glpi.ini $PHP_INI_DIR/conf.d/glpi.ini
COPY ./files/opt/startup.sh /opt/startup.sh

# Enable custom Apache configuration
RUN a2enconf zzz-glpi.conf

# Install GLPI crontab.
RUN crontab -u www-data /etc/cron.d/glpi

# Copy GLPI application.
COPY --from=builder --chown=www-data:www-data /usr/src/glpi /var/www/glpi

# Declare a volume for "config", "marketplace" and "files" directory
RUN mkdir /var/glpi && chown www-data:www-data /var/glpi
VOLUME /var/glpi

# Define GLPI environment variables
ENV \
  GLPI_INSTALL_MODE=DOCKER \
  GLPI_CONFIG_DIR=/var/glpi/config  \
  GLPI_MARKETPLACE_DIR=/var/glpi/marketplace \
  GLPI_VAR_DIR=/var/glpi/files \
  GLPI_LOG_DIR=/var/glpi/logs

# Make startup script executable and executes it as default command.
RUN chmod u+x /opt/startup.sh
CMD /opt/startup.sh

# Define application path as base working dir.
WORKDIR /var/www/glpi
