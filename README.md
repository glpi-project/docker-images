# GLPI Docker Images

This repository contains build files for docker images available in [Github Container Registry](https://github.com/orgs/glpi-project/packages?ecosystem=container).

Apart developments images, we maintain a production image for each GLPI version.
You can use it with the help of the following docker-compose file:

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
- Database: `db`
- User: `glpi`
- Password: `glpi`
