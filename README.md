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
      - "./storage/glpi/config:/var/www/glpi/config:rw"
      - "./storage/glpi/files:/var/www/glpi/files:rw"
      - "./storage/glpi/plugins:/var/www/glpi/marketplace:rw"
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

By default `glpi/glpi` images doesn't include any volumes.
There is a consensus to declare these:

- `/var/www/glpi/config` where database config and cryptography files are stored
- `/var/www/glpi/files` where GLPI stores its files, such as uploaded documents, images, etc.
- `/var/www/glpi/marketplace` where GLPI stores its plugins