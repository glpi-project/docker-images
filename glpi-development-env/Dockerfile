# `base` is provided by `docker-bake.hcl` (see the `githubactions-base` directory).
FROM base

LABEL \
  org.opencontainers.image.title="GLPI development environment" \
  org.opencontainers.image.description="This container can be used to serve GLPI in a development environment." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

RUN --mount=type=bind,from=ghcr.io/php/pie:bin,source=/pie,target=/usr/local/bin/pie \
  \
  # Install bz2 (for marketplace), opcache and xdebug PHP extensions (also updates the APT sources list, cleaned in the base image).
  install-php-extensions bz2 opcache xdebug \
  \
  # Install Cypress dependencies
  && apt-get install --assume-yes --no-install-recommends --quiet libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2 libxtst6 xauth xvfb \
  \
  # Install dependencies for plugin release tool
  && apt-get install --assume-yes --no-install-recommends --quiet gpg python3 python3-git python3-gitdb python3-github python3-lxml python3-termcolor \
  && ln -s /usr/bin/python3 /usr/bin/python \
  \
  # Install transifex client
  && (cd /usr/local/bin/ && curl --silent --location https://raw.githubusercontent.com/transifex/cli/master/install.sh | bash) \
  \
  # Install misc util packages commonly used by developers
  && apt-get install --assume-yes --no-install-recommends --quiet htop jq nano sudo vim zsh \
  \
  # Install libcap2-bin for setcap
  && apt-get install --assume-yes --no-install-recommends --quiet libcap2-bin \
  \
  # Clean sources list
  && rm -rf /var/lib/apt/lists/*

# Allow apache process to bind to port 80 as non-root user
RUN setcap cap_net_bind_service=+ep /usr/sbin/apache2

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
