#!/bin/bash
set -e -u -o pipefail

# Source GLPI environment variables (includes GLPI_MARKETPLACE_DIR detected at build time)
if [ -f /etc/glpi_env ]; then
  export $(cat /etc/glpi_env | xargs)
fi

/opt/glpi/entrypoint/init-volumes-directories.sh
/opt/glpi/entrypoint/forward-logs.sh
/opt/glpi/entrypoint/wait-for-db.sh entrypoint
/opt/glpi/entrypoint/install.sh

exec "$@"
