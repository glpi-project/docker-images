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
#   --no-wait-for-db          - Do not wait for database before starting
#
# Behavior:
#   --interval: Runs immediately on start, then repeats every N seconds
#   --daily:    Waits until the specified time, then repeats daily
#
# Examples:
#   # Run LDAP sync every 6 hours (runs immediately, then every 6h)
#   scheduler.sh --interval 21600 --name "LDAP Sync" -- php bin/console ldap:synchronize_users
#
#   # Run backup daily at 03:00 (waits until 03:00, then repeats daily)
#   scheduler.sh --daily 03:00 -- sh /opt/glpi/custom-backup.sh
#

set -e -u -o pipefail

# Defaults
MODE=""
INTERVAL=""
DAILY_TIME=""
WAIT_FOR_DB=1
TASK_NAME=""
COMMAND=()

# Functions
log() {
    if [[ -n "$TASK_NAME" ]]; then
        echo "[$TASK_NAME] $*"
    else
        echo "$*"
    fi
}

log_error() {
    log "[ERROR] $*" >&2
}

get_daily_sleep_seconds() {
    local now=$(date +%s)
    local target=$(date -d "today $DAILY_TIME" +%s)
    if [[ $target -le $now ]]; then
        target=$(date -d "tomorrow $DAILY_TIME" +%s)
    fi
    echo $((target - now))
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --interval)       MODE="interval"; INTERVAL="$2"; shift 2 ;;
        --daily)          MODE="daily"; DAILY_TIME="$2"; shift 2 ;;
        --name)           TASK_NAME="$2"; shift 2 ;;
        --no-wait-for-db) WAIT_FOR_DB=0; shift ;;
        --)               shift; COMMAND=("$@"); break ;;
        *)                log_error "Unknown option: $1"; exit 1 ;;
    esac
done

# Validate arguments
if [[ -z "$MODE" ]]; then
    log_error "Specify --interval or --daily"
    exit 1
fi

if [[ ${#COMMAND[@]} -eq 0 ]]; then
    log_error "No command specified after --"
    exit 1
fi



# Wait for database if requested
if [[ "$WAIT_FOR_DB" == "1" ]]; then
    /opt/glpi/entrypoint/wait-for-db.sh scheduler
fi

log "[INFO] Scheduler started (mode=$MODE, command=${COMMAND[*]})"

# Main loop
first_run=true
while true; do
    # Interval mode runs immediately on first iteration
    if [[ "$MODE" == "daily" ]] || [[ "$first_run" == "false" ]]; then
        if [[ "$MODE" == "interval" ]]; then
            sleep_seconds="$INTERVAL"
        else
            sleep_seconds=$(get_daily_sleep_seconds)
        fi
        log "[INFO] Next run in ${sleep_seconds}s ($(date -d "+$sleep_seconds seconds" '+%Y-%m-%d %H:%M:%S'))"
        sleep "$sleep_seconds"
    fi
    first_run=false

    "${COMMAND[@]}" 2>&1 | while IFS= read -r line; do log "$line"; done || log_error "Exit code: $?"
done
