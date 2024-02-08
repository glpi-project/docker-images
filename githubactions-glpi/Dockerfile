ARG BASE_IMAGE

FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI Github Actions PHP container for GLPI plugins" \
  org.opencontainers.image.description="This container is used to run GLPI plugins test suites on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

ARG GLPI_BRANCH

USER root

# Create a user with UID=1001 (the UID used by Github Actions runner) and give it ownership of the `/var/glpi` directory,
# so it can checkout the plugin and create config/user files without ACL issues.
RUN useradd -m -d /home/github-actions-runner -g glpi -u 1001 github-actions-runner \
  && chown -R github-actions-runner:glpi /var/glpi

USER github-actions-runner

RUN \
  # Get target GLPI branch source code.
  git clone --depth=1 --branch=$GLPI_BRANCH https://github.com/glpi-project/glpi /tmp/glpi \
  && git --git-dir="/tmp/glpi/.git" checkout-index --all --force --prefix="/var/glpi/" \
  \
  # Build GLPI.
  && composer --working-dir=/var/glpi build \
  \
  # Clean useless files
  && rm -rf /tmp/glpi \
  && rm -rf /var/glpi/node_modules
