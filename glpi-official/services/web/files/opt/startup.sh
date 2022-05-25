#!/bin/bash

# Run cron service.
cron

# Run command previously defined in base php-apache Dockerfile.
apache2-foreground

if [[ -f "/var/www/glpi/config/config_db.php"]]; then
    echo "GLPI installed already"
else
    echo "GLPI config missing. Installing GLPI..."
    ./opt/install_glpi.sh
    echo "Installation finished"
fi