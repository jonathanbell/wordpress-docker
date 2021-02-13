# Let's get this party started!
# See: https://github.com/docker-library/wordpress/blob/ed60fb3b988d10e54b003d2cc881218af29694f9/latest/php8.0/apache/Dockerfile
FROM php:8.0-apache

# Update base packages.
RUN apt-get update

# Ghostscript is required for rendering PDF previews
RUN apt-get install -y --no-install-recommends ghostscript nano; \
    rm -rf /var/lib/apt/lists/*

# Install libs and extentions needed for PHP/Wordpress development.
# See: https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions
RUN set -ex; \
	savedAptMark="$(apt-mark showmanual)"; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		default-mysql-client \
		libfreetype6-dev \
		libjpeg-dev \
		libpng-dev \
		libzip-dev \
		; \
	docker-php-ext-configure gd \
		--with-freetype \
		--with-jpeg \
		; \
	docker-php-ext-install -j "$(nproc)" \
		bcmath \
		exif \
		gd \
		mysqli \
		zip \
		; \
    # Reset apt-mark's "manual" list so that "purge --auto-remove" will remove
    # all build dependencies.
	apt-mark auto '.*' > /dev/null; \
	apt-mark manual $savedAptMark; \
	ldd "$(php -r 'echo ini_get("extension_dir");')"/*.so \
		| awk '/=>/ { print $3 }' \
		| sort -u \
		| xargs -r dpkg-query -S \
		| cut -d: -f1 \
		| sort -u \
		| xargs -rt apt-mark manual; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
	rm -rf /var/lib/apt/lists/*

# PHP.ini settings.
# See: https://secure.php.net/manual/en/opcache.installation.php
RUN set -eux; \
	docker-php-ext-enable opcache; \
	{ \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=2'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# PHP error logging.
# See: https://wordpress.org/support/article/editing-wp-config-php/#configure-error-logging
RUN { \
		echo 'error_reporting = E_ALL'; \
		echo 'display_errors = On'; \
		echo 'display_startup_errors = On'; \
		echo 'log_errors = On'; \
		echo 'display_startup_errors = On'; \
		echo 'error_log = /tmp/php_errors.log'; \
		echo 'log_errors_max_len = 1024'; \
		echo 'ignore_repeated_errors = Off'; \
		echo 'ignore_repeated_source = Off'; \
		echo 'html_errors = On'; \
	} > /usr/local/etc/php/conf.d/error-logging.ini

# Apache setup.
RUN set -eux
# Replace all instances of "%h" with "%a" in LogFormat.
# See: https://github.com/docker-library/wordpress/issues/383#issuecomment-507886512
RUN find /etc/apache2 -type f -name '*.conf' -exec sed -ri 's/([[:space:]]*LogFormat[[:space:]]+"[^"]*)%h([^"]*")/\1%a\2/g' '{}' +
# DocumentRoot / SSL
RUN sed -ri -e 's!/tmp!${APACHE_LOG_DIR}!g' /etc/apache2/apache2.conf \
	&& sed -ri -e 's!/tmp!${APACHE_LOG_DIR}!g' /etc/apache2/conf-available/*.conf \
	&& sed -ri -e 's!/tmp!${APACHE_LOG_DIR}!g' /etc/apache2/conf-enabled/*.conf \
	&& sed -ri -e 's!/tmp!${APACHE_LOG_DIR}!g' /etc/apache2/sites-available/*.conf \
	&& sed -ri -e 's!/tmp!${APACHE_LOG_DIR}!g' /etc/apache2/sites-enabled/*.conf

# Apache modules and SSL enable.
COPY ./docker/certs/server.crt /etc/apache2/ssl/server.crt
COPY ./docker/certs/server.key /etc/apache2/ssl/server.key
COPY ./docker/wordpress.conf /etc/apache2/sites-enabled/wordpress.conf
RUN a2enmod rewrite expires headers ssl

RUN service apache2 restart

# Setp for MySQL initialize script.
RUN mkdir -p /data/application

# Create a user and give them basic permissions for web server stuff
ARG uid
RUN mkdir -p /home/devuser \
    && useradd -G www-data,root -u 1000 -d /home/devuser devuser \
    && chown -R devuser:devuser /home/devuser
