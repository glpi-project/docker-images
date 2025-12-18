#!/bin/bash
set -e -u -o pipefail

# Infinite loop to run GLPI cron tasks every minute
while true; do
    php /var/www/glpi/front/cron.php || echo "Cron task failed"
    sleep 60
done
