#!/bin/bash
set -e

# Wait for database to be ready
echo "Waiting for database..."
python -c "
import time
import psycopg
import os
import sys

print('Attempting database connection...')
database_url = os.environ.get('DATABASE_URL', '')
if not database_url:
    print('ERROR: DATABASE_URL environment variable is not set')
    sys.exit(1)

# Ensure the URL starts with postgresql:// for psycopg
if database_url.startswith('postgis://'):
    database_url = database_url.replace('postgis://', 'postgresql://', 1)

# Maximum wait time: 60 seconds
max_attempts = 60
attempt = 0

while attempt < max_attempts:
    try:
        print(f'Connection attempt {attempt + 1}/{max_attempts}...')
        conn = psycopg.connect(database_url)
        conn.close()
        print('Successfully connected to database!')
        break
    except psycopg.OperationalError as e:
        attempt += 1
        if attempt >= max_attempts:
            print(f'ERROR: Could not connect to database after {max_attempts} attempts')
            print(f'Last error: {e}')
            sys.exit(1)
        print(f'Database not ready, waiting 1 second... (Error: {e})')
        time.sleep(1)
"
echo "Database is ready!"

# Apply database migrations
echo "Applying migrations..."
python manage.py migrate --noinput

# Collect static files
echo "Collecting static files..."
python manage.py collectstatic --noinput

# Start the application
echo "Starting application..."
exec "$@"
