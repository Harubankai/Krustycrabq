# Stage 1 - Build Frontend
FROM node:20 AS frontend

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build


# Stage 2 - Laravel App
FROM php:8.2-cli

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl unzip sqlite3 libsqlite3-dev \
    libonig-dev libzip-dev zip \
    && docker-php-ext-install pdo pdo_sqlite mbstring zip

# Install Composer
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy application
COPY . .

# Copy built frontend assets
COPY --from=frontend /app/public/build ./public/build

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Create SQLite DB file (if used)
RUN mkdir -p database && touch database/database.sqlite

# Clear caches
RUN php artisan config:clear && \
    php artisan route:clear && \
    php artisan view:clear

# IMPORTANT: Render uses PORT env variable
ENV PORT=10000

# Expose port
EXPOSE 10000

# Start Laravel server (THIS FIXES YOUR ISSUE)
CMD php artisan serve --host=0.0.0.0 --port=$PORT
