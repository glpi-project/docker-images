ARG BASE_IMAGE

FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI Github Actions PHP/Apache container for GLPI plugins" \
  org.opencontainers.image.description="This container is used to run GLPI plugins test suites on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

ARG GLPI_BRANCH

RUN \
  # Get target GLPI branch source code.
  git clone --depth=1 --branch=$GLPI_BRANCH https://github.com/glpi-project/glpi /tmp/glpi \
  && git --git-dir="/tmp/glpi/.git" checkout-index --all --force --prefix="/var/www/glpi/" \
  \
  # Build GLPI.
  && composer --working-dir=/var/www/glpi build \
  \
  # Clean useless files
  && rm -rf /tmp/glpi
