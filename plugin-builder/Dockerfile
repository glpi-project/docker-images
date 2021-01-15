FROM php:cli-alpine

# Copy composer binary from latest composer image.
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN \
  # Update APK package list.
  apk update \
  \
  # Install build dependencies.
  && apk add --virtual .build-deps build-base \
  \
  # Install nodejs and npm required for some plugin's dependencies.
  && apk add nodejs npm \
  \
  # Install Python, pip and Python modules required by "plugin-release" script.
  && apk add python3-dev && ln -s /usr/bin/python3 /usr/bin/python \
  && apk add py3-pip \
  && apk add libxml2-dev libxslt-dev && pip install lxml \
  && apk add git && pip install gitpython \
  && pip install PyGithub \
  && pip install termcolor \
  \
  # Install gettext required to build locale files.
  && apk add gettext \
  \
  # Remove build dependencies.
  && apk del -f .build-deps \
  \
  # Clean sources list.
  && rm -rf /var/cache/apk/*

# Reset entrypoint and default command.
ENTRYPOINT ["/bin/sh"]
CMD ["/bin/sh"]
