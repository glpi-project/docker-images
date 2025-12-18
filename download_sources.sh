#!/bin/bash
set -e -u -o pipefail

# Check for dependencies
command -v curl >/dev/null 2>&1 || { echo >&2 "curl is required but not installed. Aborting."; exit 1; }
command -v tar >/dev/null 2>&1 || { echo >&2 "tar is required but not installed. Aborting."; exit 1; }

VERSION="${1:-latest}"
TARGET_DIR="glpi/sources"

echo "Cleaning target directory $TARGET_DIR..."
rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

if [ "$VERSION" = "latest" ]; then
    command -v jq >/dev/null 2>&1 || { echo >&2 "jq is required but not installed. Aborting."; exit 1; }

    echo "Fetching info for latest version..."
    # Get tag name from latest release
    API_URL="https://api.github.com/repos/glpi-project/glpi/releases/latest"
    TAG_NAME=$(curl -s "$API_URL" | jq -r .tag_name)

    if [ "$TAG_NAME" = "null" ]; then
        echo "Error: Could not determine latest version from GitHub API."
        exit 1
    fi
    echo "Latest version is $TAG_NAME"
    VERSION=$TAG_NAME
fi

# Construct download URL for source code tarball
# We use the archive url pattern: https://github.com/glpi-project/glpi/archive/refs/tags/{TAG}.tar.gz
URL="https://github.com/glpi-project/glpi/archive/refs/tags/${VERSION}.tar.gz"

echo "Downloading GLPI $VERSION sources from $URL..."
curl -L --output glpi-sources.tar.gz "$URL"

echo "Extracting to $TARGET_DIR..."
# Strip 1 component because github archives wrap in a folder like glpi-10.0.10/
tar --extract --ungzip --strip-components=1 --file glpi-sources.tar.gz --directory "$TARGET_DIR"

echo "Cleaning up..."
rm glpi-sources.tar.gz

echo "Success! Sources for $VERSION installed in $TARGET_DIR"
