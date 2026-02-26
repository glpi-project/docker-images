# Technical Architecture

This document provides a deep technical reference for the GLPI Docker image internals: build process, runtime behavior, configuration files, process management, and security model.

For usage instructions, see the [README](../README.md).
For contributing and building locally, see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Table of Contents

- [Multi-Stage Build](#multi-stage-build)
- [Runtime Entrypoint](#runtime-entrypoint)
- [Process Management (Supervisor)](#process-management-supervisor)
- [Scheduler System](#scheduler-system)
- [Log Forwarding](#log-forwarding)
- [Apache Configuration](#apache-configuration)
- [PHP Configuration](#php-configuration)
- [Security Model](#security-model)
- [Volume Layout](#volume-layout)
- [Environment Variable Reference](#environment-variable-reference)
- [Build Argument Reference](#build-argument-reference)
- [CI/CD Pipeline](#cicd-pipeline)
- [Supporting Images](#supporting-images)

---

## Multi-Stage Build

The Dockerfile (`glpi/Dockerfile`) uses three stages to minimize the final image size and separate build-time from runtime dependencies.

### Stage 1: Downloader

```
Base: alpine
Purpose: Resolve GLPI version and download source tarball
```

**Version resolution logic:**

| Input | Behavior |
|:------|:---------|
| `latest` | Queries GitHub API (`/repos/glpi-project/glpi/releases/latest`) to resolve the latest stable tag |
| Semver tag (e.g. `11.0.4`) | Downloads `https://github.com/glpi-project/glpi/archive/<tag>.tar.gz` |
| Branch (e.g. `main`, `11.0/bugfixes`) | Same URL pattern — GitHub resolves branches to archives |
| Commit SHA (40 chars) | Same URL pattern — GitHub resolves full or short SHAs |
| `https://...` URL | Downloads directly from the given URL |

**Output:** `/glpi.tar.gz`

### Stage 2: Builder

```
Base: php:cli-alpine (configurable via BUILDER_IMAGE)
Purpose: Install dependencies, compile assets, build GLPI
```

**System packages installed:**
- `bash` — build script execution
- `patch` — optional patching support
- `gettext`, `perl` — locale compilation
- `nodejs`, `npm` — frontend asset building
- `git`, `unzip`, `curl` — Composer dependency resolution

**PHP extensions installed:**
- `intl` (required by GLPI console)

**PHP configuration:**
- `memory_limit = 512M` (build-time only)

**Build process:**

1. Source tarball extracted to `/usr/src/glpi`
2. Ownership set to `www-data:www-data`
3. Optional patches applied (from `GLPI_PATCH_URL`, space-separated URLs)
4. `build_glpi.sh` executed as `www-data` (runs Composer install + npm build)

**Patch application:**
```bash
# Each patch URL is fetched and applied with:
curl --location "${PATCH}" | patch --strip=1
```

### Stage 3: Application

```
Base: php:apache (configurable via APP_IMAGE)
Purpose: Final runtime image
```

**PHP extensions installed via apt + docker-php-ext-install:**

| Extension | System Dependencies | Notes |
|:----------|:-------------------|:------|
| apcu | — | PECL install, `apc.enable=1` |
| bz2 | libbz2-dev | |
| exif | — | |
| gd | libfreetype6-dev, libjpeg-dev, libpng-dev | `--with-freetype --with-jpeg` |
| intl | libicu-dev | |
| ldap | libldap2-dev | `--with-libdir=lib/x86_64-linux-gnu/` |
| mysqli | — | |
| bcmath | — | |
| opcache | — | Skipped on PHP 8.5+ (built-in) |
| redis | — | PECL install |
| soap | libxml2-dev | |
| zip | libzip-dev | |

**System packages installed:**

| Package | Purpose |
|:--------|:--------|
| supervisor | Process management (Apache + cron) |
| libcap2-bin | `setcap` for non-root port binding |
| acl | ACL management for shared volumes |
| default-mysql-client | Database CLI tools |

**Image configuration:**
- PHP production config: `php.ini-production` symlinked
- Apache `setcap cap_net_bind_service=+ep` on `/usr/sbin/apache2`
- All scripts in `/opt/glpi/` set to executable
- GLPI source copied from builder to `/var/www/glpi`
- Volume directory created at `/var/glpi` (owned by `www-data`)

---

## Runtime Entrypoint

**File:** `glpi/files/opt/glpi/entrypoint.sh`

```bash
#!/bin/bash
set -e -u -o pipefail

/opt/glpi/entrypoint/init-volumes-directories.sh
/opt/glpi/entrypoint/forward-logs.sh
/opt/glpi/entrypoint/wait-for-db.sh entrypoint
/opt/glpi/entrypoint/install.sh

exec "$@"
```

All scripts run sequentially. Failure in any script (`set -e`) stops the container.

### init-volumes-directories.sh

Creates the directory tree under `/var/glpi` if directories don't exist:

**Root directories (write-permission checked):**
- `${GLPI_CONFIG_DIR}` → `/var/glpi/config`
- `${GLPI_VAR_DIR}` → `/var/glpi/files`
- `${GLPI_MARKETPLACE_DIR}` → `/var/glpi/marketplace`
- `${GLPI_LOG_DIR}` → `/var/glpi/logs`

**Subdirectories (created under `GLPI_VAR_DIR`):**
```
_cache  _cron  _dumps  _graphs  _locales  _lock
_pictures  _plugins  _rss  _sessions  _tmp  _uploads  _inventories
```

If any root directory is not writable, the script exits with an error message indicating the required UID.

### wait-for-db.sh

Accepts a caller name argument (used in log prefixes).

**Skip condition:** If any of `GLPI_DB_HOST`, `GLPI_DB_PORT`, `GLPI_DB_NAME`, `GLPI_DB_USER`, or `GLPI_DB_PASSWORD` is unset or empty, the script exits successfully without waiting.

**Connection test method:**
```php
$conn = @new mysqli('$GLPI_DB_HOST', '$GLPI_DB_USER', '$GLPI_DB_PASSWORD', '', (int) '$GLPI_DB_PORT');
exit($conn->connect_error ? 1 : 0);
```

**Retry logic:**
- Maximum 120 attempts
- 1 second sleep between attempts
- Exit code 1 on timeout

### install.sh

**Functions:**

| Function | Description |
|:---------|:------------|
| `Install_GLPI()` | Runs `bin/console database:install` with DB credentials from env vars |
| `Update_GLPI()` | Runs `bin/console database:update` |
| `GLPI_Installed()` | Checks for `config_db.php` existence and runs `bin/console db:check` |

**GLPI db:check exit codes:**

| Code | Meaning | Treated as |
|:-----|:--------|:-----------|
| 0 | Everything OK | Installed |
| 1-4 | SQL diff warnings (non-critical) | Installed |
| 5 | Database connection error | Not installed |
| 6 | Version not found | Not installed |
| 7 | No tables found | Not installed |

**Decision flow:**

```
IF database config incomplete:
    → Force GLPI_SKIP_AUTOINSTALL=true and GLPI_SKIP_AUTOUPDATE=true

IF GLPI not installed:
    IF GLPI_SKIP_AUTOINSTALL=false:
        → Run Install_GLPI()
        → Display greeting with default credentials (glpi/glpi)

IF GLPI already installed:
    IF GLPI_SKIP_AUTOUPDATE=false:
        → Run Update_GLPI()
        → Display greeting (without credentials)
```

---

## Process Management (Supervisor)

**File:** `glpi/files/etc/supervisor/supervisord.conf`

Supervisor runs as `www-data` in non-daemon mode (`nodaemon=true`), which is required for Docker containers.

### Managed Processes

| Program | Command | Auto-restart | Description |
|:--------|:--------|:-------------|:------------|
| `apache2` | `apache2-foreground` | yes | GLPI web server |
| `glpi-cron` | `/opt/glpi/cron-worker.sh` | yes | Background task worker |

All stdout/stderr is forwarded to `/dev/stdout` and `/dev/stderr` (Docker logging).

### Custom Jobs Extension Point

```ini
[include]
files = /etc/supervisor/conf.d/*.conf
```

Users can mount additional `.conf` files into `/etc/supervisor/conf.d/` to add custom supervised processes.

---

## Scheduler System

**File:** `glpi/files/opt/glpi/scheduler.sh`

Generic scheduling wrapper used by the cron worker and available for custom jobs.

### Modes

**Interval mode:**
```
scheduler.sh --interval <seconds> -- <command> [args...]
```
- Runs the command immediately on start
- Sleeps for `<seconds>` between runs
- Repeats indefinitely

**Daily mode:**
```
scheduler.sh --daily <HH:MM> -- <command> [args...]
```
- Calculates sleep until the target time
- If the target time has passed today, waits until tomorrow
- Runs the command, then repeats daily

### Options

| Flag | Default | Description |
|:-----|:--------|:------------|
| `--interval <seconds>` | — | Interval between runs |
| `--daily <HH:MM>` | — | Time of day to run (24h) |
| `--name <name>` | `""` | Prefix for log messages: `[Name] ...` |
| `--no-wait-for-db` | wait enabled | Skip database availability check before starting |

### Database Waiting

By default, the scheduler calls `wait-for-db.sh scheduler` before entering the main loop. This ensures the database is available before executing any GLPI commands.

### Cron Worker

**File:** `glpi/files/opt/glpi/cron-worker.sh`

```bash
# If cron is enabled:
/opt/glpi/scheduler.sh --interval 60 --name "GLPI Cron" -- php /var/www/glpi/front/cron.php

# If cron is disabled (GLPI_CRONTAB_ENABLED=0):
tail -f /dev/null   # keeps supervisord happy
```

---

## Log Forwarding

**File:** `glpi/files/opt/glpi/entrypoint/forward-logs.sh`

Creates GLPI log files if they don't exist, then tails them to container stdout/stderr using `/proc/1/fd/1` (stdout) and `/proc/1/fd/2` (stderr).

| Log File | Destination | Content |
|:---------|:------------|:--------|
| `${GLPI_LOG_DIR}/event.log` | stdout | Application events |
| `${GLPI_LOG_DIR}/cron.log` | stdout | Cron task execution |
| `${GLPI_LOG_DIR}/mail.log` | stdout | Mail operations |
| `${GLPI_LOG_DIR}/php-errors.log` | stderr | PHP errors |
| `${GLPI_LOG_DIR}/sql-errors.log` | stderr | Database errors |
| `${GLPI_LOG_DIR}/mail-errors.log` | stderr | Mail errors |
| `${GLPI_LOG_DIR}/access-errors.log` | stderr | Access errors |

Each `tail -F` runs as a background process. The `-F` flag handles log rotation (follows by name, not inode).

---

## Apache Configuration

### Virtual Host

**File:** `glpi/files/etc/apache2/sites-available/000-default.conf`

```apache
<VirtualHost *:80>
    DocumentRoot /var/www/glpi/public

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined

    <Directory /var/www/glpi/public>
        Require all granted
        RewriteEngine On

        # Preserve HTTP Authorization header (for Bearer tokens / API)
        RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]

        # Redirect all requests to GLPI router, unless file exists
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteRule ^(.*)$ index.php [QSA,L]
    </Directory>
</VirtualHost>
```

### Server Hardening

**File:** `glpi/files/etc/apache2/conf-available/zzz-glpi.conf`

```apache
ServerName localhost
ServerTokens Prod       # Only "Server: Apache" in headers (no version)
ServerSignature Off      # No Apache signature in error pages
```

### Enabled Modules

- `rewrite` — URL routing to `index.php`

---

## PHP Configuration

**File:** `glpi/files/etc/php/conf.d/glpi.ini`

```ini
; Session cookies security
session.cookie_httponly = on
session.cookie_samesite = "Strict"

; Do not expose PHP version
expose_php = off

; PHP session persistence config
session.gc_probability = 1
session.gc_divisor = 100
session.gc_maxlifetime = 60480   ; ~16.8 hours, matches CronTask::cronSession
```

**Base configuration:** `php.ini-production` (symlinked during build)

**APCu configuration:** `apc.enable=1` (written to `docker-php-ext-apcu.ini`)

---

## Security Model

### Non-Root Execution

The container runs entirely as `www-data` (UID 33). Root is only used during the image build phase.

```dockerfile
# Allow Apache to bind to port 80 without root
RUN setcap cap_net_bind_service=+ep /usr/sbin/apache2

# Switch to non-root user
USER www-data
```

### Supervisor runs as www-data

```ini
[supervisord]
user=www-data
```

### HTTP Security Headers

| Mechanism | Configuration | Effect |
|:----------|:-------------|:-------|
| `ServerTokens Prod` | Apache | Only sends `Server: Apache` (no version) |
| `ServerSignature Off` | Apache | No Apache footer in error pages |
| `expose_php = off` | PHP | No `X-Powered-By: PHP/x.x.x` header |
| `session.cookie_httponly = on` | PHP | Session cookies inaccessible to JavaScript |
| `session.cookie_samesite = Strict` | PHP | Cookies only sent to same-origin requests |

### Bearer Token Preservation

The Apache rewrite rule explicitly preserves the `Authorization` header, which PHP-Apache would otherwise strip:

```apache
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
```

This is required for GLPI's REST API (Bearer token authentication).

### File Permissions

- Application source (`/var/www/glpi`): owned by `www-data`, read-only at runtime
- Volume data (`/var/glpi`): owned by `www-data`, read-write
- ACL tools (`acl` package) available for advanced permission management on shared volumes

---

## Volume Layout

```
/var/glpi/                           # Docker VOLUME
├── config/                          # GLPI_CONFIG_DIR
│   └── config_db.php                # Database credentials (created on install)
├── files/                           # GLPI_VAR_DIR
│   ├── _cache/                      # Symfony/GLPI cache
│   ├── _cron/                       # Cron task state files
│   ├── _dumps/                      # Database export dumps
│   ├── _graphs/                     # Generated graph images
│   ├── _locales/                    # Compiled translation files
│   ├── _lock/                       # Application lock files
│   ├── _pictures/                   # Uploaded profile pictures
│   ├── _plugins/                    # Plugin working data
│   ├── _rss/                        # RSS feed cache
│   ├── _sessions/                   # PHP session files
│   ├── _tmp/                        # Temporary files
│   ├── _uploads/                    # User-uploaded documents
│   └── _inventories/                # GLPI Agent inventory files
├── marketplace/                     # GLPI_MARKETPLACE_DIR
│   └── <plugin-name>/              # Plugins installed from GLPI marketplace
└── logs/                            # GLPI_LOG_DIR
    ├── event.log
    ├── cron.log
    ├── mail.log
    ├── php-errors.log
    ├── sql-errors.log
    ├── mail-errors.log
    └── access-errors.log
```

### Application Directory (not a volume)

```
/var/www/glpi/                       # WORKDIR, read-only at runtime
├── public/                          # Apache DocumentRoot
│   └── index.php                    # GLPI front controller
├── bin/
│   └── console                      # GLPI CLI tool
├── front/
│   └── cron.php                     # Cron entry point
├── plugins/                         # Mountable for custom plugins
└── ...                              # GLPI application files
```

---

## Environment Variable Reference

### Required for Auto-Install

| Variable | Example | Description |
|:---------|:--------|:------------|
| `GLPI_DB_HOST` | `db` | Database hostname or IP |
| `GLPI_DB_PORT` | `3306` | Database TCP port |
| `GLPI_DB_NAME` | `glpi` | Database schema name |
| `GLPI_DB_USER` | `glpi` | Database username |
| `GLPI_DB_PASSWORD` | `secret` | Database password |

### Optional Runtime

| Variable | Default | Description |
|:---------|:--------|:------------|
| `GLPI_SKIP_AUTOINSTALL` | `false` | Skip automatic `database:install` on first run |
| `GLPI_SKIP_AUTOUPDATE` | `false` | Skip automatic `database:update` on restart |
| `GLPI_CRONTAB_ENABLED` | `1` | `0` to disable the background cron worker |

### Internal (set by Dockerfile)

| Variable | Default | Description |
|:---------|:--------|:------------|
| `GLPI_INSTALL_MODE` | `DOCKER` | Signals to GLPI that it runs in a container |
| `GLPI_CONFIG_DIR` | `/var/glpi/config` | Configuration directory |
| `GLPI_VAR_DIR` | `/var/glpi/files` | Data files directory |
| `GLPI_LOG_DIR` | `/var/glpi/logs` | Log files directory |
| `GLPI_MARKETPLACE_DIR` | `/var/glpi/marketplace` | Marketplace plugins directory |

---

## Build Argument Reference

| Argument | Default | Description |
|:---------|:--------|:------------|
| `BUILDER_IMAGE` | `php:cli-alpine` | Base image for the builder stage |
| `APP_IMAGE` | `php:apache` | Base image for the application stage |
| `GLPI_VERSION` | `latest` | Version to build (tag, branch, commit, URL, or `latest`) |
| `GLPI_CACHE_KEY` | `""` | Cache-busting key (used by CI to force rebuild) |
| `GLPI_PATCH_URL` | `""` | Space-separated URLs of `.diff`/`.patch` files to apply |
| `GLPI_MARKETPLACE_DIR` | `/var/glpi/marketplace` | Marketplace path. Use `/var/www/glpi/marketplace` for GLPI 10.x |

### Build Examples

```bash
# Latest stable
docker build glpi/

# Specific version
docker build --build-arg GLPI_VERSION=11.0.4 glpi/

# Branch
docker build --build-arg GLPI_VERSION=11.0/bugfixes glpi/

# Commit
docker build --build-arg GLPI_VERSION=2186bc6bd410d8bcb048637b3c0fb86b7e320c0a glpi/

# Direct URL
docker build --build-arg GLPI_VERSION=https://github.com/glpi-project/glpi/archive/2186bc6.tar.gz glpi/

# With patches
docker build \
  --build-arg GLPI_VERSION=11.0.4 \
  --build-arg "GLPI_PATCH_URL=https://example.com/fix1.diff https://example.com/fix2.diff" \
  glpi/

# Custom PHP version
docker build --build-arg APP_IMAGE=php:8.3-apache glpi/

# GLPI 10.x marketplace path
docker build --build-arg GLPI_MARKETPLACE_DIR=/var/www/glpi/marketplace glpi/
```

---

## CI/CD Pipeline

### Main Workflow: `glpi.yml`

**Triggers:**
- `workflow_call` — reusable by the `glpi-project/glpi` repository
- `workflow_dispatch` — manual builds
- `push`/`pull_request` — on changes to `glpi/**`

**Jobs:**

```
prepare → build (matrix: amd64, arm64) → merge-manifests
```

**1. prepare**
- Resolves GLPI version to a commit SHA (for cache-busting)
- Determines tag metadata: `is-latest`, `is-latest-major`
- Validates semver format

**2. build**
- Matrix: `linux/amd64` (ubuntu-24.04), `linux/arm64` (ubuntu-24.04-arm)
- Uses Docker Buildx with GHA cache
- Outputs image digests for manifest merging

**3. merge-manifests**
- Runs only when `push=true`
- Creates multi-arch manifests for Docker Hub and GHCR
- Applies semantic versioning tags:
  - `<version>` (e.g. `11.0.4`)
  - `<major>` (e.g. `11`) — only for latest major
  - `latest` — only for latest release

### Registries

| Registry | Image | Auth Secret |
|:---------|:------|:------------|
| Docker Hub | `glpi/glpi` | `DOCKER_HUB_USERNAME`, `DOCKER_HUB_TOKEN` |
| GHCR | `ghcr.io/glpi-project/glpi` | `GHCR_USERNAME`, `GHCR_ACCESS_TOKEN` |

### Cache Strategy

- Backend: GitHub Actions cache
- Scope: per-branch with fallback to `main`
- Cache key includes `GLPI_CACHE_KEY` (commit SHA) for invalidation

---

## Supporting Images

The repository also builds supporting images for CI/CD and development:

### GitHub Actions Images

| Image | Base | Purpose | PHP Versions |
|:------|:-----|:--------|:-------------|
| `githubactions-php` | php:fpm-alpine | PHP-FPM for tests | 7.4 — 8.5 |
| `githubactions-php-apache` | php:apache | PHP-Apache for tests | 7.4 — 8.5 |
| `githubactions-php-coverage` | php:8.0 | Code coverage with pcov | 8.0 |
| `githubactions-glpi-apache` | glpi image | Pre-built GLPI for e2e | nightly |

### Database Images

| Image | Versions |
|:------|:---------|
| MariaDB | 10.4, 10.5, 10.6, 10.9, 10.10, 10.11, 11.0, 11.4, 11.8 |
| MySQL | 5.7, 8.0, 8.4 |
| Percona | 5.7, 8.0, 8.4 |

Database images include performance-optimized configuration for testing:
- Memory-based datadir (`/dev/shm/mysql`)
- Tuned buffer pool and cache sizes
- Disabled binary logging
- MySQL 8.0+ authentication plugin compatibility

### Service Images

| Image | Purpose |
|:------|:--------|
| `githubactions-redis` | Redis with healthcheck |
| `githubactions-memcached` | Memcached with netcat healthcheck |
| `githubactions-openldap` | OpenLDAP (Alpine) for LDAP testing |
| `githubactions-dovecot` | Dovecot mail server for email testing |

### Development Environment

| Image | Purpose |
|:------|:--------|
| `glpi-development-env` | Full dev environment with xdebug, nodejs, Cypress deps, Python tools |
| `plugin-builder` | Plugin build utilities (Composer, npm, Python, gettext) |

The development environment includes xdebug configured with:
```ini
xdebug.mode=develop,debug
xdebug.start_with_request=trigger
xdebug.client_host=host.docker.internal
```
