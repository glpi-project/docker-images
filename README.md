# GLPI Docker Images

![GLPI on docker illustration](https://raw.githubusercontent.com/glpi-project/docker-images/refs/heads/main/docs/illustration.png)

[GLPI](https://glpi-project.org) is a free and open source Asset and IT Management Software package, Data center management, ITIL Service Desk, licenses tracking and software auditing.

A few links:

- [Report an issue](https://github.com/glpi-project/glpi/issues/new?template=bug_report.yml)
- [Documentation](https://glpi-project.org/documentation/)


This repository contains build files for docker images available in [Github Container Registry](https://github.com/orgs/glpi-project/packages?ecosystem=container) and [Docker hub](https://hub.docker.com/r/glpi/glpi).

## How to use this image

### via [docker compose](https://github.com/docker/compose)

**docker-compose.yml**
```yaml
services:
  glpi:
    image: "glpi/glpi:latest"
    restart: "unless-stopped"
    volumes:
      - "./storage/glpi:/var/glpi:rw"
    env_file: glpi.env
    depends_on:
      db:
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
      retries: 55
    expose:
      - "3306"
```

And an .env file:

**glpi.env**
```env
GLPI_DB_HOST=db
GLPI_DB_PORT=3306
GLPI_DB_NAME=glpi
GLPI_DB_USER=glpi
GLPI_DB_PASSWORD=glpi
```

Then launch it with:

```bash
docker-compose up -d
```

Once the containers are running, you can access GLPI at `http://localhost` and follow the installation instructions.
At the time of database creation, you can use the following credentials:

- Hostname: `db`
- Database: `glpi`
- User: `glpi`
- Password: `glpi`

### Volumes

By default, the `glpi/glpi` image provides a volume containing its `config`, `marketplace` and `files` directories.
For GLPI 10.0.x version the marketplace directory is not declared in the volume as the path differs. You may want to create a manual volume for the path `/var/www/glpi/marketplace` if you plan to use it.
