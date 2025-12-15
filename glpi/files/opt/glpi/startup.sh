#!/bin/bash
set -e -u -o pipefail

/opt/glpi/startup/init-env.sh
/opt/glpi/startup/install.sh
/opt/glpi/startup/start.sh
