#!/bin/bash

cd /var/www/glpi
bin/console glpi:database:install -H=db -d=glpi -u=${DB_USER} -p=${DB_PASSWORD} -L=${GLPI_LANG:-en_GB} --no-telemetry
