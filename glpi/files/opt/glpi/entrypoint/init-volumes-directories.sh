#!/bin/bash
set -e -u -o pipefail

# Create `config`, `marketplace` and `files` volume (sub)directories that are missing
# and set ACL for www-data user
roots=(
    "${GLPI_CONFIG_DIR}"
    "${GLPI_VAR_DIR}"
    "${GLPI_MARKETPLACE_DIR}"
    "${GLPI_LOG_DIR}"
)
vars=(
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
)
all_dirs=("${roots[@]}" "${vars[@]}")
for dir in "${all_dirs[@]}"
do
    echo "Creating $dir if does not exists..."
    mkdir -p -- "$dir"
done

for dir in "${roots[@]}"
do
    echo "Setting $dir ACLs..."
    chown -R -- www-data:www-data "$dir"
    find "$dir" -type d -exec chmod u+rwx {} +
    find "$dir" -type f -exec chmod u+rw {} +
done
