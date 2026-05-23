# ---------- Stage 1 – Frontend ----------
FROM node:20 AS frontend

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# ---------- Stage 2 – Laravel + PHP ----------
FROM php:8.2-fpm

# System dependencies + PostgreSQL driver
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

# Ensure SQLite fallback (optional)
RUN mkdir -p database && touch database/database.sqlite

# Ensure writable Laravel cache & storage directories
RUN mkdir -p bootstrap/cache storage && \
    chmod -R 777 bootstrap/cache storage

# Clear Laravel caches (will be regenerated at runtime)
RUN php artisan config:clear && \
    php artisan route:clear && \
    php artisan view:clear

# Generate the application key (required for encrypted sessions, etc.)
RUN php artisan key:generate --ansi

# ---- Render runtime configuration ----
ENV PORT=10000
EXPOSE $PORT

# Add an entrypoint script that runs migrations/seed then starts the server
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]