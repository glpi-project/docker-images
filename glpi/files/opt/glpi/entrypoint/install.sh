#!/usr/bin/env bash
set -e -u -o pipefail

Install_GLPI() {
    extra_args=()
    if [[ "${GLPI_DB_SSL:-false}" = "true" ]]; then
        extra_args+=(--db-ssl)
        [ -n "${GLPI_DB_SSL_CA:-}"     ] && extra_args+=(--db-ssl-ca="$GLPI_DB_SSL_CA")
        [ -n "${GLPI_DB_SSL_CERT:-}"   ] && extra_args+=(--db-ssl-cert="$GLPI_DB_SSL_CERT")
        [ -n "${GLPI_DB_SSL_KEY:-}"    ] && extra_args+=(--db-ssl-key="$GLPI_DB_SSL_KEY")
        [ -n "${GLPI_DB_SSL_CAPATH:-}" ] && extra_args+=(--db-ssl-capath="$GLPI_DB_SSL_CAPATH")
        [ -n "${GLPI_DB_SSL_CIPHER:-}" ] && extra_args+=(--db-ssl-cipher="$GLPI_DB_SSL_CIPHER")
    fi

    if [[ -f "${GLPI_CONFIG_DIR}/config_db.php" ]]; then
        echo "Database connection configuration file exists, reconfiguring with new parameters."
        extra_args+=(--reconfigure)
    fi

    bin/console database:install \
        --db-host="$GLPI_DB_HOST" \
        --db-port="$GLPI_DB_PORT" \
        --db-name="$GLPI_DB_NAME" \
        --db-user="$GLPI_DB_USER" \
        --db-password="$GLPI_DB_PASSWORD" \
        "${extra_args[@]}" \
        --no-interaction --quiet
}

greetings() {
    local new_installation="$1"

    echo $'\n\n================================================================'
    echo $'Welcome to\n'
    echo $' ██████╗ ██╗     ██████╗ ██╗'
    echo $'██╔════╝ ██║     ██╔══██╗██║'
    echo $'██║  ███╗██║     ██████╔╝██║'
    echo $'██║   ██║██║     ██╔═══╝ ██║'
    echo $'╚██████╔╝███████╗██║     ██║'
    echo $' ╚═════╝ ╚══════╝╚═╝     ╚═╝\n'

    echo $'https://glpi-project.org'

    if [ "$new_installation" = true ]; then
        echo $'\n================================================================'
        echo $'GLPI installation completed successfully!\n'
        echo $'Please access GLPI via your web browser to complete the setup.'
        echo $'You can use the following credentials:\n'
        echo $'- Username: glpi'
        echo $'- Password: glpi'
        echo $'================================================================\n'
    fi
}

Update_GLPI() {
    if ! bin/console db:is_up_to_date --no-interaction --quiet; then
        bin/console maintenance:enable --no-interaction --quiet
        bin/console database:update --no-interaction --quiet
        bin/console cache:clear --no-interaction --quiet
        bin/console maintenance:disable --no-interaction --quiet
    fi
}

GLPI_Installed() {
    # If the config_db.php file does not exist or there is something wrong with the database,
    # GLPI is not installed
    local exit_code=0

    if [[ ! -f "${GLPI_CONFIG_DIR}/config_db.php" ]]; then
        return 1
    fi

    bin/console db:check --no-interaction || exit_code=$?
    # GLPI error code for db:check command:
    # 0: Everything is ok
    # 1-4: Warnings related to sql diffs (not critical)
    # 5: Database connection error
    # 6: version cannot be found
    # 7: no tables found
    # if the command above return an error below 5, GLPI is ok and we can return 0
    if [ "${exit_code}" -lt 5 ]; then
        return 0
    fi

    return 1;
}

is_true() {
    [[ "${1:-}" = "true" || "${1:-}" = "1" ]] && return 0

    return 1
}

# Skipping auto stuff, database configuration is not fully provided
if [[ -z "${GLPI_DB_HOST:-}" || -z "${GLPI_DB_PORT:-}" || -z "${GLPI_DB_NAME:-}" || -z "${GLPI_DB_USER:-}" || -z "${GLPI_DB_PASSWORD:-}" ]]; then
    echo "Database configuration incomplete, forcing GLPI_SKIP_AUTOINSTALL and GLPI_SKIP_AUTOUPDATE to true."
    GLPI_SKIP_AUTOINSTALL='true'
    GLPI_SKIP_AUTOUPDATE='true'
fi

if ! GLPI_Installed && ! is_true "${GLPI_SKIP_AUTOINSTALL:-}"; then
    echo "GLPI is not installed. but auto-install is enabled. Starting installation."
    echo "Please wait until you see the greeting, this may take a minute..."
    Install_GLPI
    greetings true
fi

# Recheck installation in case Install_GLPI simply reconfigured the connection
if GLPI_Installed && ! is_true "${GLPI_SKIP_AUTOUPDATE:-}"; then
    echo "GLPI is installed, and auto-update is enabled. Starting update..."
    Update_GLPI
    greetings false
fi
