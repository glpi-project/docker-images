# Contributing to GLPI Docker Images

Thank you for your interest in contributing to the GLPI Docker images project!

This guide will help you set up your local development environment to test changes.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed.

## Quick Start

The Dockerfile supports automatic source downloading via the `GLPI_VERSION` build argument.  
By default, it will download the latest stable version.

### Build Options

**Build with latest stable version:**
```bash
docker build --build-arg GLPI_VERSION=latest glpi/
```

**Build with a specific version:**
```bash
docker build --build-arg GLPI_VERSION=10.0.18 glpi/
```

**Build with a branch:**
```bash
docker build --build-arg GLPI_VERSION=11.0/bugfixes glpi/
```

**Build with a specific commit:**
```bash
docker build --build-arg GLPI_VERSION=2186bc6bd410d8bcb048637b3c0fb86b7e320c0a glpi/
```

**Build with a direct URL:**
```bash
docker build --build-arg GLPI_VERSION=https://github.com/glpi-project/glpi/archive/2186bc6.tar.gz glpi/
```

### Applying Patches

You can apply patches after the source download using the `GLPI_PATCH_URL` build argument.

**Apply patches (space-separated):**
```bash
docker build \
  --build-arg GLPI_VERSION=11.0.4 \
  --build-arg "GLPI_PATCH_URL=https://example.com/patch1.diff https://example.com/patch2.diff" \
  glpi/
```

**Using docker-compose with patches:**
```yaml
services:
  glpi:
    build:
      context: ./glpi
      args:
        GLPI_VERSION: 11.0.4
        GLPI_PATCH_URL: https://patch-diff.githubusercontent.com/raw/glpi-project/glpi/pull/22381.diff
```

### Run the Test Environment

We provide a `docker-compose.test.yml` file to test the `glpi` container:

```bash
docker compose -f docker-compose.test.yml up --build
```

### Verify

Once the containers are up:
1. Check the logs to see the installation progress:
    ```bash
    docker compose -f docker-compose.test.yml logs -f glpi
    ```
2. Wait for the "GLPI installation completed successfully!" message.
3. Access GLPI at [http://localhost:8080](http://localhost:8080).
    - **User:** `glpi`
    - **Password:** `glpi`

### Cleanup

To stop and remove the test containers:
```bash
docker compose -f docker-compose.test.yml down -v
```
