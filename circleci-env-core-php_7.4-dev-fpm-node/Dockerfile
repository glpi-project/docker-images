FROM php:7.4-rc-fpm-buster

#
# This DockerFile reproduces build step of official CircleCI PHP 7.3-fpm-node image
# and of circleci-env-core image.
#
# It is a temporary solutionto test GLPI against PHP 7.4-dev since PHP and CircleCI does not provide
# images of this version.
#


#
# BEGIN: inclusion of 7.3.7-fpm-buster/Dockerfile form CircleCI repository
# https://github.com/CircleCI-Public/circleci-dockerfiles/tree/master/php/images/7.3.7-fpm-buster/Dockerfile
#


# make Apt non-interactive
RUN echo 'APT::Get::Assume-Yes "true";' > /etc/apt/apt.conf.d/90circleci \
  && echo 'DPkg::Options "--force-confnew";' >> /etc/apt/apt.conf.d/90circleci

ENV DEBIAN_FRONTEND=noninteractive

# Debian Jessie is EOL'd and original repos don't work.
# Switch to the archive mirror until we can get people to
# switch to Stretch.
RUN if grep -q Debian /etc/os-release && grep -q jessie /etc/os-release; then \
    rm /etc/apt/sources.list \
    && echo "deb http://archive.debian.org/debian/ jessie main" >> /etc/apt/sources.list \
    && echo "deb http://security.debian.org/debian-security jessie/updates main" >> /etc/apt/sources.list \
    ; fi

# Make sure PATH includes ~/.local/bin
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=839155
RUN echo 'PATH="$HOME/.local/bin:$PATH"' >> /etc/profile.d/user-local-path.sh

# man directory is missing in some base images
# https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=863199
RUN apt-get update \
  && mkdir -p /usr/share/man/man1 \
  && apt-get install -y \
    git mercurial xvfb apt \
    locales sudo openssh-client ca-certificates tar gzip parallel \
    net-tools netcat unzip zip bzip2 gnupg curl wget make


# Set timezone to UTC by default
RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime

# Use unicode
RUN locale-gen C.UTF-8 || true
ENV LANG=C.UTF-8

# install jq
RUN JQ_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/jq-latest" \
  && curl --silent --show-error --location --fail --retry 3 --output /usr/bin/jq $JQ_URL \
  && chmod +x /usr/bin/jq \
  && jq --version

# Install Docker

# Docker.com returns the URL of the latest binary when you hit a directory listing
# We curl this URL and `grep` the version out.
# The output looks like this:

#>    # To install, run the following commands as root:
#>    curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-17.05.0-ce.tgz && tar --strip-components=1 -xvzf docker-17.05.0-ce.tgz -C /usr/local/bin
#>
#>    # Then start docker in daemon mode:
#>    /usr/local/bin/dockerd

