# ==========================================
# STAGE 1: Base Image & PHP Extensions
# ==========================================
FROM php:8.3-fpm-alpine AS base

# Install system dependencies & PHP extensions yang dibutuhkan Laravel
RUN apk add --no-cache \
    zip \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    freetype-dev \
    oniguruma-dev \
    $PHPIZE_DEPS \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql mbstring zip gd fileinfo \
    && docker-php-ext-enable fileinfo

WORKDIR /var/www/html

# ==========================================
# STAGE 2: Vendor Builder (Hanya untuk Prod/Stg)
# ==========================================
FROM composer:latest AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
# Jalankan install tanpa dev-dependencies untuk menghemat ukuran
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --prefer-dist

# ==========================================
# STAGE 3: Final Production Image
# ==========================================
FROM base AS production

# Copy kodingan Laravel
COPY . .
# Copy folder vendor dari STAGE 2
COPY --from=vendor /app/vendor ./vendor

# Set hak akses folder storage & bootstrap/cache (Wajib di Laravel)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

USER www-data
EXPOSE 9000
CMD ["php-fpm"]

# ==========================================
# STAGE 4: Local Development Image (Optional)
# ==========================================
FROM base AS development
# Di dev, kita butuh composer utuh untuk instalasi testing library (Pest/PHPUnit)
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
USER root
