#!/bin/bash
set -e -u -x -o pipefail

# run permissions script
/opt/glpi/permissions.sh

# run logs script
/opt/glpi/logs.sh

exec "$@"
