#!/bin/bash
set -e -u -o pipefail

# Load secrets from files (_FILE suffix, /run/secrets/, etc.)
source /opt/glpi/entrypoint/load-secrets.sh

/opt/glpi/entrypoint/init-volumes-directories.sh
/opt/glpi/entrypoint/forward-logs.sh
/opt/glpi/entrypoint/wait-for-db.sh entrypoint
/opt/glpi/entrypoint/install.sh

exec "$@"
