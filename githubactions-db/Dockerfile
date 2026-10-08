ARG BASE_IMAGE=mysql:latest

FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI Github Actions database container" \
  org.opencontainers.image.description="This container is used to run GLPI test suite on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

ARG CONFIG_DIR=/etc/mysql/conf.d
COPY ./files/etc/mysql/conf.d/custom.cnf $CONFIG_DIR/custom.cnf

RUN \
  (test -f /usr/bin/mysql || (test -f /usr/bin/mariadb && ln -s /usr/bin/mariadb /usr/bin/mysql)) \
  && (test -f /usr/bin/mysqladmin || (test -f /usr/bin/mariadb-admin && ln -s /usr/bin/mariadb-admin /usr/bin/mysqladmin))

# Use --host=127.0.0.1 --protocol=tcp to force TCP instead of using the unix socket, which might be ready before external
# connections are accepted.
HEALTHCHECK --interval=10s --retries=5 --timeout=5s --start-period=30s --start-interval=1s \
  CMD mysqladmin ping --host=127.0.0.1 --protocol=tcp
