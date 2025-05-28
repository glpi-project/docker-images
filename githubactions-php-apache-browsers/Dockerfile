ARG BASE_IMAGE=ghcr.io/glpi-project/githubactions-php-apache

FROM $BASE_IMAGE

USER root

ENV PLAYWRIGHT_BROWSERS_PATH=/opt/pw-browsers

RUN npx playwright install chromium --with-deps

USER www-data
