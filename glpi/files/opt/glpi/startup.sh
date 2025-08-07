#!/bin/bash
set -e -u -o pipefail

/opt/glpi/startup/install.sh
/opt/glpi/startup/start.sh
