ARG BASE_IMAGE=php:fpm-alpine


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
  # Install PHP build dependencies.
  apk add --update --virtual .build-deps $PHPIZE_DEPS \
  \
  # Install exif extension.
  && docker-php-ext-install exif \
  \
  # Install GD PHP extension.
  # GD extension configuration parameters changed on PHP 7.4
  # see https://www.php.net/manual/en/image.installation.php#image.installation
  && apk add --update freetype-dev libjpeg-turbo-dev libpng-dev \
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
  # Install intl PHP extension.
  && apk add --update icu-dev \
  && docker-php-ext-install intl \
  \
  # Install ldap PHP extension.
  && apk add --update --virtual .ldap-build-deps openldap-dev \
  && apk add --update libldap \
  && docker-php-ext-install ldap \
  && apk del -f .ldap-build-deps \
  \
  # Install mysqli PHP extension.
  && docker-php-ext-install mysqli \
  \
  # Install pcntl PHP extension (required for composer-require-checker).
  && docker-php-ext-install pcntl \
  \
  # Install XMLRPC PHP extension.
  && if [ $PHP_MAJOR_VERSION -lt "8" ]; then \
    # For PHP < 8.x, install bundled extension
    apk add --update libxml2-dev \
    && docker-php-ext-install xmlrpc \
  #; else \
    # For PHP 8+, install from PECL archive (pecl util is not available)
    # uncomment when a release will be available
    # mkdir -p /usr/src/php/ext/xmlrpc \
    # && curl -LsfS https://pecl.php.net/get/xmlrpc | tar xvz -C "/usr/src/php/ext/xmlrpc" --strip 1 \
    # && docker-php-ext-enable xmlrpc \
  ; fi \
  \
  # Install APCU PHP extension.
  && if [ $PHP_MAJOR_VERSION -eq "5" ]; then \
    # For PHP 5.x, install apcu 4.0.x using PECL util
    pecl install apcu-4.0.11 \
    && docker-php-ext-enable apcu \
  ; elif [ $PHP_MAJOR_VERSION -eq "7" ]; then \
    # For PHP 7.x, install latest apcu version using PECL util
    pecl install apcu \
    && docker-php-ext-enable apcu \
  ; else \
    # For PHP 8+, install from PECL archive (pecl util is not available)
    mkdir -p /usr/src/php/ext/apcu \
    && curl -LsfS https://pecl.php.net/get/apcu | tar xvz -C "/usr/src/php/ext/apcu" --strip-components 1 \
    && docker-php-ext-install apcu \
  ; fi \
  && echo "apc.enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  && echo "apc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  \
  # Use 'gnu-libiconv' to fix "iconv(): Wrong charset, conversion from `us-ascii' to `UTF-8//TRANSLIT' is not allowed".
  # Use 'edge' repository as this package is not available on Alpine 3.8 (used for PHP 5.6 and 7.0).
  && apk add --repository http://dl-cdn.alpinelinux.org/alpine/edge/community/ gnu-libiconv \
  \
  # Update PHP configuration.
  && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
  \
  # Install nodejs and npm.
  # On alpine 3.7 (for PHP 7.0 and lower), npm is named nodejs-npm.
  && (apk add --update nodejs npm || apk add --update nodejs nodejs-npm) \
  \
  # Install git and zip used by composer when fetching dependencies.
  && apk add --update git unzip \
  \
  # Install bash that is used in some GLPI scripts.
  && apk add --update bash \
  \
  # Remove PHP build dependencies.
  && apk del -f .build-deps \
  \
  # Clean sources list.
  && rm -rf /var/cache/apk/*

# Install gettext 0.21
RUN apk add --update build-base \
  && curl https://ftp.gnu.org/pub/gnu/gettext/gettext-0.21.tar.gz --location --output /tmp/gettext.tar.gz \
  && mkdir /tmp/gettext \
  && tar --extract --ungzip --strip 1 --file /tmp/gettext.tar.gz --directory /tmp/gettext \
  && (cd /tmp/gettext/ && ./configure --prefix=/usr/local/gettext) \
  && (cd /tmp/gettext/ && make --quiet) \
  && (cd /tmp/gettext/ && make --quiet install) \
  && rm -rf /tmp/gettext.tar.gz /tmp/gettext \
  && apk del -f build-base
ENV PATH=/usr/local/gettext/bin:$PATH

# Copy composer binary
COPY --from=composer /usr/bin/composer /usr/bin/composer

# Create application volume (used to share data across jobs),
# give its ownage to glpi user (1000:1000) and define it as base working dir
RUN addgroup -g 1000 glpi \
  && adduser -D -h /home/glpi -G glpi -u 1000 glpi \
  && mkdir -p /var/glpi \
  && chown glpi:glpi /var/glpi
USER glpi
VOLUME /home/glpi
VOLUME /var/glpi
WORKDIR /var/glpi

ENV \
  # #Fix "iconv(): Wrong charset, conversion from `us-ascii' to `UTF-8//TRANSLIT' is not allowed".
  LD_PRELOAD="/usr/lib/preloadable_libiconv.so php-fpm7 php"
