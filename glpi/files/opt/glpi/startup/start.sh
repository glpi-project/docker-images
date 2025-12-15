#!/bin/bash
set -e -u -o pipefail

# Copy the env variables to `/etc/environment`, to make them available for the commands executed by the cron service
# using the `www-data` user.
printenv > /etc/environment

# Run cron service.
cron

# Run command previously defined in base php-apache Dockerfile.
apache2-foreground
