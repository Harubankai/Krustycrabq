#!/bin/sh
set -e

# Run database migrations
php artisan migrate --force || true

# Seed the admin user (if not already seeded)
php artisan db:seed --force || true

# Start the Laravel development server on the Render-assigned port
exec php artisan serve --host=0.0.0.0 --port=${PORT}
