# GLPI Docker Images

![GLPI logo](https://raw.githubusercontent.com/glpi-project/glpi/main/public/pics/logos/logo-GLPI-250-black.png)

[GLPI](https://glpi-project.org) is a free and open source Asset and IT Management Software package, Data center management, ITIL Service Desk, licenses tracking and software auditing.

A few links:

- [Report an issue](https://github.com/glpi-project/glpi/issues/new?template=bug_report.yml)
- [Documentation](https://glpi-project.org/documentation/)


This repository contains build files for docker images available in [Github Container Registry](https://github.com/orgs/glpi-project/packages?ecosystem=container) and [Docker hub](https://hub.docker.com/r/glpi/glpi).

## How to use this image

### via [docker compose](https://github.com/docker/compose)

```yaml
services:
  glpi:
    image: "glpi/glpi:latest"
    restart: "unless-stopped"
    volumes:
      - "./storage/glpi:/var/glpi:rw"
    depends_on:
      - "db"
    ports:
      - "80:80"

  db:
    image: "mysql"
    restart: "unless-stopped"
    volumes:
       - "./storage/mysql:/var/lib/mysql"
    environment:
      MYSQL_RANDOM_ROOT_PASSWORD: "yes"
      MYSQL_DATABASE: "glpi"
      MYSQL_USER: "glpi"
      MYSQL_PASSWORD: "glpi"
    expose:
      - "3306"
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
