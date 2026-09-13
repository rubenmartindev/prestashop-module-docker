#!/bin/sh
set -eu

if [ -f "/var/www/html/modules/$MODULE_NAME/composer.json" ]; then
    echo "\n* Installing \033[32m$MODULE_NAME\033[0m Composer dependencies"

    runuser -u www-data -- composer install \
        --working-dir="/var/www/html/modules/$MODULE_NAME" \
        --no-interaction \
        --prefer-dist
fi
