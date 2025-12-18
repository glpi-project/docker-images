#!/bin/bash
set -e -u -o pipefail

# Create GLPI log files if they do not exist, set rights for www-data user
# and forward them to stdout/stderr (see https://stackoverflow.com/a/63713129).
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
all_logs=(
    "${info_logs[@]}"
    "${error_logs[@]}"
)
for log in "${all_logs[@]}"
do
    if [ ! -f "$log" ];
    then
        touch "$log"
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



