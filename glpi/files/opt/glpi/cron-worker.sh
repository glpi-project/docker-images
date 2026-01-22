#!/bin/bash
set -e -u -o pipefail

if [ "${GLPI_CRONTAB_ENABLED:-1}" = "1" ]; then
    echo "[INFO] GLPI cron is enabled. Starting worker tasks..."

    # Database waiting is done in scheduler.sh
    /opt/glpi/scheduler.sh --interval 60 --name "GLPI Cron" -- php /var/www/glpi/front/cron.php
else
    echo "[INFO] GLPI cron is disabled (GLPI_CRONTAB_ENABLED=0)."
    # Sleeping forever to keep supervisord happy
    tail -f /dev/null
fi
