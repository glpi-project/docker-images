#!/usr/bin/env bash
set -e -u -o pipefail

Install_Database() {
    if [[ "${GLPI_DB_SSL:-false}" = "true" ]]; then
        ssl_args+=(--db-ssl)
        [ -n "${GLPI_DB_SSL_CA:-}"     ] && ssl_args+=(--db-ssl-ca="$GLPI_DB_SSL_CA")
        [ -n "${GLPI_DB_SSL_CERT:-}"   ] && ssl_args+=(--db-ssl-cert="$GLPI_DB_SSL_CERT")
        [ -n "${GLPI_DB_SSL_KEY:-}"    ] && ssl_args+=(--db-ssl-key="$GLPI_DB_SSL_KEY")
        [ -n "${GLPI_DB_SSL_CAPATH:-}" ] && ssl_args+=(--db-ssl-capath="$GLPI_DB_SSL_CAPATH")
        [ -n "${GLPI_DB_SSL_CIPHER:-}" ] && ssl_args+=(--db-ssl-cipher="$GLPI_DB_SSL_CIPHER")
    fi

    bin/console database:install \
        --db-host="$GLPI_DB_HOST" \
        --db-port="$GLPI_DB_PORT" \
        --db-name="$GLPI_DB_NAME" \
        --db-user="$GLPI_DB_USER" \
        --db-password="$GLPI_DB_PASSWORD" \
        "${ssl_args[@]}" \
        --no-interaction --quiet \
        "${@}" || return 1
}

Install_GLPI() {
    Install_Database || return 1
}

Reconfigure_GLPI() {
    GLPI_Configured || return 1

    echo "Database connection configuration file exists, reconfiguring with new parameters."
    # database|install --reconfigure exit with error if the database exists.
    # It warns about using --force to overwrite existing tables.
    # || true ignore the false-positive failure
    Install_Database --reconfigure || true
}

greetings() {
    local new_installation="${1:-}"

    echo $'\n\n================================================================'
    echo $'Welcome to\n'
    echo $' ██████╗ ██╗     ██████╗ ██╗'
    echo $'██╔════╝ ██║     ██╔══██╗██║'
    echo $'██║  ███╗██║     ██████╔╝██║'
    echo $'██║   ██║██║     ██╔═══╝ ██║'
    echo $'╚██████╔╝███████╗██║     ██║'
    echo $' ╚═════╝ ╚══════╝╚═╝     ╚═╝\n'

    echo $'https://glpi-project.org'

    if [[ "${new_installation}" = '--new' ]]; then
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
        bin/console database:update --no-interaction --quiet ||
            echo "Error: Database update failed."
        bin/console cache:clear --no-interaction --quiet ||
            echo "Warning: cache clearing failed."
        bin/console maintenance:disable --no-interaction --quiet
    fi
}

GLPI_Configured() {
    [[ -f "${GLPI_CONFIG_DIR}/config_db.php" ]] || return 1
}

GLPI_Installed() {
    local reconfigured="${1-}"
    # If the config_db.php file does not exist or there is something wrong with the database,
    # GLPI is not installed
    local exit_code=0

    GLPI_Configured || return 1

    bin/console db:check --no-interaction || exit_code=$?

    # GLPI error code for db:check command:
    # 0: Everything is ok
    # 1-4: Warnings related to sql diffs (not critical)
    # 5: Database connection error
    # 6: version cannot be found
    # 7: no tables found
    # if the command above return an error below 5, GLPI is ok and we can return 0
    if [[ "${exit_code}" -eq 5 && "${reconfigured}" != "--reconfigured" ]]; then
        # reconfigure database connection and recheck the installation status.
        Reconfigure_GLPI

        GLPI_Installed --reconfigured && return 0 || return 1
    fi

    [[ "${exit_code}" -lt 5 ]] && return 0 || return 1
}

is_true() {
    [[ "${1:-}" = "true" || "${1:-}" = "1" ]] && return 0 || return 1
}

# Skipping auto stuff, database configuration is not fully provided
if [[ -z "${GLPI_DB_HOST:-}" || -z "${GLPI_DB_PORT:-}" || -z "${GLPI_DB_NAME:-}" || -z "${GLPI_DB_USER:-}" || -z "${GLPI_DB_PASSWORD:-}" ]]; then
    echo "Database configuration incomplete, forcing GLPI_SKIP_AUTOINSTALL and GLPI_SKIP_AUTOUPDATE to true."
    GLPI_SKIP_AUTOINSTALL='true'
    GLPI_SKIP_AUTOUPDATE='true'
fi

if GLPI_Installed; then
    if ! is_true "${GLPI_SKIP_AUTOUPDATE:-}"; then
        echo "GLPI is installed, and auto-update is enabled. Starting update..."
        Update_GLPI
    fi

    greetings

    exit 0
fi

if ! is_true "${GLPI_SKIP_AUTOINSTALL:-}"; then
    echo "GLPI is not installed. but auto-install is enabled. Starting installation."
    echo "Please wait until you see the greeting, this may take a minute..."
    Install_GLPI
    greetings --new
fi
