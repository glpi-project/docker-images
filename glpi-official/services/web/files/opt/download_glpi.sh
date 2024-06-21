#!/bin/bash

RELEASE_URL=$1

cd ~
if [[ "$RELEASE_URL" == "http"* ]]; then
    curl -L $RELEASE_URL -o glpi.tgz
else
    cp $RELEASE_URL glpi.tgz
fi
tar -xzf glpi.tgz -C /var/www/