FROM php:8.1-fpm

RUN apt-get update && apt-get install -y \
    gnupg \
    gosu \
    ca-certificates \
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
    wget

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions && sync

RUN install-php-extensions gd \
    xdebug \
    imap \
    bcmath \
    msgpack \
    pcntl \
    igbinary

COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

RUN echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.log=/var/log/xdebug.log" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=trigger" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.mode=develop,debug,coverage" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && rm -rf /tmp/* /var/tmp/*

RUN touch /var/log/xdebug.log
RUN chmod -R ugo+rw /var/log/xdebug.log