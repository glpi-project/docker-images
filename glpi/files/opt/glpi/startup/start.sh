#!/bin/bash
set -e -u -o pipefail

# Run cron service.
/opt/glpi/startup/cron.sh

# Run command previously defined in base php-apache Dockerfile.
apache2-foreground
