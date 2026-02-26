# GLPI Docker — Operations Guide

A practical reference for system administrators deploying and operating GLPI with Docker.

For basic setup, see the [README](../README.md).

## Table of Contents

- [Environment Variables](#environment-variables)
- [Volumes and Data Persistence](#volumes-and-data-persistence)
- [Startup Behavior](#startup-behavior)
- [Scheduled Jobs](#scheduled-jobs)
- [Logs](#logs)
- [PHP Configuration](#php-configuration)
- [Apache Configuration](#apache-configuration)
- [Reverse Proxy and HTTPS](#reverse-proxy-and-https)
- [Upgrading GLPI](#upgrading-glpi)
- [Backup and Restore](#backup-and-restore)
- [Security Considerations](#security-considerations)
- [Horizontal Scaling](#horizontal-scaling)
- [Troubleshooting](#troubleshooting)

---

## Environment Variables

### Database Connection

All five variables are **required** for auto-install and auto-update to work. If any is missing, both features are disabled and GLPI will present the web-based installation wizard instead.

| Variable | Example | Description |
|:---------|:--------|:------------|
| `GLPI_DB_HOST` | `db` | Database hostname or IP |
| `GLPI_DB_PORT` | `3306` | Database TCP port |
| `GLPI_DB_NAME` | `glpi` | Database name |
| `GLPI_DB_USER` | `glpi` | Database username |
| `GLPI_DB_PASSWORD` | `secret` | Database password |

### Installation Control

| Variable | Default | Description |
|:---------|:--------|:------------|
| `GLPI_SKIP_AUTOINSTALL` | `false` | Set to `true` to skip automatic database installation on first run |
| `GLPI_SKIP_AUTOUPDATE` | `false` | Set to `true` to skip automatic database schema updates on restart |

### Cron Control

| Variable | Default | Description |
|:---------|:--------|:------------|
| `GLPI_CRONTAB_ENABLED` | `1` | Set to `0` to disable the background cron worker |

### Path Configuration

These are preconfigured and generally do not need to be changed:

| Variable | Default | Description |
|:---------|:--------|:------------|
| `GLPI_CONFIG_DIR` | `/var/glpi/config` | Configuration directory |
| `GLPI_VAR_DIR` | `/var/glpi/files` | Application data directory |
| `GLPI_LOG_DIR` | `/var/glpi/logs` | Log files directory |
| `GLPI_MARKETPLACE_DIR` | `/var/glpi/marketplace` | Plugin marketplace directory |

---

## Volumes and Data Persistence

The image declares a single volume at `/var/glpi` containing all persistent data:

```
/var/glpi/
├── config/          # Database credentials, local configuration
├── files/           # Application data
│   ├── _cache/      # Application cache
│   ├── _cron/       # Cron task state
│   ├── _dumps/      # Database dumps
│   ├── _graphs/     # Generated graphs
│   ├── _locales/    # Translation files
│   ├── _lock/       # Lock files
│   ├── _pictures/   # Uploaded images
│   ├── _plugins/    # Plugin working data
│   ├── _rss/        # RSS feed cache
│   ├── _sessions/   # PHP session files
│   ├── _tmp/        # Temporary files
│   ├── _uploads/    # User-uploaded documents
│   └── _inventories/# GLPI Agent inventory data
├── marketplace/     # Plugins installed from marketplace
└── logs/            # Application log files
```

### Named Volumes vs Bind Mounts

**Named volumes** (recommended) — Docker manages permissions automatically:

```yaml
volumes:
  - glpi_data:/var/glpi
```

**Bind mounts** — you must ensure the host directory is writable by UID 33 (`www-data`):

```bash
mkdir -p ./glpi_data
chown -R 33:33 ./glpi_data
```

```yaml
volumes:
  - ./glpi_data:/var/glpi
```

### Custom Plugins

Mount your own plugins directory alongside the marketplace:

```yaml
volumes:
  - ./my_plugins:/var/www/glpi/plugins:ro
```

### GLPI 10.x Note

For GLPI 10.0.x, the marketplace uses a different path. Add a separate volume:

```yaml
volumes:
  - glpi_marketplace:/var/www/glpi/marketplace
```

If building your own image for 10.x:
```bash
docker build --build-arg GLPI_MARKETPLACE_DIR=/var/www/glpi/marketplace glpi/
```

---

## Startup Behavior

When the container starts, it runs these steps in order before serving requests:

1. **Create directories** — Ensures all required directories exist under `/var/glpi` and checks write permissions
2. **Forward logs** — Starts tailing GLPI log files to container stdout/stderr
3. **Wait for database** — Retries connecting to the database for up to 120 seconds
4. **Install or update** — Runs auto-install (first run) or auto-update (version change) if enabled

If any step fails, the container stops immediately.

After startup, two processes run under Supervisor:
- **Apache** — serves the web application on port 80
- **Cron worker** — executes GLPI background tasks every 60 seconds

---

## Scheduled Jobs

The container runs as non-root (`www-data`), so traditional cron is not available. Instead, custom jobs are added through Supervisor using the built-in scheduler.

### Scheduler Modes

| Mode | Syntax | Behavior |
|:-----|:-------|:---------|
| Interval | `--interval <seconds>` | Runs immediately, then repeats every N seconds |
| Daily | `--daily <HH:MM>` | Waits until the specified time, then repeats daily |

### Additional Options

| Flag | Description |
|:-----|:------------|
| `--name <name>` | Label displayed in log output |
| `--no-wait-for-db` | Skip database availability check before starting |

### Example: LDAP Sync Every 6 Hours

Create `ldap-sync.conf`:
```ini
[program:ldap-sync]
command = /opt/glpi/scheduler.sh --interval 21600 --name "LDAP Sync" -- php /var/www/glpi/bin/console ldap:synchronize_users
autorestart = true
stdout_logfile = /dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile = /dev/stderr
stderr_logfile_maxbytes = 0
```

Mount it in your `docker-compose.yml`:
```yaml
volumes:
  - ./ldap-sync.conf:/etc/supervisor/conf.d/ldap-sync.conf:ro
```

### Example: Daily Backup at 2 AM

Create `backup.conf`:
```ini
[program:daily-backup]
command = /opt/glpi/scheduler.sh --daily 02:00 --name "Daily Backup" -- /opt/glpi/scripts/backup.sh
autorestart = true
stdout_logfile = /dev/stdout
stdout_logfile_maxbytes = 0
stderr_logfile = /dev/stderr
stderr_logfile_maxbytes = 0
```

---

## Logs

GLPI log files are automatically forwarded to Docker's logging system:

| Log File | Stream | Content |
|:---------|:-------|:--------|
| `event.log` | stdout | Application events |
| `cron.log` | stdout | Cron task execution |
| `mail.log` | stdout | Mail operations |
| `php-errors.log` | stderr | PHP errors |
| `sql-errors.log` | stderr | Database query errors |
| `mail-errors.log` | stderr | Mail delivery errors |
| `access-errors.log` | stderr | Access control errors |

### Viewing Logs

```bash
# All GLPI logs
docker compose logs glpi

# Follow in real time
docker compose logs -f glpi

# Only errors
docker compose logs glpi 2>&1 | grep -i error
```

### Docker Logging Limits

To prevent logs from consuming unlimited disk space, add logging limits:

```yaml
services:
  glpi:
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
```

---

## PHP Configuration

The image uses `php.ini-production` with additional hardening.

### Default Settings

| Setting | Value | Description |
|:--------|:------|:------------|
| `session.cookie_httponly` | `on` | Cookies not accessible via JavaScript |
| `session.cookie_samesite` | `Strict` | Cookies only sent to same-origin requests |
| `expose_php` | `off` | PHP version hidden from HTTP headers |
| `session.gc_probability` | `1` | Session garbage collection enabled |
| `session.gc_divisor` | `100` | GC runs on ~1% of requests |
| `session.gc_maxlifetime` | `60480` | Session lifetime (~16.8 hours) |

### Overriding PHP Settings

Mount a custom `.ini` file:

```yaml
volumes:
  - ./custom-php.ini:/usr/local/etc/php/conf.d/custom-php.ini:ro
```

**Common overrides:**
```ini
memory_limit = 256M
upload_max_filesize = 50M
post_max_size = 50M
max_execution_time = 300
```

### Verify Settings

```bash
docker compose exec glpi php -r "echo ini_get('memory_limit');"
```

Or check from the GLPI web interface under `Setup > General > System > Server`.

### PHP Extensions Included

apcu, bcmath, bz2, exif, gd (with FreeType/JPEG), intl, ldap, mysqli, opcache, redis, soap, zip.

---

## Apache Configuration

The image ships with:

- **DocumentRoot:** `/var/www/glpi/public`
- **Module:** `mod_rewrite` enabled
- **Hardening:** `ServerTokens Prod`, `ServerSignature Off`
- **API support:** HTTP `Authorization` header preserved for Bearer token authentication

### Custom Apache Configuration

Mount a `.conf` file and enable it:

```yaml
volumes:
  - ./my-apache.conf:/etc/apache2/conf-available/zzz-custom.conf:ro
```

```bash
docker compose exec glpi a2enconf zzz-custom
docker compose exec glpi apachectl graceful
```

---

## Reverse Proxy and HTTPS

The image exposes only HTTP on port 80. For production, place it behind a reverse proxy with TLS termination.

### Nginx

```nginx
server {
    listen 443 ssl;
    server_name glpi.example.com;

    ssl_certificate     /etc/ssl/certs/glpi.crt;
    ssl_certificate_key /etc/ssl/private/glpi.key;

    location / {
        proxy_pass http://glpi:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### Traefik

```yaml
services:
  glpi:
    image: "glpi/glpi:latest"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.glpi.rule=Host(`glpi.example.com`)"
      - "traefik.http.routers.glpi.entrypoints=websecure"
      - "traefik.http.routers.glpi.tls.certresolver=letsencrypt"
      - "traefik.http.services.glpi.loadbalancer.server.port=80"
```

---

## Upgrading GLPI

### Automatic Upgrade

By default (`GLPI_SKIP_AUTOUPDATE=false`), the container automatically runs `database:update` on every startup when it detects a version change. Simply pull the new image and restart:

```bash
docker compose pull glpi
docker compose up -d
```

### Manual Upgrade

If you prefer manual control (`GLPI_SKIP_AUTOUPDATE=true`):

```bash
docker compose exec glpi php bin/console database:update
```

### Before Any Upgrade

Always back up your database and volume first. See [Backup and Restore](#backup-and-restore).

---

## Backup and Restore

### Database Backup

```bash
docker compose exec db mysqldump -u root -p glpi > backup_$(date +%F).sql
```

### Volume Backup

```bash
# If using named volumes
docker run --rm -v glpi_glpi_data:/data -v $(pwd):/backup alpine \
  tar czf /backup/glpi_data_$(date +%F).tar.gz -C /data .

# If using bind mounts
tar czf glpi_data_$(date +%F).tar.gz ./glpi_data/
```

### Restore

```bash
# Database
docker compose exec -T db mysql -u root -p glpi < backup_2025-01-01.sql

# Volume (named)
docker run --rm -v glpi_glpi_data:/data -v $(pwd):/backup alpine \
  sh -c "cd /data && tar xzf /backup/glpi_data_2025-01-01.tar.gz"
```

---

## Security Considerations

### Container Execution

- All processes run as non-root user `www-data` (UID 33)
- Apache binds to port 80 using Linux capabilities (`setcap`), not root privileges
- PHP uses production configuration by default

### Credentials

- Store database credentials in a `.env` file (not in `docker-compose.yml`)
- Ensure `.env` is in your `.gitignore`
- Change the default GLPI admin password (`glpi/glpi`) immediately after installation

### Network

- The container exposes only port 80 (HTTP)
- Use a reverse proxy for HTTPS (see [Reverse Proxy and HTTPS](#reverse-proxy-and-https))
- In Docker Compose, define isolated networks to limit service communication:

```yaml
networks:
  frontend:
  backend:

services:
  glpi:
    networks: [frontend, backend]
  db:
    networks: [backend]
```

### Supported Database Engines

| Engine | Tested Versions |
|:-------|:----------------|
| MySQL | 5.7, 8.0, 8.4 |
| MariaDB | 10.4 — 11.8 |
| Percona | 5.7, 8.0, 8.4 |

---

## Horizontal Scaling

For high-availability deployments, separate web and cron workloads:

```yaml
services:
  glpi-web:
    image: "glpi/glpi:latest"
    environment:
      GLPI_CRONTAB_ENABLED: 0    # Web-only, no cron
    ports:
      - "80:80"
    deploy:
      replicas: 3

  glpi-cron:
    image: "glpi/glpi:latest"
    environment:
      GLPI_CRONTAB_ENABLED: 1    # Cron-only, no ports
    # No ports exposed
```

This prevents duplicate cron execution across replicas. Only one instance should run background tasks.

---

## Troubleshooting

### Database Connection Fails

1. Check that the database container is running:
   ```bash
   docker compose ps db
   ```

2. Check database logs:
   ```bash
   docker compose logs db
   ```

3. Test connectivity from the GLPI container:
   ```bash
   docker compose exec glpi php -r "\$c = new mysqli('db','glpi','glpi','glpi',3306); echo \$c->connect_error ?: 'OK';"
   ```

The container waits up to **120 seconds** for the database. If it's not ready by then, the container stops.

### Permission Errors

If you see `Directory /var/glpi/... is not writable`:

- **Named volumes:** should work automatically
- **Bind mounts:** fix ownership:
  ```bash
  sudo chown -R 33:33 /path/to/your/glpi_data
  ```

### Checking PHP Settings

```bash
# Specific setting
docker compose exec glpi php -r "echo ini_get('memory_limit');"

# Full phpinfo
docker compose exec glpi php -i

# Loaded extensions
docker compose exec glpi php -m
```

### GLPI Console Commands

The GLPI CLI is available inside the container:

```bash
# Check database status
docker compose exec glpi php bin/console db:check

# Force database update
docker compose exec glpi php bin/console database:update

# List all available commands
docker compose exec glpi php bin/console list
```

### Timezone Support

1. Grant the GLPI user access to the MySQL timezone table:
   ```bash
   docker exec -it <db_container> mysql -u root -p \
     -e "GRANT SELECT ON mysql.time_zone_name TO 'glpi'@'%'; FLUSH PRIVILEGES;"
   ```

2. Enable timezones in GLPI:
   ```bash
   docker compose exec glpi php bin/console database:enable_timezones
   ```

### Multi-Architecture

The image is available for `linux/amd64` and `linux/arm64` on both Docker Hub (`glpi/glpi`) and GitHub Container Registry (`ghcr.io/glpi-project/glpi`).
