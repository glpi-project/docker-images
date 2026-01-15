#!/bin/bash
set -e -u -o pipefail

if [ "${GLPI_CRONTAB_ENABLED:-1}" = "1" ]; then
    echo "[INFO] GLPI cron is enabled. Starting worker tasks..."
    
    # Wait for database to be ready before starting cron tasks
    /opt/glpi/entrypoint/wait-for-db.sh cron-worker
    
    # Infinite loop to run GLPI cron tasks every minute
    while true; do
        php /var/www/glpi/front/cron.php || echo "[ERROR] GLPI cron execution failed"
        sleep 60
    done

else
    echo "[INFO] GLPI cron is disabled (GLPI_CRONTAB_ENABLED=0)."
    # Sleeping forever to keep supervisord happy    
    tail -f /dev/null
fi
