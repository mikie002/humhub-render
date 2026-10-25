FROM php:8.3-apache

# --- System libraries required to build the PHP extensions HumHub needs ---
RUN apt-get update && apt-get install -y --no-install-recommends \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libwebp-dev \
        libzip-dev \
        libicu-dev \
        unzip \
    && rm -rf /var/lib/apt/lists/*

# --- PHP extensions ---
# gd (JPEG/PNG/WebP) + intl + zip + pdo_mysql + exif + bcmath are all
#    checked by HumHub's SelfTest / installer requirements screen.
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j"$(nproc)" gd intl zip pdo_mysql exif bcmath \
    && a2enmod rewrite headers expires deflate

# --- PHP settings ---
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

# --- Apache: point the vhost at the HumHub document root and honour .htaccess ---
RUN printf '%s\n' \
    '<VirtualHost *:80>' \
    '    DocumentRoot /var/www/html' \
    '    <Directory /var/www/html>' \
    '        Options -Indexes +FollowSymLinks' \
    '        AllowOverride All' \
    '        Require all granted' \
    '    </Directory>' \
    '    ErrorLog ${APACHE_LOG_DIR}/error.log' \
    '    CustomLog ${APACHE_LOG_DIR}/access.log combined' \
    '</VirtualHost>' \
    > /etc/apache2/sites-available/000-default.conf \
    && sed -ri -e 's!/var/www/html!/var/www/html!g' /etc/apache2/sites-available/000-default.conf

WORKDIR /var/www/html
