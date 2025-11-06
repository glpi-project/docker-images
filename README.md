# GLPI Docker Images

![GLPI on docker illustration](https://raw.githubusercontent.com/glpi-project/docker-images/refs/heads/main/docs/illustration.png)

[GLPI](https://glpi-project.org) is a free and open source Asset and IT Management Software package, Data center management, ITIL Service Desk, licenses tracking and software auditing.

A few links:

- [Report an issue](https://github.com/glpi-project/glpi/issues/new?template=bug_report.yml)
- [Documentation](https://glpi-project.org/documentation/)

This repository contains build files for docker images available in [Github Container Registry](https://github.com/orgs/glpi-project/packages?ecosystem=container) and [Docker hub](https://hub.docker.com/r/glpi/glpi).

## How to use this image

### via [docker compose](https://github.com/docker/compose)

### docker-compose.yml

```yaml
services:
  glpi:
    build:
      context: ./glpi
      dockerfile: Dockerfile
    restart: "unless-stopped"
    volumes:
      - "./storage/glpi:/var/glpi:rw"
    env_file: .env # Pass environment variables from .env file to the container
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "80:80"

  db:
    image: "mysql"
    restart: "unless-stopped"
    volumes:
       - "./storage/mysql:/var/lib/mysql"
    environment:
      MYSQL_RANDOM_ROOT_PASSWORD: "yes"
      MYSQL_DATABASE: ${GLPI_DB_NAME}
      MYSQL_USER: ${GLPI_DB_USER}
      MYSQL_PASSWORD: ${GLPI_DB_PASSWORD}
    healthcheck:
      test: mysqladmin ping -h 127.0.0.1 -u $$MYSQL_USER --password=$$MYSQL_PASSWORD
      start_period: 5s
      interval: 5s
      timeout: 5s
      retries: 10
    expose:
      - "3306"

  redis:
    image: "redis:7-alpine"
    restart: "unless-stopped"
    command: redis-server --appendonly yes
    volumes:
      - "./storage/redis:/data"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      start_period: 5s
      interval: 5s
      timeout: 5s
      retries: 10
    expose:
      - "6379"
```

And an .env file:

### .env

```env
# Database configuration
GLPI_DB_HOST=db
GLPI_DB_PORT=3306
GLPI_DB_NAME=glpi
GLPI_DB_USER=glpi
GLPI_DB_PASSWORD=glpi

# Redis session configuration
# Set to "true" to use Redis for PHP sessions (recommended for multi-instance deployments)
# Set to "false" to use file-based sessions (default, suitable for single instance)
GLPI_USE_REDIS_SESSION=false
GLPI_REDIS_SESSION_HOST=redis:6379

# PHP configuration - General
PHP_MEMORY_LIMIT=256M
PHP_MAX_EXECUTION_TIME=60
PHP_MAX_INPUT_VARS=5000

# PHP configuration - File uploads
PHP_POST_MAX_SIZE=20M
PHP_UPLOAD_MAX_FILESIZE=20M

# PHP configuration - Security
PHP_SESSION_COOKIE_HTTPONLY=on
PHP_SESSION_COOKIE_SAMESITE=Strict
PHP_EXPOSE_PHP=off

# PHP configuration - OPcache
PHP_OPCACHE_VALIDATE_TIMESTAMPS=1
PHP_OPCACHE_MAX_ACCELERATED_FILES=10000
PHP_OPCACHE_MEMORY_CONSUMPTION=128
PHP_OPCACHE_MAX_WASTED_PERCENTAGE=5
```

Then launch it with:

```bash
docker compose up -d
```

Please note that we setup a random root password for the MySQL database, so you will need to check the logs of the `db` container to find it:

```bash
docker logs <db_container_id>
```

Once the containers are running, you can access GLPI at `http://localhost`
GLPI will automatically install or update itself if needed.

You can disable this behavior by setting the environment variable `GLPI_SKIP_AUTOINSTALL` to `true` in the `.env` file. Same with `GLPI_SKIP_AUTOUPDATE` to disable automatic updates.

If so, when accessing the web interface, installation wizard will ask you to provide the database connection details. You can use the following credentials:

- Hostname: `db`
- Database: `glpi`
- User: `glpi`
- Password: `glpi`

### Timezones support

If you want to initialize the timezones support for GLPI, we need to first GRANT the glpi user to access the `mysql.time_zone` table. So with the docker container running, you can run the following command:

```bash
docker exec -it <db_container_id> mysql -u root -p -e "GRANT SELECT ON mysql.time_zone_name TO 'glpi'@'%';FLUSH PRIVILEGES;"
```

The root password will be the one you found in the logs of the `db` container previously.

Then you can run the following command to initialize the timezones on the GLPI container:

```bash
docker exec -it <glpi_container_id> /var/www/glpi/bin/console database:enable_timezones
```

### Volumes

By default, the `glpi/glpi` image provides a volume containing its `config`, `marketplace` and `files` directories.
For GLPI 10.0.x version the marketplace directory is not declared in the volume as the path differs. You may want to create a manual volume for the path `/var/www/glpi/marketplace` if you plan to use it.
