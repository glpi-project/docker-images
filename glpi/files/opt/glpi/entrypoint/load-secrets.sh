#!/bin/bash
set -e -u -o pipefail

# Docker secrets support for GLPI
# Resolves sensitive environment variables from files (Docker secrets, Kubernetes secrets, or _FILE suffix).
#
# Priority order:
#   1. VAR_FILE environment variable (points to a file containing the value)
#   2. /run/secrets/VAR file (Docker Swarm / Kubernetes / Podman)
#   3. Existing environment variable value (default behavior)

# file_env - Read an environment variable from a file, following the Docker _FILE convention.
# Usage: file_env VAR [DEFAULT]
#
# Based on the pattern used by official Docker images (mysql, mariadb, postgres).
file_env() {
    local var="$1"
    local default="${2:-}"

    local file_var="${var}_FILE"
    local val="$default"

    # Get current values
    local current_val="${!var:-}"
    local file_val="${!file_var:-}"

    if [ -n "$current_val" ] && [ -n "$file_val" ]; then
        echo "ERROR: Both $var and $file_var are set. These are mutually exclusive."
        exit 1
    fi

    if [ -n "$file_val" ]; then
        # _FILE variable is set, read from the specified file
        if [ ! -f "$file_val" ]; then
            echo "ERROR: Secret file '$file_val' specified in $file_var does not exist."
            exit 1
        fi
        if [ ! -r "$file_val" ]; then
            echo "ERROR: Secret file '$file_val' specified in $file_var is not readable."
            exit 1
        fi
        val="$(< "$file_val")"
        unset "$file_var"
    elif [ -f "/run/secrets/$var" ]; then
        # Docker Swarm / Kubernetes / Podman secret
        val="$(< "/run/secrets/$var")"
    elif [ -n "$current_val" ]; then
        # Use existing environment variable
        val="$current_val"
    fi

    export "$var"="$val"
}

# List of environment variables that support secret file resolution
secret_vars=(
    GLPI_DB_HOST
    GLPI_DB_PORT
    GLPI_DB_NAME
    GLPI_DB_USER
    GLPI_DB_PASSWORD
)

for var in "${secret_vars[@]}"; do
    file_env "$var"
done
