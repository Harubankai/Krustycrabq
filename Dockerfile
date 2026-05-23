# Stage 1 - Build Frontend
FROM node:20 AS frontend

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build


# Stage 2 - Laravel App
FROM php:8.2-cli

# Install system dependencies + PostgreSQL driver support
RUN apt-get update && apt-get install -y \
    git curl unzip zip \
    sqlite3 libsqlite3-dev \
    libonig-dev libzip-dev \
    libpq-dev \
    && docker-php-ext-install \
        pdo \
        pdo_pgsql \
        pgsql \
        pdo_sqlite \
        mbstring \
        zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy app
COPY . .

# Copy frontend build
COPY --from=frontend /app/public/build ./public/build

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Ensure SQLite folder exists (safe fallback)
RUN mkdir -p database && touch database/database.sqlite

# Clear caches
RUN php artisan config:clear && \
    php artisan route:clear && \
    php artisan view:clear

# Render port
ENV PORT=10000
EXPOSE 10000

# Start Laravel server
CMD php artisan serve --host=0.0.0.0 --port=$PORT
