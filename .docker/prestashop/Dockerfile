# syntax=docker/dockerfile:1

ARG PS_VERSION_TAG=9

FROM prestashop/prestashop:${PS_VERSION_TAG}

ARG HOST_UID=1000
ARG HOST_GID=1000

ENV COMPOSER_HOME=/tmp/.composer

COPY --link --from=mlocati/php-extension-installer \
    /usr/bin/install-php-extensions \
    /usr/local/bin/install-php-extensions

RUN groupmod --gid "${HOST_GID}" www-data \
    && usermod --uid "${HOST_UID}" --gid "${HOST_GID}" www-data \
    && chown -R www-data:www-data /tmp/data-ps/prestashop/

RUN install-php-extensions @composer xdebug

COPY --link --chmod=644 \
    tmp/defines_custom.inc.php \
    /tmp/defines_custom.inc.php

RUN chown -R www-data:www-data /tmp/defines_custom.inc.php

COPY --link --chmod=755 \
    tmp/pre-install-scripts/composer.sh \
    /tmp/pre-install-scripts/composer.sh

COPY --link --chmod=755 \
    tmp/module/ \
    /tmp/module/

COPY --link php/xdebug.ini /usr/local/etc/php/conf.d/zz-xdebug.ini
