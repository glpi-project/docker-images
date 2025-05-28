ARG BASE_IMAGE=glpi-project:githubactions-php-apache

#####
# Build main image
#####
FROM $BASE_IMAGE

ENV PLAYWRIGHT_BROWSERS_PATH=opt/pw-browsers

RUN npx playwright install chromium --with-deps
