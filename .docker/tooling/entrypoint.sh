#!/bin/sh
set -eu

if [ ! -d "/app/tooling/vendor" ] && [ -f "/app/tooling/composer.json" ]; then
    echo "\n* Installing \033[32mTooling\033[0m Composer dependencies\n"

    composer install \
        --working-dir="/app/tooling" \
        --no-interaction \
        --no-progress \
        --prefer-dist
fi

exec "$@"
