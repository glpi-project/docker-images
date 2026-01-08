#!/bin/bash
set -e -u -o pipefail

# Wait for database to be ready before proceeding
# Uses PHP mysqli to check database connectivity
# Usage: wait-for-db.sh [caller_name]

caller="${1:-unknown}"
echo "[$caller] Waiting for database to be ready..."
attempts_left=120

until [ $attempts_left -eq 0 ]; do
    # Try a simple database connection check using PHP mysqli
    if php -r "
        \$conn = @new mysqli('$GLPI_DB_HOST', '$GLPI_DB_USER', '$GLPI_DB_PASSWORD', '', (int) '$GLPI_DB_PORT');
        exit(\$conn->connect_error ? 1 : 0);
    " 2>/dev/null; then
        echo "[$caller] The database is now ready and reachable"
        exit 0
    fi

    sleep 1
    attempts_left=$((attempts_left - 1))
    echo "[$caller] Still waiting for database to be ready... $attempts_left attempts left."
done

echo "[$caller] The database is not up or not reachable."
exit 1
