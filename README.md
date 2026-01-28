# GLPI Docker Images

[![Release Build](https://github.com/glpi-project/docker-images/actions/workflows/glpi.yml/badge.svg)](https://github.com/glpi-project/docker-images/actions/workflows/glpi.yml)

![GLPI on docker illustration](https://raw.githubusercontent.com/glpi-project/docker-images/refs/heads/main/docs/illustration.png)

[GLPI](https://glpi-project.org) is a free and open source Asset and IT Management Software package, Data center management, ITIL Service Desk, licenses tracking and software auditing.

A few links:

- [Report an issue](https://github.com/glpi-project/glpi/issues/new?template=bug_report.yml)
- [Documentation](https://glpi-project.org/documentation/)
- [Contributing](CONTRIBUTING.md)


This repository contains build files for docker images available in [Github Container Registry](https://github.com/orgs/glpi-project/packages?ecosystem=container) and [Docker hub](https://hub.docker.com/r/glpi/glpi).

## Summary

- [How to use this image](#how-to-use-this-image)
- [Timezones support](#timezones-support)
- [Volumes](#volumes)
- [Custom PHP configuration](#custom-php-configuration)
- [Managing Cron tasks](#managing-cron-tasks)
- [Adding custom Cron tasks](#adding-custom-cron-tasks)

## How to use this image

### via [docker compose](https://github.com/docker/compose)

**docker-compose.yml**
```yaml
name: glpi

services:
  glpi:
    image: "glpi/glpi:latest"
    restart: "unless-stopped"
    volumes:
       # Using a named volume avoids permission issues on host (automatically managed by Docker)
       - glpi_data:/var/glpi
      # For GLPI 10.x, uncomment the following line to create a volume for plugins fetched from the marketplace.
      # - "./storage/glpi_marketplace:/var/www/glpi/marketplace/:rw"
    env_file: .env # Pass environment variables from .env file to the container
    depends_on:
      - db
    ports:
      - "80:80"

  db:
    image: "mysql"
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

And an .env file:

**.env**
```env
GLPI_DB_HOST=db
GLPI_DB_PORT=3306
GLPI_DB_NAME=glpi
GLPI_DB_USER=glpi
GLPI_DB_PASSWORD=glpi
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
If you are building your own GLPI 10.0.x image using the `glpi/Dockerfile` file, you have to specify the marketplace path using the `--build-arg GLPI_MARKETPLACE_DIR=/var/www/glpi/marketplace` option.

You can also mount a volume containing your own custom plugins in `/var/www/glpi/plugins`.

### Custom PHP configuration
The following example sets the memory limit to 256M

1. Create an ini file  
   **custom-config.ini**
   ```ini
   memory_limit = 256M
   ```
2. Update the volumes configuration

   ```yaml
   volumes:
     - "./custom-config.ini:/usr/local/etc/php/conf.d/custom-config.ini:ro"
   ```

3. Apply the changes

   ```bash
   docker compose up -d
   ```

4. Check the configuration by running on the GLPI container:

   ```bash
   docker compose exec glpi sh -c 'php -r "phpinfo();" | grep memory_limit'
   ```

   Or by browsing the GLPI website under `Setup > General > System > Server`.

### Managing Cron tasks

By default, the image includes a background worker that executes GLPI cron tasks every minute. This behavior is controlled by the `GLPI_CRONTAB_ENABLED` environment variable.

This is especially useful for horizontal scaling or Kubernetes deployments, where you might want a dedicated container for cron tasks while disabling it on Web or API nodes to avoid automatic tasks duplication.

| Variable               | Default | Description                                                  |
|:-----------------------|:--------|:-------------------------------------------------------------|
| `GLPI_CRONTAB_ENABLED` | `1`     | Set to `1` to run the cron worker. Set to `0` to disable it. |

### Adding custom Cron tasks

Since the container runs as the non-root `www-data` user, traditional cron is not available. Instead, this image provides a built-in scheduler script that supports interval-based and daily scheduled tasks through supervisord.

See the [custom scheduled jobs documentation](docs/custom-cron-tasks.md) for usage examples.