RUN set -ex \
  && export DOCKER_VERSION=$(curl --silent --fail --retry 3 https://download.docker.com/linux/static/stable/x86_64/ | grep -o -e 'docker-[.0-9]*\.tgz' | sort -r | head -n 1) \
  && DOCKER_URL="https://download.docker.com/linux/static/stable/x86_64/${DOCKER_VERSION}" \
  && echo Docker URL: $DOCKER_URL \
  && curl --silent --show-error --location --fail --retry 3 --output /tmp/docker.tgz "${DOCKER_URL}" \
  && ls -lha /tmp/docker.tgz \
  && tar -xz -C /tmp -f /tmp/docker.tgz \
  && mv /tmp/docker/* /usr/bin \
  && rm -rf /tmp/docker /tmp/docker.tgz \
  && which docker \
  && (docker version || true)

# docker compose
RUN COMPOSE_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/docker-compose-latest" \
  && curl --silent --show-error --location --fail --retry 3 --output /usr/bin/docker-compose $COMPOSE_URL \
  && chmod +x /usr/bin/docker-compose \
  && docker-compose version

# install dockerize
RUN DOCKERIZE_URL="https://circle-downloads.s3.amazonaws.com/circleci-images/cache/linux-amd64/dockerize-latest.tar.gz" \
  && curl --silent --show-error --location --fail --retry 3 --output /tmp/dockerize-linux-amd64.tar.gz $DOCKERIZE_URL \
  && tar -C /usr/local/bin -xzvf /tmp/dockerize-linux-amd64.tar.gz \
  && rm -rf /tmp/dockerize-linux-amd64.tar.gz \
  && dockerize --version

RUN groupadd --gid 3434 circleci \
  && useradd --uid 3434 --gid circleci --shell /bin/bash --create-home circleci \
  && echo 'circleci ALL=NOPASSWD: ALL' >> /etc/sudoers.d/50-circleci \
  && echo 'Defaults    env_keep += "DEBIAN_FRONTEND"' >> /etc/sudoers.d/env_keep

# BEGIN IMAGE CUSTOMIZATIONS

RUN echo 'Defaults    env_keep += "PHP_INI_DIR"' >> /etc/sudoers.d/env_keep

# Install composer
RUN php -r "copy('https://raw.githubusercontent.com/composer/getcomposer.org/master/web/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer

# Install XDebug
#RUN (pecl install xdebug || pecl install xdebug-2.5.5 || pecl install xdebug-2.7.1) && docker-php-ext-enable xdebug

# Install common extensions
RUN apt install -y libicu-dev zlib1g-dev libzip-dev && \
    rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-configure intl && docker-php-ext-install intl
RUN docker-php-ext-install zip
# END IMAGE CUSTOMIZATIONS

USER circleci

CMD ["/bin/sh"]


#
# BEGIN: inclusion of 7.3.7-fpm-buster/node/Dockerfile form CircleCI repository
# https://github.com/CircleCI-Public/circleci-dockerfiles/blob/master/php/images/7.3.7-fpm-buster/node/Dockerfile
#


# Verify the circleci user exists before proceeding
RUN whoami

# node installations command expect to run as root
USER root
## Using node installation from https://raw.githubusercontent.com/nodejs/docker-node/f8f2384f7edc345f5ffc0496458005981b512882/10/stretch/Dockerfile

RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

ENV NODE_VERSION 10.16.0

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  # gpg keys listed at https://github.com/nodejs/node#release-keys
  && set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

ENV YARN_VERSION 1.16.0

RUN set -ex \
  && for key in \
    6A010C5166006599AA17F08146C2130DFD2497F5 \
  ; do \
    gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --batch --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --batch --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz" \
  && curl -fsSLO --compressed "https://yarnpkg.com/downloads/$YARN_VERSION/yarn-v$YARN_VERSION.tar.gz.asc" \
  && gpg --batch --verify yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz \
  && mkdir -p /opt \
  && tar -xzf yarn-v$YARN_VERSION.tar.gz -C /opt/ \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarn /usr/local/bin/yarn \
  && ln -s /opt/yarn-v$YARN_VERSION/bin/yarnpkg /usr/local/bin/yarnpkg \
  && rm yarn-v$YARN_VERSION.tar.gz.asc yarn-v$YARN_VERSION.tar.gz



# Basic smoke test
RUN node --version

USER circleci


#
# BEGIN: inclusion of Dockerfile form circleci-env-core
# 
# Some elements have be been commented:
# - PDO is already installed by default,
# - IMAP extension cannot be installed due to conflict with libssl version
# - removal of xdebug ext is unecessary


# Switch to root user for installation commands
USER root

RUN \
  # Clean APT sources list to prevent packages list update error:
  # E: Could not open file /var/lib/apt/lists/deb.debian.org_debian_dists_buster_main_binary-amd64_Packages.diff_Index - open (2: No such file or directory)
  rm -rf /var/lib/apt/lists/* \
  \
  && if [ "$(grep -oP '(?<=^VERSION_CODENAME=).+' /etc/os-release | tr -d '\"')" = "buster" ]; then \
    # On Buster, install the old freetype6 version to make freetype-config script available
    # see https://github.com/docker-library/php/issues/865
    # TODO This may be removed if future PHP versions fixes this
    echo "\033[0;31m Fallback to old version of freetype6 \033[0m" \
    && echo "deb http://deb.debian.org/debian stretch main" >> /etc/apt/sources.list.d/stretch.list \
    && apt-get update && apt-get install --assume-yes --allow-downgrades --no-install-recommends --quiet libfreetype6-dev=2.6.3-3.2 libfreetype6=2.6.3-3.2 \
    && rm /etc/apt/sources.list.d/stretch.list \
  ; else \
    # On Stretch, install the available freetype6 version that contains freetype-config script
    apt-get update && apt-get install --assume-yes --no-install-recommends --quiet libfreetype6-dev \
  ; fi \
  \
  # Update APT sources list
  && apt-get update \
  \
  # Install MySQL client.
  && apt-get install --assume-yes --no-install-recommends --quiet default-mysql-client \
  \
  # Install mail server and getmail utility.
  && apt-get install --assume-yes --no-install-recommends --quiet dovecot-imapd dovecot-pop3d getmail4 \
  && maildirmake.dovecot /home/circleci/Maildir circleci \
  \
  # Install exif extension.
  && docker-php-ext-install exif \
  \
  # Install GD PHP extension.
  && apt-get install --assume-yes --no-install-recommends --quiet libjpeg-dev libpng-dev \
  && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
  && docker-php-ext-install gd \
  \
  # Install imap PHP extension.
  #&& apt-get install --assume-yes --no-install-recommends --quiet libc-client-dev libkrb5-dev \
  #&& docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
  #&& docker-php-ext-install imap \
  \
  # Install mysqli PHP extension (required only for GLPI prior to 10.0).
  && docker-php-ext-install mysqli \
  \
  # Install PDO MySQL PHP extension.
  #&& docker-php-ext-install pdo pdo_mysql \
  && docker-php-ext-install pdo_mysql \
  \
  # Install XMLRPC PHP extension.
  && apt-get install --assume-yes --no-install-recommends --quiet libxml2-dev \
  && docker-php-ext-install xmlrpc \
  \
  # Install APCU PHP extension.
  # apcu-4.0.11 is the fallback version for PHP prior to 7.0
  && (pecl install apcu || pecl install apcu-4.0.11) \
  && docker-php-ext-enable apcu \
  && echo "apc.enable=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  && echo "apc.enable_cli=1" >> /usr/local/etc/php/conf.d/docker-php-ext-apcu.ini \
  \
  # Update PHP configuration.
  && echo "memory_limit = 512M" >> /usr/local/etc/php/conf.d/docker-php-memory.ini \
  \
  # Disable xdebug PHP extension.
  #&& rm /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
  \
  # Update composer to latest version.
  && composer self-update --no-interaction --no-progress \
  \
  # Clean sources list.
  && rm -rf /var/lib/apt/lists/*

# Copy files to container.
COPY ./files /

# Switch back to circleci user
USER circleci
