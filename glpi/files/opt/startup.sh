#!/bin/bash -e

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

# forward logs files to stdout/stderr
# see https://stackoverflow.com/a/63713129
info_logs=(
    "${GLPI_LOG_DIR}/event.log"
    "${GLPI_LOG_DIR}/cron.log"
    "${GLPI_LOG_DIR}/mail.log"
)
error_logs=(
    "${GLPI_LOG_DIR}/php-errors.log"
    "${GLPI_LOG_DIR}/sql-errors.log"
    "${GLPI_LOG_DIR}/mail-errors.log"
    "${GLPI_LOG_DIR}/access-errors.log"
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
        touch "$log"
        chown www-data:www-data "$log"
        chmod u+rw "$log"
    fi
done

# info log files to stdout
for log in "${info_logs[@]}"
do
    tail -F "$log" > /proc/1/fd/1 &
done

# error log files to stderr
for log in "${error_logs[@]}"
do
    tail -F "$log" > /proc/1/fd/2 &
done

# Run cron service.
cron

# Run command previously defined in base php-apache Dockerfile.
apache2-foreground
