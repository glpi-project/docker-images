# Contributing to GLPI Docker Images

Thank you for your interest in contributing to the GLPI Docker images project!

This guide will help you set up your local development environment to test changes.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed.
- [jq](https://jqlang.github.io/jq/download/) (optional, for the download script).

## Setup Development Environment

To verify that the Docker image builds and runs correctly, you need to populate the `./glpi/sources` directory with the GLPI source code.

### 1. Download GLPI Sources

We provide a helper script to automatically fetch and extract the GLPI source code.

**Download the latest stable version ([jq required](https://jqlang.github.io/jq/download/)):**
```bash
./download_sources.sh
```

**Download a specific version (e.g. 10.0.16):**
```bash
./download_sources.sh 10.0.16
```

> **Note:** This script downloads the source code archive from GitHub into `glpi/sources`. This is required for the Docker build process (`Dockerfile` copies content from this directory).

### 2. Run the Test Environment

We provide a `docker-compose.test.yml` file designed to test the `glpi` container.

Run the stack (builds the image and starts GLPI + MariaDB):

```bash
docker compose -f docker-compose.test.yml up --build
```

### 3. Verify

Once the containers are up:
1.  Check the logs to see the installation progress:
    ```bash
    docker compose -f docker-compose.test.yml logs -f glpi
    ```
2.  Wait for the "GLPI installation completed successfully!" message.
3.  Access GLPI at [http://localhost:8080](http://localhost:8080).
    - **User:** `glpi`
    - **Password:** `glpi`

### 4. Cleanup

To stop and remove the test containers:
```bash
docker compose -f docker-compose.test.yml down -v
```
