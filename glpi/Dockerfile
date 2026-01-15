# GLPI Docker Image
#
# Build Arguments:
#   BUILDER_IMAGE          - PHP CLI image for building (default: php:cli-alpine)
#   APP_IMAGE              - PHP Apache image for runtime (default: php:apache)
#   GLPI_VERSION           - Version to build: "latest" (default), tag (10.0.18), branch (main), commit, or URL
#   GLPI_CACHE_KEY         - Cache-busting key for CI workflows (internal use)
#   GLPI_PATCH_URL         - Space-separated URLs to .diff/.patch files to apply
#   GLPI_MARKETPLACE_DIR   - Marketplace directory path (default: /var/glpi/marketplace)
#                            Use /var/www/glpi/marketplace for v10.x builds

ARG BUILDER_IMAGE=php:cli-alpine
ARG APP_IMAGE=php:apache

#####
# Downloader image - Resolve version and download source
#####
FROM alpine AS downloader

# GLPI_VERSION can be:
# - "latest" (default): resolves to latest stable release
# - A tag version: e.g., "10.0.18", "11.0.0"
# - A branch name: e.g., "11.0/bugfixes", "main"
# - A commit hash: e.g., "2186bc6bd410d8bcb048637b3c0fb86b7e320c0a"
# - A direct URL: e.g., "https://github.com/glpi-project/glpi/archive/2186bc6.tar.gz"
ARG GLPI_VERSION=latest
# Cache-busting key for glpi workflows
ARG GLPI_CACHE_KEY=""

RUN apk add --no-cache curl jq

# Resolve version and download source
RUN set -ex; \
    INPUT="${GLPI_VERSION}"; \
    # If input starts with https://, use it as-is \
    if echo "$INPUT" | grep --quiet '^https://'; then \
      URL="$INPUT"; \
    else \
      VERSION="$INPUT"; \
      # If "latest", resolve from GitHub API \
      if [ "$VERSION" = "latest" ]; then \
        VERSION=$(curl --silent https://api.github.com/repos/glpi-project/glpi/releases/latest | jq --raw-output .tag_name); \
      fi; \
      # Use GitHub's generic archive format (works for branches, tags, and commits)
      URL="https://github.com/glpi-project/glpi/archive/${VERSION}.tar.gz"; \
    fi; \
    echo "Downloading GLPI from $URL"; \
    curl --location "$URL" --output /glpi.tar.gz

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
  # Install git, zip, and curl used by composer.
  && apk add git unzip curl \
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

# Copy tarball from downloader and extract (preserves permissions from archive)
COPY --from=downloader /glpi.tar.gz /tmp/glpi.tar.gz
RUN mkdir --parents /usr/src/glpi \
    && tar --extract --gzip --file=/tmp/glpi.tar.gz --strip-components=1 --directory=/usr/src/glpi \
    && rm /tmp/glpi.tar.gz \
    && chown --recursive www-data:www-data /usr/src/glpi

# Optional patch URL to apply after download
ARG GLPI_PATCH_URL=""
# Apply optional patches if GLPI_PATCH_URL is provided (space-separated URLs)
RUN set -ex; \
    if [ -n "${GLPI_PATCH_URL}" ]; then \
      cd /usr/src/glpi && \
      for PATCH in ${GLPI_PATCH_URL}; do \
        echo "Applying patch from ${PATCH}"; \
        curl --location "${PATCH}" | patch --strip=1; \
      done; \
    fi

# Build GLPI app
USER www-data
RUN /usr/src/glpi/tools/build_glpi.sh


#####
# Application image
#####
FROM $APP_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI build" \
  org.opencontainers.image.description="This container contains Apache/PHP and a build of GLPI." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

RUN apt-get update \
  && PHP_MAJOR_VERSION="$(echo $PHP_VERSION | cut --delimiter='.' --fields=1)" \
  && PHP_MINOR_VERSION="$(echo $PHP_VERSION | cut --delimiter='.' --fields=2)" \
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
  # Install opcache PHP extension (it is already enabled in PHP 8.5+ images).
  && if [ "$PHP_MINOR_VERSION" -ne "8.5" ]; then \
    docker-php-ext-install opcache \
  ; fi \
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
  # Install supervisor service.
  && apt-get install --assume-yes --no-install-recommends --quiet supervisor \
  \
  # Install libcap2-bin for setcap
  && apt-get install --assume-yes --no-install-recommends --quiet libcap2-bin \
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
RUN ln --symbolic $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini

# Allow apache process to bind to port 80 as non-root user
RUN setcap cap_net_bind_service=+ep /usr/sbin/apache2

# Copy services configuration files and startup script to container.
COPY ./files/etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
COPY ./files/etc/apache2/conf-available/zzz-glpi.conf /etc/apache2/conf-available/zzz-glpi.conf
COPY ./files/etc/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY ./files/etc/php/conf.d/glpi.ini $PHP_INI_DIR/conf.d/glpi.ini
COPY ./files/opt/glpi/ /opt/glpi/
RUN find /opt/glpi -type f -iname "*.sh" -exec chmod +x {} \;

# Enable custom Apache configuration
RUN a2enconf zzz-glpi.conf

# Copy GLPI application.
COPY --from=builder --chown=www-data:www-data /usr/src/glpi /var/www/glpi

# Declare a volume for "config", "marketplace" and "files" directory
RUN mkdir /var/glpi && chown www-data:www-data /var/glpi
VOLUME /var/glpi

# Marketplace directory configuration
# v10.x uses /var/www/glpi/marketplace (legacy), v11+ uses /var/glpi/marketplace
ARG GLPI_MARKETPLACE_DIR=/var/glpi/marketplace

# Define GLPI environment variables
ENV \
  GLPI_INSTALL_MODE=DOCKER \
  GLPI_CONFIG_DIR=/var/glpi/config \
  GLPI_MARKETPLACE_DIR=${GLPI_MARKETPLACE_DIR} \
  GLPI_VAR_DIR=/var/glpi/files \
  GLPI_LOG_DIR=/var/glpi/logs \
  GLPI_SKIP_AUTOINSTALL=false \
  GLPI_SKIP_AUTOUPDATE=false

# Pass the execution to the www-data user
USER www-data

# Define entrypoint and default command.
ENTRYPOINT ["/opt/glpi/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Define application path as base working dir.
WORKDIR /var/www/glpi
