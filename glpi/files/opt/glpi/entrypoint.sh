#!/bin/bash
set -e -u -o pipefail

if [ -z "${GLPI_MARKETPLACE_DIR:-}" ]; then
    GLPI_MAJOR=$(ls /var/www/glpi/version/ | sort --version-sort | tail --lines=1| cut --delimiter='.' --fields=1)
    if [ "$GLPI_MAJOR" = "10" ]; then
      export GLPI_MARKETPLACE_DIR="/var/www/glpi/marketplace"
    else
      export GLPI_MARKETPLACE_DIR="/var/glpi/marketplace"
    fi
fi

/opt/glpi/entrypoint/init-volumes-directories.sh
/opt/glpi/entrypoint/forward-logs.sh
/opt/glpi/entrypoint/wait-for-db.sh entrypoint
/opt/glpi/entrypoint/install.sh

exec "$@"
