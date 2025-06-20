#!/bin/bash -e

# Create config and files volume (sub)directories that are missing
# and set ACL for www-data user
dirs=(
    "/var/glpi/config"
    "/var/glpi/files"
    "/var/glpi/files/_cache"
    "/var/glpi/files/_cron"
    "/var/glpi/files/_dumps"
    "/var/glpi/files/_graphs"
    "/var/glpi/files/_locales"
    "/var/glpi/files/_lock"
    "/var/glpi/files/_log"
    "/var/glpi/files/_pictures"
    "/var/glpi/files/_plugins"
    "/var/glpi/files/_rss"
    "/var/glpi/files/_sessions"
    "/var/glpi/files/_tmp"
    "/var/glpi/files/_uploads"
    "/var/glpi/files/_inventories"
)
for dir in "${dirs[@]}"
do
    if [ ! -d "$dir" ]
    then
        mkdir "$dir"
    fi
    chown www-data:www-data "$dir"
    chmod 775 "$dir"
done

# Set ACL for www-data user on marketplace directory
chown www-data:www-data "/var/www/glpi/marketplace"
chmod 775 "/var/www/glpi/marketplace"

# Run cron service.
cron

# Run command previously defined in base php-apache Dockerfile.
apache2-foreground

