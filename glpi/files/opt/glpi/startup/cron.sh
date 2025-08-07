#!/bin/bash
set -e -u -o pipefail

# Run cron service.
touch /var/log/cron-output.log
touch /var/log/cron-errors.log
tail -F /var/log/cron-output.log &
tail -F /var/log/cron-errors.log &
cron
