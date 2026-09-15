#!/bin/sh
set -eu

if [ ! -f "/app/tooling/vendor/autoload.php" ] && [ -f "/app/tooling/composer.json" ]; then
    echo "\n* Installing \033[32mTooling\033[0m Composer dependencies\n"

    composer install \
        --working-dir="/app/tooling" \
        --no-interaction \
        --no-progress \
        --prefer-dist
fi

exec "$@"
