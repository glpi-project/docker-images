#!/bin/bash
set -e -u -x -o pipefail

/opt/glpi/entrypoint/init-volumes-directories.sh
/opt/glpi/entrypoint/forward-logs.sh

exec "$@"
