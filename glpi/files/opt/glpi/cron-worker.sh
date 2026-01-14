#!/bin/bash
set -e -u -o pipefail

if [ "${ENABLE_CRONTAB:-1}" = "1" ]; then
    echo "[INFO] Cron ENABLED. Starting worker tasks..."
    
    # Wait for database to be ready before starting cron tasks
    /opt/glpi/entrypoint/wait-for-db.sh cron-worker
    
    # Infinite loop to run GLPI cron tasks every minute
    while true; do
        php /var/www/glpi/front/cron.php || echo "[ERROR] GLPI cron task failed"
        sleep 60
    done

else
    # Infinite loop to run GLPI cron tasks every minute
    echo "[INFO] Cron DISABLED (ENABLE_CRONTAB=0)."
    echo "[INFO] Sleeping forever to keep supervisord happy..."
    
    tail -f /dev/null
fi
