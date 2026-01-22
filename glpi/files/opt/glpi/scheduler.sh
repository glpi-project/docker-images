#!/bin/bash
#
# Generic Scheduler Script for GLPI Docker
#
# Runs a command on a schedule: fixed interval or daily at a specific time.
#
# Usage:
#   scheduler.sh --interval <seconds> -- <command> [args...]
#   scheduler.sh --daily <HH:MM> -- <command> [args...]
#
# Optional arguments:
#   --name <name>             - Name to display in logs
#   --run-on-start            - Run the command immediately on startup
#   --no-wait-for-db          - Do not wait for database before starting
#
# Examples:
#   # Run LDAP sync every 6 hours
#   scheduler.sh --interval 21600 --name "LDAP Sync" -- php bin/console ldap:synchronize_users
#
#   # Run LDAP sync daily at 03:00
#   scheduler.sh --daily 03:00 -- php bin/console ldap:synchronize_users
#

set -e -u -o pipefail

# Defaults
MODE=""
INTERVAL=""
DAILY_TIME=""
RUN_ON_START=0
WAIT_FOR_DB=1
TASK_NAME=""
COMMAND=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --interval)
            MODE="interval"
            INTERVAL="$2"
            shift 2
            ;;
        --daily)
            MODE="daily"
            DAILY_TIME="$2"
            shift 2
            ;;
        --name)
            TASK_NAME="$2"
            shift 2
            ;;
        --run-on-start)
            RUN_ON_START=1
            shift
            ;;
        --no-wait-for-db)
            WAIT_FOR_DB=0
            shift
            ;;
        --)
            shift
            COMMAND=("$@")
            break
            ;;
        *)
            echo "[ERROR] Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ -z "$MODE" ]]; then
    echo "[ERROR] Specify --interval or --daily" >&2
    exit 1
fi

if [[ ${#COMMAND[@]} -eq 0 ]]; then
    echo "[ERROR] No command specified after --" >&2
    exit 1
fi

# Log helper
log() {
    if [[ -n "$TASK_NAME" ]]; then
        echo "[$TASK_NAME] $*"
    else
        echo "$*"
    fi
}

# Calculate sleep duration
get_sleep_seconds() {
    if [[ "$MODE" == "interval" ]]; then
        echo "$INTERVAL"
    else
        local now=$(date +%s)
        local target=$(date -d "today $DAILY_TIME" +%s)
        if [[ $target -le $now ]]; then
            target=$(date -d "tomorrow $DAILY_TIME" +%s)
        fi
        echo $((target - now))
    fi
}

# Wait for database if requested
if [[ "$WAIT_FOR_DB" == "1" ]] && [[ -x /opt/glpi/entrypoint/wait-for-db.sh ]]; then
    /opt/glpi/entrypoint/wait-for-db.sh scheduler
fi

log "[INFO] Scheduler started (mode=$MODE, command=${COMMAND[*]})"

# Run on start if requested
if [[ "$RUN_ON_START" == "1" ]]; then
    log "[INFO] Running on startup..."
    "${COMMAND[@]}" || true
fi

# Main loop
while true; do
    sleep_seconds=$(get_sleep_seconds)
    log "[INFO] Next run in ${sleep_seconds}s ($(date -d "+$sleep_seconds seconds" '+%Y-%m-%d %H:%M:%S'))"
    sleep "$sleep_seconds"
    "${COMMAND[@]}" || log "[ERROR] Exit code: $?"
done
