# Copy the GLPI env variables to `/etc/environment`, to make them available for the commands executed by the cron service
# using the `www-data` user.
printenv | grep 'GLPI_' > /etc/environment
