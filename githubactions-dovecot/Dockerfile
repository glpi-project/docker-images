ARG BASE_IMAGE=debian:buster-slim

FROM $BASE_IMAGE

# Create glpi user and its home directory
RUN groupadd --gid 1000 glpi
RUN useradd --create-home --home-dir /home/glpi --gid 1000 --uid 1000 glpi

RUN \
  # Clean APT sources list to prevent packages list update error:
  # E: Could not open file /var/lib/apt/lists/deb.debian.org_debian_dists_buster_main_binary-amd64_Packages.diff_Index - open (2: No such file or directory)
  rm -rf /var/lib/apt/lists/* \
  \
  # Update APT sources list
  && apt-get update \
  \
  # Install mail server and getmail utility.
  && apt-get install --assume-yes --no-install-recommends --quiet dovecot-imapd dovecot-pop3d getmail4 \
  && maildirmake.dovecot /home/glpi/Maildir glpi \
  \
  # Clean sources list.
  && rm -rf /var/lib/apt/lists/*

COPY ./files/etc/dovecot/local.conf /etc/dovecot/local.conf
COPY ./files/etc/dovecot/passwd /etc/dovecot/passwd

HEALTHCHECK --interval=10s --retries=5 --timeout=5s \
  CMD doveadm service status

CMD ["/usr/sbin/dovecot", "-F"]
