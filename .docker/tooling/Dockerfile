# syntax=docker/dockerfile:1

FROM php:8.5-cli

COPY --link --from=mlocati/php-extension-installer \
    /usr/bin/install-php-extensions \
    /usr/local/bin/install-php-extensions

RUN install-php-extensions @composer

WORKDIR /app/tooling

COPY composer.json ./

RUN composer install \
    --no-interaction \
    --prefer-dist

ARG MODULE_NAME

WORKDIR /app/prestashop/modules/${MODULE_NAME}
