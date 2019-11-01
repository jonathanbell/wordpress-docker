# Use standard Apache 2 with PHP 7.2
FROM php:7.2-apache

# Update base packages
RUN apt-get update

# Install libs needed for PHP/Wordpress development
RUN apt-get install -yq \
    git \
    zip \
    curl \
    sudo \
    nano \
    unzip \
    libicu-dev \
    libbz2-dev \
    libpng-dev \
    libjpeg-dev \
    libmcrypt-dev \
    libreadline-dev \
    libfreetype6-dev \
    g++

# Apache config: DocumentRoot / SSL
RUN sed -ri -e 's!/var/www!/var/www/html!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# mod_rewrite, mod_headers and SSL enable
COPY ./docker/certs/server.crt /etc/apache2/ssl/server.crt
COPY ./docker/certs/server.key /etc/apache2/ssl/server.key
COPY ./docker/wordpress.conf /etc/apache2/sites-enabled/wordpress.conf
RUN a2enmod rewrite headers ssl
RUN service apache2 restart

# Start with the base PHP config and a basic Xdebug configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"; \
    echo "display_errors = On" >> "$PHP_INI_DIR/php.ini"; \
    echo "display_startup_errors = On" >> "$PHP_INI_DIR/php.ini"; \
    echo "error_reporting = E_ALL" >> "$PHP_INI_DIR/php.ini"; \
    echo "xdebug.idekey=PHPSTORM" >> "$PHP_INI_DIR/php.ini"; \
    echo "xdebug.remote_enable=1" >> "$PHP_INI_DIR/php.ini"; \
    echo "xdebug.remote_connect_back=0" >> "$PHP_INI_DIR/php.ini"; \
    echo "xdebug.remote_host=host.docker.internal" >> "$PHP_INI_DIR/php.ini"

#zend_extension=/usr/local/lib/php/extensions/no-debug-non-zts-20170718/xdebug.so

# Install PHP extensions needed for Wordpress
RUN docker-php-ext-install \
    bz2 \
    intl \
    iconv \
    bcmath \
    opcache \
    calendar \
    mbstring \
    mysqli \
    pdo_mysql \
    zip

# Install Composer from base image
#COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Install and configure Xdebug
RUN pecl install xdebug; \
    docker-php-ext-enable xdebug;

# Create a user and give them basic permissions for web server stuff
ARG uid
RUN useradd -G www-data,root -u 1000 -d /home/devuser devuser
RUN mkdir -p /home/devuser/.composer && chown -R devuser:devuser /home/devuser
