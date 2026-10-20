# `base` is provided by `docker-bake.hcl` (see the `githubactions-base` directory).
FROM base

LABEL \
  org.opencontainers.image.title="GLPI Github Actions PHP container" \
  org.opencontainers.image.description="This container is used to run GLPI test suite on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

RUN \
  # Disable sodium PHP extension (Test should validate that polyfill works).
  rm /usr/local/etc/php/conf.d/docker-php-ext-sodium.ini \
  \
  # Install Cypress dependencies
  && apt-get update \
  && apt-get install --assume-yes --no-install-recommends --quiet libgtk2.0-0 libgtk-3-0 libgbm-dev libnotify-dev libnss3 libxss1 libasound2 libxtst6 xauth xvfb \
  \
  # Clean sources list
  && rm -rf /var/lib/apt/lists/*

# Create application volume (used to share data across jobs),
# give its ownage to glpi user (1000:1000) and define it as base working dir
RUN addgroup -gid 1000 glpi \
  && useradd -m -d /home/glpi -g glpi -u 1000 glpi \
  && mkdir -p /var/www/glpi \
  && chown glpi:glpi /var/www/glpi
USER glpi
VOLUME /home/glpi
VOLUME /var/www/glpi
WORKDIR /var/www/glpi

# Define GLPI environment variables
ENV \
  GLPI_ENVIRONMENT_TYPE=testing
