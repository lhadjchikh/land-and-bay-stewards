#!/bin/bash
set -e

# This script initializes the database when the PostgreSQL container starts

ADMIN_USER="${DB_USERNAME:-coalition_admin}"
ADMIN_PASS="${DB_PASSWORD:-admin_password}"
APP_USER="${APP_DB_USERNAME:-coalition_app}"
APP_PASS="${APP_DB_PASSWORD:-app_password}"
APP_DB="${DB_NAME:-coalitionbuilder}"

echo "Starting database initialization..."

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${ADMIN_USER}') THEN
            CREATE USER ${ADMIN_USER} WITH PASSWORD '${ADMIN_PASS}';
            ALTER USER ${ADMIN_USER} WITH SUPERUSER;
            RAISE NOTICE 'Created admin user: ${ADMIN_USER}';
        ELSE
            RAISE NOTICE 'Admin user already exists: ${ADMIN_USER}';
        END IF;
    END
    \$\$;

    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${APP_USER}') THEN
            CREATE USER ${APP_USER} WITH PASSWORD '${APP_PASS}';
            RAISE NOTICE 'Created application user: ${APP_USER}';
        ELSE
            RAISE NOTICE 'Application user already exists: ${APP_USER}';
        END IF;
    END
    \$\$;

    GRANT CONNECT ON DATABASE ${APP_DB} TO ${APP_USER};
    GRANT USAGE, CREATE ON SCHEMA public TO ${APP_USER};
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${APP_USER};
    GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO ${APP_USER};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${APP_USER};
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO ${APP_USER};

    CREATE EXTENSION IF NOT EXISTS postgis;
    SELECT 'PostGIS version: ' || PostGIS_version() as postgis_info;
EOSQL

echo "Database initialization completed successfully!"
