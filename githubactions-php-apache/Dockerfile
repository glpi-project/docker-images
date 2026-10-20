# `base` is provided by `docker-bake.hcl` (see the `githubactions-base` directory).
FROM base AS main

LABEL \
  org.opencontainers.image.title="GLPI Github Actions PHP container" \
  org.opencontainers.image.description="This container is used to run GLPI test suite on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

RUN --mount=type=bind,from=ghcr.io/php/pie:bin,source=/pie,target=/usr/local/bin/pie \
  \
  # Install PCOV PHP extension (also updates the APT sources list, cleaned in the base image).
  install-php-extensions pcov \
  \
  # Disable sodium PHP extension (Test should validate that polyfill works).
  && rm /usr/local/etc/php/conf.d/docker-php-ext-sodium.ini \
  \
  # Install ldap utils used by plugin CI workflows.
  && apt-get install --assume-yes --no-install-recommends --quiet ldap-utils \
  \
  # Install acl and sudo that will be used to give correct rights in the Gihub Actions runner context.
  # sudo may also be usefull to temporarly install upcoming required system components.
  && apt-get install --assume-yes --no-install-recommends --quiet acl sudo \
  \
  # Install jq that is used for JSON files manipulations.
  && apt-get install --assume-yes --no-install-recommends --quiet jq \
  \
  # Clean sources list
  && rm -rf /var/lib/apt/lists/*

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

#####
# Variant with Playwright system dependencies
#####
FROM main AS playwright

USER root

RUN \
  # Update package list.
  apt-get update \
  \
  # Install Playwright dependencies
  && npx playwright install-deps chromium \
  \
  # Clean sources list
  && rm -rf /var/lib/apt/lists/* \
  \
  # Clean npm cache (created by `npx`, not used later)
  && rm -rf /root/.npm

USER www-data
