#!/bin/sh
set -eu

if [ ! -f "/app/phpunit/vendor/autoload.php" ] && [ -f "/app/phpunit/composer.json" ]; then
    echo "\n* Installing \033[32mPHPUnit\033[0m Composer dependencies\n"

    composer install \
        --working-dir="/app/phpunit" \
        --no-interaction \
        --no-progress \
        --prefer-dist
fi

exec "$@"
