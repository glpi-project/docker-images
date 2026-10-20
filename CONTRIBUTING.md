# Contributing to GLPI Docker Images

Thank you for your interest in contributing to the GLPI Docker images project!

This guide will help you set up your local development environment to test changes.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed.

## Quick Start

The `glpi` image is built with `docker buildx bake` (see `docker-bake.hcl`). It downloads the sources automatically from
the `GLPI_VERSION` variable. By default, it will download the latest stable version.

### Build Options

**Build with latest stable version:**
```bash
docker buildx bake glpi --load --set glpi.tags=glpi:local
```

**Build with a specific version:**
```bash
GLPI_VERSION=10.0.18 docker buildx bake glpi --load --set glpi.tags=glpi:local
```

**Build with a branch:**
```bash
GLPI_VERSION=11.0/bugfixes docker buildx bake glpi --load --set glpi.tags=glpi:local
```

**Build with a specific commit:**
```bash
GLPI_VERSION=2186bc6bd410d8bcb048637b3c0fb86b7e320c0a docker buildx bake glpi --load --set glpi.tags=glpi:local
```

**Build with a direct URL:**
```bash
GLPI_VERSION=https://github.com/glpi-project/glpi/archive/2186bc6.tar.gz docker buildx bake glpi --load --set glpi.tags=glpi:local
```

### Applying Patches

You can apply patches after the source download using the `GLPI_PATCH_URL` build argument.

**Apply patches (space-separated):**
```bash
GLPI_VERSION=11.0.4 \
GLPI_PATCH_URL="https://example.com/patch1.diff https://example.com/patch2.diff" \
  docker buildx bake glpi --load --set glpi.tags=glpi:local
```

**Using docker-compose with patches:**
```yaml
services:
  glpi:
    build:
      context: ./glpi
      additional_contexts:
        php-scripts: ./githubactions-base/scripts
      args:
        GLPI_VERSION: 11.0.4
        GLPI_PATCH_URL: https://patch-diff.githubusercontent.com/raw/glpi-project/glpi/pull/22381.diff
```

### Run the Test Environment

We provide a `docker-compose.dev.yml` file to build and test the `glpi` container locally:

```bash
docker compose --file docker-compose.dev.yml up --build
```

### Verify

Once the containers are up:
1. Check the logs to see the installation progress:
    ```bash
    docker compose --file docker-compose.dev.yml logs --follow glpi
    ```
2. Wait for the "GLPI installation completed successfully!" message.
3. Access GLPI at [http://localhost:8080](http://localhost:8080).
    - **User:** `glpi`
    - **Password:** `glpi`

### Cleanup

To stop and remove the test containers:
```bash
docker compose --file docker-compose.dev.yml down --volumes
```

## Publishing from a fork

On a fork, the PHP images workflows (`githubactions-php`, `glpi-development-env`) build the images but never push them.
To publish them on your own registry, define these repository variables (and the `GHCR_USERNAME` / `GHCR_ACCESS_TOKEN`
secrets) in your fork:

| Variable | Description | Default |
|:---------|:------------|:--------|
| `PUSH_IMAGES` | Set to `true` to push the images built from the `main` branch | _(not set, no push)_ |
| `REGISTRY` | Registry and namespace of the images (e.g. `ghcr.io/my-user`) | `ghcr.io/glpi-project` |

The same variables can be used locally, e.g. `REGISTRY=ghcr.io/my-user docker buildx bake githubactions-php-8-5`.
