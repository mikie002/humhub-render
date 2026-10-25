FROM php:8.3-apache

# Install dependencies
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libpng-dev libjpeg-dev libfreetype6-dev \
    libicu-dev libonig-dev libxml2-dev libcurl4-openssl-dev \
    zlib1g-dev libexif-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    pdo_mysql mbstring gd intl zip curl exif bcmath \
    && pecl install apcu \
    && docker-php-ext-enable apcu \
    && a2enmod rewrite headers expires deflate \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# PHP config
RUN { \
        echo "memory_limit = 512M"; \
        echo "upload_max_filesize = 64M"; \
        echo "post_max_size = 64M"; \
        echo "max_execution_time = 300"; \
        echo "date.timezone = UTC"; \
        echo "opcache.enable = 1"; \
        echo "opcache.memory_consumption = 256"; \
        echo "opcache.max_accelerated_files = 20000"; \
        echo "opcache.validate_timestamps = 1"; \
        echo "opcache.revalidate_freq = 0"; \
    } > /usr/local/etc/php/conf.d/99-humhub.ini

# Apache config
RUN printf "%s\n" \
    "<VirtualHost *:80>" \
    "    ServerName localhost" \
    "    DocumentRoot /var/www/html" \
    "    <Directory /var/www/html>" \
    "        Options -Indexes +FollowSymLinks" \
    "        AllowOverride All" \
    "        Require all granted" \
    "    </Directory>" \
    "    ErrorLog ${APACHE_LOG_DIR}/error.log" \
    "    CustomLog ${APACHE_LOG_DIR}/access.log combined" \
    "</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

# Copy HumHub files
COPY . /var/www/html/

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/protected/runtime /var/www/html/uploads /var/www/html/assets 2>/dev/null || true

WORKDIR /var/www/html

EXPOSE 80

CMD ["apache2-foreground"]
