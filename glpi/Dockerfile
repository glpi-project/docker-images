
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
  # Install intl PHP extension required to execute the GLPI console.
  && apk add icu-dev \
  && docker-php-ext-configure intl \
  && docker-php-ext-install intl \
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

ARG GLPI_MARKETPLACE_DIR=/var/glpi/marketplace

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
  # Install Redis PHP extension.
  && pecl install redis \
  && docker-php-ext-enable redis \
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
  # install mysql client
  && apt-get install --assume-yes --no-install-recommends --quiet default-mysql-client \
  \
  # Clean sources list.
  && rm -rf /var/lib/apt/lists/*

# Use the default production configuration
# ref: https://github.com/docker-library/docs/tree/master/php#configuration
RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini

# Copy services configuration files and startup script to container.
COPY ./files/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./files/etc/apache2/conf-available/zzz-glpi.conf /etc/apache2/conf-available/zzz-glpi.conf
COPY ./files/etc/cron.d/glpi /etc/cron.d/glpi
COPY ./files/opt/glpi/ /opt/glpi/
RUN find /opt/glpi -type f -iname "*.sh" -exec chmod u+x {} \;

# Enable custom Apache configuration
RUN a2enconf zzz-glpi.conf

# Install GLPI crontab.
RUN crontab -u root /etc/cron.d/glpi

# Copy GLPI application.
COPY --from=builder --chown=www-data:www-data /usr/src/glpi /var/www/glpi

# Declare a volume for "config", "marketplace" and "files" directory
RUN mkdir /var/glpi && chown www-data:www-data /var/glpi
VOLUME /var/glpi

# Define GLPI environment variables
ENV \
  GLPI_INSTALL_MODE=DOCKER \
  GLPI_CONFIG_DIR=/var/glpi/config \
  GLPI_MARKETPLACE_DIR=${GLPI_MARKETPLACE_DIR} \
  GLPI_VAR_DIR=/var/glpi/files \
  GLPI_LOG_DIR=/var/glpi/logs \
  GLPI_SKIP_AUTOINSTALL=false \
  GLPI_SKIP_AUTOUPDATE=false \
  GLPI_USE_REDIS_SESSION=false \
  GLPI_REDIS_SESSION_HOST=redis:6379

# PHP configuration environment variables
ENV \
  PHP_SESSION_COOKIE_HTTPONLY=on \
  PHP_SESSION_COOKIE_SAMESITE=Strict \
  PHP_EXPOSE_PHP=off \
  PHP_POST_MAX_SIZE=20M \
  PHP_UPLOAD_MAX_FILESIZE=20M \
  PHP_MEMORY_LIMIT=256M \
  PHP_MAX_INPUT_VARS=5000 \
  PHP_MAX_EXECUTION_TIME=60 \
  PHP_OPCACHE_VALIDATE_TIMESTAMPS=1 \
  PHP_OPCACHE_MAX_ACCELERATED_FILES=10000 \
  PHP_OPCACHE_MEMORY_CONSUMPTION=128 \
  PHP_OPCACHE_MAX_WASTED_PERCENTAGE=5

# Copy the env variables to `/etc/environment`, to make them available for the commands executed by the cron service
RUN printenv > /etc/environment

# Define entrypoint and default command.
ENTRYPOINT ["/opt/glpi/entrypoint.sh"]
CMD ["/opt/glpi/startup.sh"]

# Define application path as base working dir.
WORKDIR /var/www/glpi
