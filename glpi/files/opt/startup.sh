#!/bin/bash -e

# Create `config`, `marketplace` and `files` volume (sub)directories that are missing
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
    "/var/glpi/files/_pictures"
    "/var/glpi/files/_plugins"
    "/var/glpi/files/_rss"
    "/var/glpi/files/_sessions"
    "/var/glpi/files/_tmp"
    "/var/glpi/files/_uploads"
    "/var/glpi/files/_inventories"
    "/var/glpi/marketplace"
    "/var/glpi/logs"
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

# forward logs files to stdout/stderr
# see https://stackoverflow.com/a/63713129
info_logs=(
    "/var/glpi/logs/event.log"
    "/var/glpi/logs/cron.log"
    "/var/glpi/logs/mail.log"
)
error_logs=(
    "/var/glpi/logs/php-errors.log"
    "/var/glpi/logs/sql-errors.log"
    "/var/glpi/logs/mail-errors.log"
    "/var/glpi/logs/access-error.log"
)
# Create log files if they do not exist and set rights for www-data user
all_logs=(
    "${info_logs[@]}"
    "${error_logs[@]}"
)
for log in "${all_logs[@]}"
do
    if [ ! -f $log ];
    then
        touch $log
        chown www-data:www-data "$log"
        chmod u+rw "$log"
    fi
done
# info log files to stdout
tail -F ${info_logs[@]} > /proc/1/fd/1 &
# error log files to stderr
tail -F ${error_logs[@]} > /proc/1/fd/2 &

# Run cron service.
cron

# Run command previously defined in base php-apache Dockerfile.
apache2-foreground
