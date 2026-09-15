# syntax=docker/dockerfile:1

FROM php:8.5-cli

RUN useradd -m -s /bin/bash nonroot

COPY --link --from=mlocati/php-extension-installer \
    /usr/bin/install-php-extensions \
    /usr/local/bin/install-php-extensions

RUN install-php-extensions @composer

COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

ARG MODULE_NAME

WORKDIR /app/prestashop/modules/${MODULE_NAME}

USER nonroot

ENTRYPOINT ["entrypoint.sh"]
