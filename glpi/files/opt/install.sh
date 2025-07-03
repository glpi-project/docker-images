#!/bin/bash
set -e -u -x -o pipefail

Install_GLPI() {
    bin/console database:install \
        --db-host="$GLPI_DB_HOST" \
        --db-port="$GLPI_DB_PORT" \
        --db-name="$GLPI_DB_NAME" \
        --db-user="$GLPI_DB_USER" \
        --db-password="$GLPI_DB_PASSWORD" \
        --no-interaction --reconfigure
}

greetings() {
    local new_installation="$1"

    echo "Welcome to\n"
    echo " ██████╗ ██╗     ██████╗ ██╗"
    echo "██╔════╝ ██║     ██╔══██╗██║"
    echo "██║  ███╗██║     ██████╔╝██║"
    echo "██║   ██║██║     ██╔═══╝ ██║"
    echo "╚██████╔╝███████╗██║     ██║"
    echo " ╚═════╝ ╚══════╝╚═╝     ╚═╝\n"

    echo "https://glpi-project.org"

    if [ "$new_installation" = true ]; then
        echo "\n\n\n================================================================"
        echo "GLPI installation completed successfully!"
        echo "Please access GLPI via your web browser to complete the setup."
        echo "You can use the following credentials:"
        echo "Username: glpi"
        echo "Password: glpi"
    fi
}

Update_GLPI() {
    bin/console database:check_schema_integrity || bin/console database:update --no-interaction
}

GLPI_Installed() {
    if [ -f "${GLPI_CONFIG_DIR}/config_db.php" ]; then
        return 0
    else
        return 1
    fi
}

if ! GLPI_Installed; then
    echo "GLPI is not installed. Starting installation..."
    Install_GLPI
    greetings true
else
    echo "GLPI is already installed. Starting update..."
    Update_GLPI
    greetings
fi
