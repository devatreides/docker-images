FROM php:8.1-fpm

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
    pgsql \
    mbstring \
    xml \
    zip \
    bcmath \
    soap \
    msgpack \
    pcntl \
    igbinary \
    redis

RUN pecl channel-update https://pecl.php.net/channel.xml

RUN yes | pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.log=/var/log/xdebug.log" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=trigger" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && pecl clear-cache \
    && rm -rf /tmp/* /var/tmp/*

RUN apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN setcap "cap_net_bind_service=+ep" /usr/local/bin/php

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN chmod 777 /var/log/xdebug.log

RUN useradd -m -u 1001 ${user}
RUN usermod -a -G root,www-data ${user}

RUN mkdir -p /home/${user}/.composer && \
    chown -R ${user}:${user} /home/${user}

RUN touch /var/log/xdebug.log
RUN chmod -R ugo+rw /var/log/xdebug.log

COPY php.ini /usr/local/etc/php/php.ini

COPY start-container /usr/local/bin/start-container
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY supervisor/ /home/${user}/supervisor/
RUN chmod +x /usr/local/bin/start-container

ENTRYPOINT [ "start-container" ]