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
    setfacl -m user:www-data:rwx,group:www-data:rwx "$dir"
done

# Set ACL for www-data user on marketplace directory
setfacl -m user:www-data:rwx,group:www-data:rwx "/var/www/glpi/marketplace"

# forward logs files to /proc/1/fd/1
# see https://stackoverflow.com/a/63713129
logs=(
    "event.log"
    "cron.log"
    "mail.log"
    "php-errors.log"
    "sql-errors.log"
    "mail-errors.log"
    "access-error.log"
)
for log in "${logs[@]}"
do
    if [ ! -f /var/log/glpi/$log ];
    then
        touch /var/log/glpi/$log
        setfacl -m user:www-data:rwx,group:www-data:rwx /var/log/glpi/$log
    fi
done
tail -f /var/log/glpi/*.log > /proc/1/fd/1 &

# Run cron service.
cron

# Run command previously defined in base php-apache Dockerfile.
apache2-foreground
