# Database Module

# KMS key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.prefix}-rds-kms-key"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.prefix}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.prefix}-db-subnet"
  subnet_ids = var.db_subnet_ids

  tags = {
    Name = "${var.prefix}-db-subnet"
  }
}

# Create the master DB secret in Secrets Manager if it doesn't exist
resource "aws_secretsmanager_secret" "db_master" {
  count       = var.use_secrets_manager ? 1 : 0
  name        = "${var.prefix}/database-master"
  description = "Master credentials for the ${var.prefix} database"

  # Add KMS key when available
  # kms_key_id  = var.kms_key_id

  tags = {
    Name = "${var.prefix}-db-master-secret"
  }

  # Handle resource conflict
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# Store initial credentials in the secret
resource "aws_secretsmanager_secret_version" "db_master_initial" {
  count     = var.use_secrets_manager ? 1 : 0
  secret_id = aws_secretsmanager_secret.db_master[0].id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
    host     = "" # Will be updated after DB creation
    port     = "" # Will be updated after DB creation
    dbname   = var.db_name
  })
}

locals {
  # Always use the input variables for initial creation
  # The secret will be updated with actual values after DB creation
  master_username = var.db_username
  master_password = var.db_password

  # Set a default value for app_username if not specified
  app_username = var.app_db_username == "" ? "app_user" : var.app_db_username

  # Extract PostgreSQL major version for parameter group naming
  pg_version = split(".", var.db_engine_version)[0]
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  identifier        = "${var.prefix}-db" # Set a consistent identifier with the project prefix
  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  engine            = "postgres"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  db_name           = var.db_name
  username          = local.master_username
  password          = local.master_password
  # Use the regular parameter group for basic parameters
  # Note: Static parameters are defined in postgres_static but not associated with the instance
  parameter_group_name         = aws_db_parameter_group.postgres.name
  db_subnet_group_name         = aws_db_subnet_group.main.name
  vpc_security_group_ids       = [var.db_security_group_id]
  skip_final_snapshot          = false
  final_snapshot_identifier    = "${var.prefix}-final-snapshot"
  deletion_protection          = true
  multi_az                     = false
  backup_retention_period      = var.db_backup_retention_period
  backup_window                = "03:00-04:00"
  maintenance_window           = "mon:04:00-mon:05:00"
  performance_insights_enabled = false
  storage_encrypted            = true
  kms_key_id                   = aws_kms_key.rds.arn
  monitoring_interval          = 0
  publicly_accessible          = false

  tags = {
    Name = "${var.prefix}-db"
  }
}

# PostgreSQL Parameter Group
# Note: This module separates dynamic and static parameters to prevent apply errors
# - Dynamic parameters (those that can be applied immediately) are defined in this resource
# - Static parameters (requiring restart) are defined in separate resources below
# - After applying changes to static parameters, a manual DB restart is required
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.prefix}-pg-${local.pg_version}"
  family = "postgres${local.pg_version}"

  tags = {
    Name = "${var.prefix}-pg-${local.pg_version}"
  }

  # Use a lifecycle configuration that maintains stability while allowing parameter changes
  lifecycle {
    prevent_destroy = true
  }
}

# Include static parameters directly in the parameter group, but with apply_method="pending-reboot"
# IMPORTANT: Static parameters require a database restart to take effect!
# After applying, you'll need to manually restart the RDS instance or wait for the next maintenance window
resource "aws_db_parameter_group" "postgres_static" {
  name   = "${var.prefix}-pg-${local.pg_version}-static"
  family = "postgres${local.pg_version}"

  # Include static parameters with pending-reboot apply method
  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot" # This is the key setting that makes this work
  }

  tags = {
    Name = "${var.prefix}-pg-${local.pg_version}-static"
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    aws_db_instance.postgres
  ]
}

