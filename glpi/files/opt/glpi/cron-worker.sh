#!/bin/bash
set -e -u -o pipefail

# Wait for database to be ready before starting cron tasks
/opt/glpi/entrypoint/wait-for-db.sh cron-worker

# Infinite loop to run GLPI cron tasks every minute
while true; do
    php /var/www/glpi/front/cron.php || echo "Cron task failed"
    sleep 60
done
