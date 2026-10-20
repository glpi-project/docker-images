#!/usr/bin/env bash
#
# Install PHP extensions in an official `php` Docker image (Debian based).
#
# Usage: install-php-extensions.sh <extension> [<extension> ...]
#
# Extensions installed through PIE (apcu, memcached, redis, pcov, xdebug) require the `pie` binary to be available,
# e.g. by mounting it in the calling RUN instruction:
#   --mount=type=bind,from=ghcr.io/php/pie:bin,source=/pie,target=/usr/local/bin/pie
#
# Environment variables:
#   APCU_ENABLE_CLI  set to 0 to keep APCu disabled for the CLI (default: 1)
#
# The apt lists are not cleaned by this script, the caller is responsible for it.

set -euo pipefail

PHP_MAJOR_MINOR="$(echo "$PHP_VERSION" | cut --delimiter='.' --fields=1,2)"
if echo "$PHP_VERSION" | cut --delimiter='.' --fields=3 | grep --ignore-case --quiet --perl-regexp '(alpha|beta|rc)'; then
  PHP_IS_PRERELEASE=true
else
  PHP_IS_PRERELEASE=false
fi

apt_install() {
  apt-get install --assume-yes --no-install-recommends --quiet "$@"
}

# Install an extension distributed through PIE.
# For PHP prereleases, the extension is built from the given repository archive to get the latest commit.
#   $1: PIE package name
#   $2: extension name
#   $3: archive URL used for PHP prereleases
install_pie_extension() {
  local package="$1" name="$2" prerelease_url="$3"
  if [ "$PHP_IS_PRERELEASE" = true ]; then
    local dir="/tmp/$name"
    mkdir --parents "$dir"
    curl --fail --silent --show-error --location "$prerelease_url" \
      | tar --extract --gzip --directory="$dir" --strip-components=1
    docker-php-ext-install "$dir"
    rm --recursive --force "$dir"
  else
    pie install "$package"
  fi
  docker-php-ext-enable "$name"
}

apt-get update
# unzip is used by PIE to extract the extension sources.
apt_install unzip

for extension in "$@"; do
  echo "### Installing PHP extension: $extension"
  case "$extension" in
    apcu)
      install_pie_extension apcu/apcu apcu https://github.com/krakjoe/apcu/archive/refs/heads/master.tar.gz
      {
        echo "apc.enable=1"
        echo "apc.enable_cli=${APCU_ENABLE_CLI:-1}"
      } >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini
      ;;
    bcmath | exif | mysqli | pcntl)
      docker-php-ext-install "$extension"
      ;;
    bz2)
      apt_install libbz2-dev
      docker-php-ext-install bz2
      ;;
    gd)
      apt_install libfreetype6-dev libjpeg-dev libpng-dev libwebp-dev
      docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
      docker-php-ext-install gd
      ;;
    intl)
      apt_install libicu-dev
      docker-php-ext-install intl
      ;;
    ldap)
      apt_install libldap2-dev
      docker-php-ext-configure ldap --with-libdir="lib/$(dpkg-architecture --query DEB_HOST_MULTIARCH)/"
      docker-php-ext-install ldap
      ;;
    mbstring)
      # Not installed by default since PHP 8.6.
      apt_install libonig-dev
      docker-php-ext-install mbstring
      ;;
    memcached)
      apt_install libmemcached-dev
      install_pie_extension php-memcached/php-memcached memcached \
        https://github.com/php-memcached-dev/php-memcached/archive/refs/heads/master.tar.gz
      ;;
    opcache)
      # Already enabled in PHP 8.5+ images.
      if ! php -m | grep --quiet 'Zend OPcache'; then
        docker-php-ext-install opcache
      fi
      ;;
    pcov)
      # Disabled by default, enabled via the PCOV_ENABLED env var.
      install_pie_extension pecl/pcov pcov https://github.com/krakjoe/pcov/archive/refs/heads/develop.tar.gz
      echo "pcov.enabled=0" >> /usr/local/etc/php/conf.d/docker-php-ext-pcov.ini
      ;;
    redis)
      install_pie_extension phpredis/phpredis redis https://github.com/phpredis/phpredis/archive/refs/heads/develop.tar.gz
      ;;
    soap)
      apt_install libxml2-dev
      docker-php-ext-install soap
      ;;
    xdebug)
      install_pie_extension xdebug/xdebug xdebug https://github.com/xdebug/xdebug/archive/refs/heads/master.tar.gz
      ;;
    xmlrpc)
      # GLPI 10 is the last version using this extension, and it does not support PHP 8.6.
      if [ "$PHP_MAJOR_MINOR" != "8.6" ]; then
        apt_install libxml2-dev
        # Install from Github (extension should be available on PECL but is not).
        mkdir --parents /tmp/xmlrpc
        curl --fail --silent --show-error --location \
          https://github.com/php/pecl-networking-xmlrpc/archive/ea3c8b6a902a1b24f543aef035edb594211a05b3.tar.gz \
          | tar --extract --gzip --directory=/tmp/xmlrpc --strip-components=1
        docker-php-ext-configure /tmp/xmlrpc --with-xmlrpc
        docker-php-ext-install /tmp/xmlrpc
        rm --recursive --force /tmp/xmlrpc
      fi
      ;;
    zip)
      apt_install libzip-dev
      docker-php-ext-install zip
      ;;
    *)
      echo "Unsupported PHP extension: $extension" >&2
      exit 1
      ;;
  esac
done
