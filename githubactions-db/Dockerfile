ARG BASE_IMAGE=mysql:latest

FROM $BASE_IMAGE

COPY ./files/etc/mysql/conf.d/custom.cnf /etc/mysql/conf.d/custom.cnf

HEALTHCHECK --interval=10s --retries=5 --timeout=5s \
  CMD mysqladmin ping
