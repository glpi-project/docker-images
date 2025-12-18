#!/bin/bash
set -e -u -o pipefail

/opt/glpi/entrypoint/init-volumes-directories.sh
/opt/glpi/entrypoint/forward-logs.sh
/opt/glpi/startup/install.sh

exec "$@"
