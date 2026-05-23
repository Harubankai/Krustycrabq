# ---------- Stage 1 – Frontend ----------
FROM node:20 AS frontend

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build


# ---------- Stage 2 – Laravel + PHP ----------
FROM php:8.2-fpm

# System deps + PostgreSQL driver support
RUN apt-get update && apt-get install -y \
    git curl unzip zip \
    sqlite3 libsqlite3-dev \
    libonig-dev libzip-dev \
    libpq-dev \
    && docker-php-ext-install \
        pdo pdo_pgsql mbstring zip

# Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy application code
COPY . .

# Bring in the compiled frontend assets
COPY --from=frontend /app/public/build ./public/build

# Install PHP dependencies (production only)
RUN composer install --no-dev --optimize-autoloader

# Ensure SQLite fallback still works (optional)
RUN mkdir -p database && touch database/database.sqlite

# Laravel cache & storage must be writable
RUN mkdir -p bootstrap/cache storage && \
    chmod -R 777 bootstrap/cache storage

# Clear Laravel caches (so they are regenerated at runtime)
RUN php artisan config:clear && \
    php artisan route:clear && \
    php artisan view:clear

# ---- Render runtime configuration ----
ENV PORT=10000
EXPOSE $PORT

# Start the app – this binds to the correct port and runs in the foreground.
CMD php artisan serve --host=0.0.0.0 --port=$PORT
