ARG BASE_IMAGE=mysql:latest

FROM $BASE_IMAGE

COPY ./files /

HEALTHCHECK --interval=10s --retries=5 --timeout=5s \
  CMD mysqladmin ping