# DB Setup script (for PostGIS and app user)
resource "null_resource" "db_setup" {
  depends_on = [aws_db_instance.postgres]

  # This will run every time the RDS endpoint changes or when explicitly triggered
  triggers = {
    db_instance_endpoint = aws_db_instance.postgres.endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e  # Exit on any error
      
      echo "Starting database setup for ${aws_db_instance.postgres.endpoint}"
      
      command_exists() {
        command -v "$1" >/dev/null 2>&1
      }
      
      # Install PostgreSQL client based on the system
      if ! command_exists psql; then
        echo "Installing PostgreSQL client..."
        if command_exists apt-get; then
          sudo apt-get update && sudo apt-get install -y postgresql-client
        elif command_exists yum; then
          sudo yum install -y postgresql
        elif command_exists dnf; then
          sudo dnf install -y postgresql
        elif command_exists brew; then
          brew install postgresql
        else
          echo "ERROR: Cannot install PostgreSQL client. Please install psql manually."
          exit 1
        fi
      else
        echo "PostgreSQL client already available"
      fi
      
      # Check if AWS CLI is available and configured
      if ! command_exists aws; then
        echo "ERROR: AWS CLI is not installed or not in PATH"
        exit 1
      fi
      
      # Test AWS CLI access
      if ! aws sts get-caller-identity >/dev/null 2>&1; then
        echo "ERROR: AWS CLI is not properly configured or lacks permissions"
        exit 1
      fi
      
      echo "Waiting for RDS instance to be fully ready..."
      
      # Wait for RDS to be available with retries
      max_attempts=20
      attempt=1
      while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt/$max_attempts: Checking RDS availability..."
        
        # Check if we can connect to the database
        if PGPASSWORD='${local.master_password}' psql -h ${aws_db_instance.postgres.address} -U ${local.master_username} -d ${var.db_name} -c "SELECT 1;" >/dev/null 2>&1; then
          echo "Database is ready!"
          break
        fi
        
        if [ $attempt -eq $max_attempts ]; then
          echo "ERROR: Database did not become available after $max_attempts attempts"
          exit 1
        fi
        
        echo "Database not ready yet, waiting 30 seconds..."
        sleep 30
        attempt=$((attempt + 1))
      done
      
      # Generate a strong random password for the app user
      echo "Generating application user password..."
      app_password=$(openssl rand -base64 48 | tr -dc 'a-zA-Z0-9!@*()_+~.-' | head -c 32)
      
      if [ -z "$app_password" ]; then
        echo "ERROR: Failed to generate password"
        exit 1
      fi
      
      # Create a SQL script file for better escaping and readability
      cat > /tmp/db_setup.sql << 'SQLEOF'
      -- Enable PostGIS extension
      CREATE EXTENSION IF NOT EXISTS postgis;

      -- Create or update application user with the generated password
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${local.app_username}') THEN
          -- Create the user if it doesn't exist
          CREATE USER ${local.app_username} WITH PASSWORD 'PLACEHOLDER_PASSWORD';
        ELSE
          -- Update the password if user already exists
          ALTER USER ${local.app_username} WITH PASSWORD 'PLACEHOLDER_PASSWORD';
        END IF;
      END
      $$;
      
      -- Grant basic connect privileges
      GRANT CONNECT ON DATABASE ${var.db_name} TO ${local.app_username};
      
      -- Grant schema usage
      GRANT USAGE ON SCHEMA public TO ${local.app_username};
      
      -- Grant table privileges
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${local.app_username};
      
      -- Grant sequence privileges
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO ${local.app_username};
      
      -- Set default privileges for future tables and sequences
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${local.app_username};
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO ${local.app_username};
SQLEOF
      
      # Substitute the password in the SQL file (safer than shell variable substitution)
      sed -i "s/PLACEHOLDER_PASSWORD/$app_password/g" /tmp/db_setup.sql
      
      echo "Executing database setup SQL..."
      # Execute the SQL script
      if ! PGPASSWORD='${local.master_password}' psql -h ${aws_db_instance.postgres.address} -U ${local.master_username} -d ${var.db_name} -f /tmp/db_setup.sql; then
        echo "ERROR: Failed to execute database setup SQL"
        rm -f /tmp/db_setup.sql
        exit 1
      fi
      
      echo "Database setup SQL executed successfully"
      
      # Properly URL-encode the password for the connection string
      encoded_password=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$app_password', safe=''))" 2>/dev/null || echo "$app_password")
      
      # Update the App DB Secret in AWS Secrets Manager
      echo "Updating application database secret..."
      if ! aws secretsmanager update-secret \
        --secret-id "${var.prefix}/database-url" \
        --secret-string "{\"url\":\"postgresql://${local.app_username}:$encoded_password@${aws_db_instance.postgres.endpoint}/${var.db_name}\",\"username\":\"${local.app_username}\",\"password\":\"$app_password\",\"host\":\"${aws_db_instance.postgres.address}\",\"port\":\"${aws_db_instance.postgres.port}\",\"dbname\":\"${var.db_name}\"}" >/dev/null; then
        echo "ERROR: Failed to update application database secret"
        rm -f /tmp/db_setup.sql
        exit 1
      fi
      
      echo "Updated app user password in database and synced with Secrets Manager"
      
      # Update the Master DB Secret in AWS Secrets Manager
      echo "Updating master database secret..."
      if aws secretsmanager describe-secret --secret-id "${var.prefix}/database-master" >/dev/null 2>&1; then
        echo "Updating existing master secret..."
        aws secretsmanager update-secret \
          --secret-id "${var.prefix}/database-master" \
          --secret-string "{\"username\":\"${local.master_username}\",\"password\":\"${local.master_password}\",\"host\":\"${aws_db_instance.postgres.address}\",\"port\":\"${aws_db_instance.postgres.port}\",\"dbname\":\"${var.db_name}\"}" >/dev/null
      else
        echo "Creating new master secret..."
        aws secretsmanager create-secret \
          --name "${var.prefix}/database-master" \
          --secret-string "{\"username\":\"${local.master_username}\",\"password\":\"${local.master_password}\",\"host\":\"${aws_db_instance.postgres.address}\",\"port\":\"${aws_db_instance.postgres.port}\",\"dbname\":\"${var.db_name}\"}" >/dev/null
      fi
      
      # Clean up
      rm -f /tmp/db_setup.sql
      unset app_password
      
      echo "Database setup completed successfully!"
    EOT

    # Set working directory and environment
    working_dir = path.module

    # Environment variables for the script
    environment = {
      PGCONNECT_TIMEOUT = "10"
    }
  }

  # Add a local-exec provisioner for cleanup on destroy
  provisioner "local-exec" {
    when    = destroy
    command = "echo 'Database setup resource destroyed - manual cleanup of database users may be required'"
  }
}