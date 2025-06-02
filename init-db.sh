#!/bin/bash
set -e

# This script is executed when the PostgreSQL container starts
# NOTE: This contains development-only credentials. In production,
# credentials are managed through AWS Secrets Manager as described in DEPLOY_TO_ECS.md and terraform/README.md

echo "Starting database initialization..."

# Create the admin user
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create the admin user (DEVELOPMENT ENVIRONMENT ONLY)
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'landandbay_admin') THEN
            CREATE USER landandbay_admin WITH PASSWORD 'admin_password';
            ALTER USER landandbay_admin WITH SUPERUSER;
            RAISE NOTICE 'Created admin user: landandbay_admin';
        ELSE
            RAISE NOTICE 'Admin user already exists: landandbay_admin';
        END IF;
    END
    \$\$;
    
    -- Create the application user with restricted privileges (DEVELOPMENT ENVIRONMENT ONLY)
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'landandbay_app') THEN
            CREATE USER landandbay_app WITH PASSWORD 'app_password';
            RAISE NOTICE 'Created application user: landandbay_app';
        ELSE
            RAISE NOTICE 'Application user already exists: landandbay_app';
        END IF;
    END
    \$\$;
    
    -- Grant privileges to the application user
    GRANT CONNECT ON DATABASE landandbay TO landandbay_app;
    GRANT USAGE, CREATE ON SCHEMA public TO landandbay_app;
    GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO landandbay_app;
    GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO landandbay_app;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO landandbay_app;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO landandbay_app;
    
    -- Enable PostGIS extension
    CREATE EXTENSION IF NOT EXISTS postgis;
    
    -- Verify PostGIS installation
    SELECT 'PostGIS version: ' || PostGIS_version() as postgis_info;
EOSQL

echo "Database initialization completed successfully!"
