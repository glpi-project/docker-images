#!/bin/bash
set -e -u -o pipefail

echo "Configuring PHP settings from environment variables..."

# Create dynamic PHP configuration file
cat > /usr/local/etc/php/conf.d/glpi-dynamic.ini <<EOF
; Session cookies security
session.cookie_httponly = ${PHP_SESSION_COOKIE_HTTPONLY}
session.cookie_samesite = "${PHP_SESSION_COOKIE_SAMESITE}"

; Do not expose PHP version
expose_php = ${PHP_EXPOSE_PHP}

; Allow posting larger files (e.g., for attachments)
post_max_size = ${PHP_POST_MAX_SIZE}
upload_max_filesize = ${PHP_UPLOAD_MAX_FILESIZE}

; Increase values for large operations
memory_limit = ${PHP_MEMORY_LIMIT}
max_input_vars = ${PHP_MAX_INPUT_VARS}
max_execution_time = ${PHP_MAX_EXECUTION_TIME}

; OPCache settings
opcache.validate_timestamps = ${PHP_OPCACHE_VALIDATE_TIMESTAMPS}
opcache.max_accelerated_files = ${PHP_OPCACHE_MAX_ACCELERATED_FILES}
opcache.memory_consumption = ${PHP_OPCACHE_MEMORY_CONSUMPTION}
opcache.max_wasted_percentage = ${PHP_OPCACHE_MAX_WASTED_PERCENTAGE}
EOF

echo "PHP configuration applied:"
echo "  - Memory limit: ${PHP_MEMORY_LIMIT}"
echo "  - Post max size: ${PHP_POST_MAX_SIZE}"
echo "  - Upload max filesize: ${PHP_UPLOAD_MAX_FILESIZE}"
echo "  - Max execution time: ${PHP_MAX_EXECUTION_TIME}s"
echo "  - OPcache memory: ${PHP_OPCACHE_MEMORY_CONSUMPTION}M"
