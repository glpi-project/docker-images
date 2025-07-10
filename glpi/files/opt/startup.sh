#!/bin/bash
set -e -u -x -o pipefail

# get GLPI major version
GLPI_MAJOR_VERSION=$(ls /var/www/glpi/version | sort -V | head -n 1 | cut -d. -f1)
# fix marketplace directory for GLPI versions < 11
if [ $GLPI_MAJOR_VERSION -lt 11 ]; then
    GLPI_MARKETPLACE_DIR="/var/www/glpi/marketplace"
fi

# Create `config`, `marketplace` and `files` volume (sub)directories that are missing
# and set ACL for www-data user
dirs=(
    "${GLPI_CONFIG_DIR}"
    "${GLPI_VAR_DIR}"
    "${GLPI_VAR_DIR}/_cache"
    "${GLPI_VAR_DIR}/_cron"
    "${GLPI_VAR_DIR}/_dumps"
    "${GLPI_VAR_DIR}/_graphs"
    "${GLPI_VAR_DIR}/_locales"
    "${GLPI_VAR_DIR}/_lock"
    "${GLPI_VAR_DIR}/_pictures"
    "${GLPI_VAR_DIR}/_plugins"
    "${GLPI_VAR_DIR}/_rss"
    "${GLPI_VAR_DIR}/_sessions"
    "${GLPI_VAR_DIR}/_tmp"
    "${GLPI_VAR_DIR}/_uploads"
    "${GLPI_VAR_DIR}/_inventories"
    "${GLPI_MARKETPLACE_DIR}"
    "${GLPI_LOG_DIR}"
)
for dir in "${dirs[@]}"
do
    if [ ! -d "$dir" ]
    then
        echo "Creating $dir..."
        mkdir "$dir"
    fi
    echo "Setting $dir ACLs..."
    chown -R www-data:www-data "$dir"
    chmod u+rwx "$dir"
    find "$dir" -type d -exec chmod u+rwx {} \;
    find "$dir" -type f -exec chmod u+rw {} \;
done

# run logs script
chmod u+x /opt/logs.sh
/opt/logs.sh

# run install/update script
chmod u+x /opt/install.sh
/opt/install.sh

# Run cron service.
touch /var/log/cron-output.log
touch /var/log/cron-errors.log
tail -F /var/log/cron-output.log &
tail -F /var/log/cron-errors.log &
cron

# Run command previously defined in base php-apache Dockerfile.
apache2-foreground
