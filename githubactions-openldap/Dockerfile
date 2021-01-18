ARG BASE_IMAGE=alpine

FROM $BASE_IMAGE

LABEL \
  org.opencontainers.image.title="GLPI Github Actions OpenLDAP container" \
  org.opencontainers.image.description="This container is used to run GLPI test suite on Github Actions." \
  org.opencontainers.image.url="https://github.com/glpi-project/docker-images" \
  org.opencontainers.image.source="git@github.com:glpi-project/docker-images"

RUN \
  # Update APK package list.
  apk update \
  \
  # Install openldap.
  && apk add openldap openldap-back-hdb openldap-clients \
  \
  # Clean sources list.
  && rm -rf /var/cache/apk/*

# Use default config for LDAP database
RUN mv /var/lib/openldap/openldap-data/DB_CONFIG.example /var/lib/openldap/openldap-data/DB_CONFIG

COPY ./files/etc/openldap/slapd.conf /etc/openldap/slapd.conf

HEALTHCHECK --interval=10s --retries=5 --timeout=5s \
  CMD ldapwhoami  -x -H ldap://127.0.0.1:3890/ -D "cn=Manager,dc=glpi,dc=org" -w insecure || exit 1

CMD ["slapd", "-d", "32768", "-h", "ldap://0.0.0.0:3890/"]
 