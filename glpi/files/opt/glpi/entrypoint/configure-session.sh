#!/bin/bash
set -e -u -o pipefail

# Configure PHP session handler based on environment variables
if [ "${GLPI_USE_REDIS_SESSION:-false}" = "true" ]; then
    echo "Configuring PHP to use Redis for session management..."
    echo "Redis host: ${GLPI_REDIS_SESSION_HOST}"

    # Create session configuration file
    cat > /usr/local/etc/php/conf.d/session-redis.ini <<EOF
; Redis session configuration
session.save_handler = redis
session.save_path = "tcp://${GLPI_REDIS_SESSION_HOST}"
EOF

    echo "Redis session configuration applied."
else
    echo "Using default file-based session management..."
    # Remove Redis session config if it exists
    rm -f /usr/local/etc/php/conf.d/session-redis.ini
fi
