FROM php:8.0-fpm

ARG XDEBUGIDEKEY
ARG WWWGROUP
ARG user=sail

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
    unzip

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && sync

RUN install-php-extensions gd \
    xdebug \
    curl \
    memcached \
    imap \
    pdo_mysql \
    mbstring \
    xml \
    zip \
    bcmath \
    soap \
    msgpack \
    igbinary \
    redis

RUN apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN pecl channel-update https://pecl.php.net/channel.xml \
    && pecl install swoole

RUN yes | pecl install xdebug

RUN setcap "cap_net_bind_service=+ep" /usr/local/bin/php

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN useradd -m ${user}
RUN usermod -a -G root,www-data ${user}

RUN mkdir -p /home/${user}/.composer && \
    chown -R ${user}:${user} /home/${user}

RUN touch /var/log/xdebug.log
RUN chmod -R ugo+rw /var/log/xdebug.log

COPY start-container /usr/local/bin/start-container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

COPY php.ini /etc/php/8.0/cli/conf.d/99-sail.ini
RUN echo ${XDEBUGIDEKEY} >> /etc/php/8.0/cli/conf.d/99-sail.ini

RUN chmod +x /usr/local/bin/start-container

ENTRYPOINT [ "start-container" ]