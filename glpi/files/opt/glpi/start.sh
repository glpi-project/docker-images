#!/bin/bash
set -e -u -x -o pipefail

# Run cron service.
/opt/glpi/cron.sh

# Run command previously defined in base php-apache Dockerfile.
apache2-foreground
