# GLPI Docker Images

[![Release Build](https://github.com/glpi-project/docker-images/actions/workflows/glpi.yml/badge.svg)](https://github.com/glpi-project/docker-images/actions/workflows/glpi.yml)

![GLPI on docker illustration](https://raw.githubusercontent.com/glpi-project/docker-images/refs/heads/main/docs/illustration.png)

[GLPI](https://glpi-project.org) is a free and open source Asset and IT Management Software package, Data center management, ITIL Service Desk, licenses tracking and software auditing.

A few links:

- [Report an issue](https://github.com/glpi-project/glpi/issues/new?template=bug_report.yml)
- [Documentation](https://glpi-project.org/documentation/)
- [Technical Architecture](docs/architecture.md)
- [Contributing](CONTRIBUTING.md)


This repository contains build files for docker images available in [Github Container Registry](https://github.com/orgs/glpi-project/packages?ecosystem=container) and [Docker hub](https://hub.docker.com/r/glpi/glpi).

## Summary

- [Quick Start](#quick-start)
- [Image Architecture](#image-architecture)
- [Environment Variables](#environment-variables)
- [Volumes and Data Persistence](#volumes-and-data-persistence)
- [Timezones Support](#timezones-support)
- [Custom PHP Configuration](#custom-php-configuration)
- [Custom Apache Configuration](#custom-apache-configuration)
- [Managing Cron Tasks](#managing-cron-tasks)
- [Adding Custom Scheduled Jobs](#adding-custom-scheduled-jobs)
- [Reverse Proxy and HTTPS](#reverse-proxy-and-https)
- [Upgrading](#upgrading)
- [Multi-Architecture Support](#multi-architecture-support)
- [Troubleshooting](#troubleshooting)

## Quick Start

### via [docker compose](https://github.com/docker/compose)

**docker-compose.yml**
```yaml
name: glpi

services:
  glpi:
    image: "glpi/glpi:latest"
    restart: "unless-stopped"
    volumes:
       - glpi_data:/var/glpi
    env_file: .env
    depends_on:
      - db
    ports:
      - "80:80"

  db:
    image: "mariadb:11"
    restart: "unless-stopped"
    volumes:
       - db_data:/var/lib/mysql
    environment:
      MYSQL_RANDOM_ROOT_PASSWORD: "yes"
      MYSQL_DATABASE: ${GLPI_DB_NAME}
      MYSQL_USER: ${GLPI_DB_USER}
      MYSQL_PASSWORD: ${GLPI_DB_PASSWORD}

volumes:
   glpi_data:
   db_data:
```

**.env**
```env
GLPI_DB_HOST=db
GLPI_DB_PORT=3306
GLPI_DB_NAME=glpi
GLPI_DB_USER=glpi
GLPI_DB_PASSWORD=change_me_to_a_secure_password
```

Then launch it:

```bash
docker compose up -d
```

Once the containers are running, access GLPI at `http://localhost`. GLPI will automatically install itself on first run.

Default GLPI credentials after auto-install:
- **Username:** `glpi`
- **Password:** `glpi`

> **Important:** Change these default credentials immediately after your first login.

## Image Architecture

### How the Image Works

The GLPI Docker image is built in three stages:

1. **Downloader** — Fetches the GLPI source code from GitHub
2. **Builder** — Installs dependencies (Composer, npm) and compiles the application
3. **Application** — Final runtime image with Apache, PHP, and Supervisor

At container startup, the entrypoint runs the following scripts in order:

| Step | Script | Description |
|:-----|:-------|:------------|
| 1 | `init-volumes-directories.sh` | Creates required directories and checks permissions |
| 2 | `forward-logs.sh` | Tails GLPI logs to container stdout/stderr |
| 3 | `wait-for-db.sh` | Waits up to 120s for the database to become available |
| 4 | `install.sh` | Auto-installs or auto-updates GLPI if enabled |

After the entrypoint completes, **Supervisor** takes over and manages two processes:
- **Apache** — serves the GLPI web application
- **GLPI Cron Worker** — executes background tasks every 60 seconds

### PHP Extensions Included

The image ships with the following PHP extensions pre-installed:

| Extension | Purpose |
|:----------|:--------|
| apcu | In-memory object caching |
| bcmath | Arbitrary precision math |
| bz2 | Bzip2 compression |
| exif | Image metadata reading |
| gd | Image processing (with FreeType and JPEG) |
| intl | Internationalization (ICU) |
| ldap | LDAP/Active Directory authentication |
| mysqli | MySQL/MariaDB database driver |
| opcache | PHP bytecode caching |
| redis | Redis session/cache backend |
| soap | SOAP protocol support (used by some plugins) |
| zip | ZIP archive handling |

### Apache Configuration

- **DocumentRoot:** `/var/www/glpi/public`
- **Module enabled:** `mod_rewrite`
- **Security hardening:** `ServerTokens Prod`, `ServerSignature Off`, `expose_php = off`
- **Bearer tokens:** HTTP Authorization header is preserved for API access

### Security Features

- Container runs as non-root user (`www-data`)
- Apache binds to port 80 via `setcap` (no root required)
- PHP uses `php.ini-production` configuration
- Session cookies are set to `HttpOnly` and `SameSite=Strict`
- PHP version is not exposed in HTTP headers

## Environment Variables

### Database Configuration

| Variable | Required | Description |
|:---------|:---------|:------------|
| `GLPI_DB_HOST` | Yes | Database server hostname |
| `GLPI_DB_PORT` | Yes | Database server port (typically `3306`) |
| `GLPI_DB_NAME` | Yes | Database name |
| `GLPI_DB_USER` | Yes | Database user |
| `GLPI_DB_PASSWORD` | Yes | Database password |

> All five variables must be set for auto-install and auto-update to work. If any is missing, both features are automatically disabled.

### Installation Control

| Variable | Default | Description |
|:---------|:--------|:------------|
| `GLPI_SKIP_AUTOINSTALL` | `false` | Set to `true` to skip automatic database installation on first run |
| `GLPI_SKIP_AUTOUPDATE` | `false` | Set to `true` to skip automatic database updates on container restart |

When auto-install is disabled, the GLPI web wizard will guide you through the installation process manually.

### Cron Control

| Variable | Default | Description |
|:---------|:--------|:------------|
| `GLPI_CRONTAB_ENABLED` | `1` | Set to `0` to disable the background cron worker |

### Path Configuration

These are set automatically and generally do not need to be changed:

| Variable | Default | Description |
|:---------|:--------|:------------|
| `GLPI_CONFIG_DIR` | `/var/glpi/config` | GLPI configuration directory |
| `GLPI_VAR_DIR` | `/var/glpi/files` | GLPI data files directory |
| `GLPI_LOG_DIR` | `/var/glpi/logs` | GLPI log files directory |
| `GLPI_MARKETPLACE_DIR` | `/var/glpi/marketplace` | Plugin marketplace directory |
| `GLPI_INSTALL_MODE` | `DOCKER` | Installation mode identifier |

## Volumes and Data Persistence

The image declares a single volume at `/var/glpi` that contains all persistent data:

```
/var/glpi/
├── config/          # GLPI configuration (config_db.php, etc.)
├── files/           # Application data
│   ├── _cache/      # Application cache
│   ├── _cron/       # Cron task state
│   ├── _dumps/      # Database dumps
│   ├── _graphs/     # Generated graphs
│   ├── _locales/    # Translation files
│   ├── _lock/       # Lock files
│   ├── _pictures/   # Uploaded images
│   ├── _plugins/    # Plugin data
│   ├── _rss/        # RSS cache
│   ├── _sessions/   # PHP session files
│   ├── _tmp/        # Temporary files
│   ├── _uploads/    # User uploads
│   └── _inventories/# Inventory data
├── marketplace/     # Plugins installed from marketplace
└── logs/            # Application logs
```

### Recommended Volume Setup

Use **named volumes** (managed by Docker) to avoid permission issues:

```yaml
volumes:
  - glpi_data:/var/glpi
```

If you prefer **bind mounts**, make sure the host directory is writable by UID 33 (`www-data`):

```bash
mkdir -p ./glpi_data
chown -R 33:33 ./glpi_data
```

```yaml
volumes:
  - ./glpi_data:/var/glpi
```

### Custom Plugins Volume

You can mount your own plugins directory:

```yaml
volumes:
  - ./my_plugins:/var/www/glpi/plugins:ro
```

### GLPI 10.x Marketplace Path

For GLPI 10.0.x, the marketplace uses a different path. You need to:

1. Add a separate volume:
   ```yaml
   volumes:
     - glpi_marketplace:/var/www/glpi/marketplace
   ```
2. If building your own image, use:
   ```bash
   docker build --build-arg GLPI_MARKETPLACE_DIR=/var/www/glpi/marketplace glpi/
   ```

## Timezones Support

To enable timezone support in GLPI:

1. Grant the GLPI database user access to the timezone table:
   ```bash
   docker exec -it <db_container_id> mysql -u root -p \
     -e "GRANT SELECT ON mysql.time_zone_name TO 'glpi'@'%'; FLUSH PRIVILEGES;"
   ```
   > The root password can be found in the database container logs: `docker logs <db_container_id>`

2. Initialize the timezones in the GLPI container:
   ```bash
   docker exec -it <glpi_container_id> php bin/console database:enable_timezones
   ```

## Custom PHP Configuration

Mount a custom `.ini` file to override PHP settings.

**Example: Increase memory limit to 256M**

1. Create `custom-php.ini`:
   ```ini
   memory_limit = 256M
   upload_max_filesize = 50M
   post_max_size = 50M
   max_execution_time = 300
   ```

2. Mount it in your `docker-compose.yml`:
   ```yaml
   volumes:
     - ./custom-php.ini:/usr/local/etc/php/conf.d/custom-php.ini:ro
   ```

3. Restart the container:
   ```bash
   docker compose up -d
   ```

4. Verify:
   ```bash
   docker compose exec glpi php -r "echo ini_get('memory_limit');"
   ```
   Or check from the GLPI web interface under `Setup > General > System > Server`.

### Default PHP Settings

The image uses `php.ini-production` with these additional settings:

| Setting | Value | Description |
|:--------|:------|:------------|
| `session.cookie_httponly` | `on` | Cookies not accessible via JavaScript |
| `session.cookie_samesite` | `Strict` | Cookies only sent to same origin |
| `expose_php` | `off` | PHP version hidden from headers |
| `session.gc_probability` | `1` | Session garbage collection enabled |
| `session.gc_divisor` | `100` | GC runs on ~1% of requests |
| `session.gc_maxlifetime` | `60480` | Session lifetime (~16.8 hours) |

## Custom Apache Configuration

To add custom Apache configuration, mount a `.conf` file:

```yaml
volumes:
  - ./my-apache.conf:/etc/apache2/conf-available/zzz-custom.conf:ro
```

Then enable it:
```bash
docker compose exec glpi a2enconf zzz-custom
docker compose exec glpi apachectl graceful
```

Or build a custom image with your config baked in.

## Managing Cron Tasks

By default, the image includes a background worker that executes GLPI cron tasks every 60 seconds. This is managed by Supervisor.

### Disabling the Cron Worker

Set `GLPI_CRONTAB_ENABLED=0` in your environment to disable it.

This is useful for:
- **Horizontal scaling** — run cron on a dedicated container while web nodes serve requests only
- **Kubernetes deployments** — use a dedicated CronJob resource instead

**Example: Dedicated cron container**
```yaml
services:
  glpi-web:
    image: "glpi/glpi:latest"
    environment:
      GLPI_CRONTAB_ENABLED: 0
    # ... web-only instance

  glpi-cron:
    image: "glpi/glpi:latest"
    environment:
      GLPI_CRONTAB_ENABLED: 1
    # ... cron-only instance, no ports exposed
```

## Adding Custom Scheduled Jobs

Since the container runs as non-root (`www-data`), traditional cron is not available. Instead, use the built-in scheduler script with Supervisor.

The scheduler supports two modes:

| Mode | Behavior |
|:-----|:---------|
| `--interval <seconds>` | Runs immediately, then repeats every N seconds |
| `--daily <HH:MM>` | Waits until the specified time, then repeats daily |

### Options

| Flag | Description |
|:-----|:------------|
| `--interval <seconds>` | Interval between runs |
| `--daily <HH:MM>` | Time of day to run (24h format) |
| `--name <name>` | Name displayed in logs |
| `--no-wait-for-db` | Skip waiting for database availability |

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

Mount it:
```yaml
volumes:
  - ./ldap-sync.conf:/etc/supervisor/conf.d/ldap-sync.conf:ro
```

### Example: Daily Database Backup at 2 AM

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

See the [full scheduler documentation](docs/custom-cron-tasks.md) for more examples.

## Reverse Proxy and HTTPS

The GLPI image exposes only HTTP on port 80. For production use, place it behind a reverse proxy that handles TLS termination.

### Example: Nginx Reverse Proxy

```nginx
server {
    listen 443 ssl;
    server_name glpi.example.com;

    ssl_certificate /etc/ssl/certs/glpi.crt;
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

### Example: Traefik

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

## Upgrading

### Automatic Upgrades

By default, the image will automatically update the GLPI database schema when a new version is deployed. This is controlled by `GLPI_SKIP_AUTOUPDATE`.

To upgrade GLPI:

1. **Backup your data:**
   ```bash
   docker compose exec db mysqldump -u root -p glpi > backup.sql
   ```

2. **Pull the new image:**
   ```bash
   docker compose pull glpi
   ```

3. **Restart the container:**
   ```bash
   docker compose up -d
   ```

The database migration will run automatically on startup.

### Manual Upgrades

If you prefer manual control (`GLPI_SKIP_AUTOUPDATE=true`):

```bash
docker compose exec glpi php bin/console database:update
```

## Multi-Architecture Support

The image is built for both `linux/amd64` and `linux/arm64` platforms. Multi-arch manifests are pushed to both Docker Hub and GitHub Container Registry.

### Available Registries

| Registry | Image |
|:---------|:------|
| Docker Hub | `glpi/glpi` |
| GitHub Container Registry | `ghcr.io/glpi-project/glpi` |

### Tags

| Tag | Description |
|:----|:------------|
| `latest` | Latest stable release |
| `11.0.4` | Specific version |
| `11` | Latest patch for major version 11 |

## Troubleshooting

### Container Logs

GLPI logs are forwarded to Docker's logging system:

```bash
# All logs
docker compose logs glpi

# Follow logs in real time
docker compose logs -f glpi
```

The following GLPI log files are streamed:

| Log File | Stream | Content |
|:---------|:-------|:--------|
| `event.log` | stdout | Application events |
| `cron.log` | stdout | Cron task execution |
| `mail.log` | stdout | Mail operations |
| `php-errors.log` | stderr | PHP errors |
| `sql-errors.log` | stderr | Database errors |
| `mail-errors.log` | stderr | Mail errors |
| `access-errors.log` | stderr | Access errors |

### Database Connection Issues

If GLPI cannot connect to the database:

1. Verify the database container is running:
   ```bash
   docker compose ps db
   ```

2. Check database logs:
   ```bash
   docker compose logs db
   ```

3. Test connectivity manually:
   ```bash
   docker compose exec glpi php -r "\$c = new mysqli('db','glpi','glpi','glpi',3306); echo \$c->connect_error ?: 'OK';"
   ```

The GLPI container waits up to **120 seconds** for the database to become available before giving up.

### Permission Errors

If you see errors like `Directory /var/glpi/... is not writable`:

- **Named volumes:** Docker handles permissions automatically (recommended)
- **Bind mounts:** Ensure the host directory is owned by UID 33 (`www-data`):
  ```bash
  sudo chown -R 33:33 /path/to/your/glpi_data
  ```

### Checking PHP Configuration

```bash
# Check a specific setting
docker compose exec glpi php -r "echo ini_get('memory_limit');"

# Full PHP info
docker compose exec glpi php -i

# List loaded extensions
docker compose exec glpi php -m
```

### Running GLPI Console Commands

The GLPI CLI console is available inside the container:

```bash
# Check database status
docker compose exec glpi php bin/console db:check

# Force a database update
docker compose exec glpi php bin/console database:update

# List available commands
docker compose exec glpi php bin/console list
```

### Supported Database Engines

| Engine | Tested Versions |
|:-------|:----------------|
| MySQL | 5.7, 8.0, 8.4 |
| MariaDB | 10.4 — 11.8 |
| Percona | 5.7, 8.0, 8.4 |
