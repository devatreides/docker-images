FROM php:8.0-fpm

WORKDIR /var/www/html

RUN apt-get update && apt-get install -y \
    gnupg \
    gosu \
    ca-certificates \
    supervisor \
    sqlite3 \
    libcap2-bin \
    python2 \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    wget \
    libpq-dev

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && sync

RUN install-php-extensions gd \
    xdebug \
    memcached \
    imap \
    pdo \
    pgsql \
    pdo_mysql \
    pdo_pgsql \
    zip \
    bcmath \
    soap \
    msgpack \
    pcntl \
    igbinary \
    redis

RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list' \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
    && apt-get update \
    && apt-get install -y postgresql-client-14

RUN echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.log=/var/log/xdebug.log" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=trigger" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && rm -rf /tmp/* /var/tmp/*

RUN apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN setcap "cap_net_bind_service=+ep" /usr/local/bin/php

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN touch /var/log/xdebug.log
RUN chmod -R ugo+rw /var/log/xdebug.log

COPY php.ini /usr/local/etc/php/php.ini

COPY start-container /usr/local/bin/start-container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY supervisor/ /tmp/supervisor/
RUN chmod +x /usr/local/bin/start-container

ENTRYPOINT [ "start-container" ]