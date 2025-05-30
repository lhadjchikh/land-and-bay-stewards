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

# Get the master DB password from Secrets Manager if available,
# otherwise generate one securely
data "aws_secretsmanager_secret" "db_master" {
  count = var.use_secrets_manager ? 1 : 0
  name  = "${var.prefix}/database-master"
}

data "aws_secretsmanager_secret_version" "db_master" {
  count     = var.use_secrets_manager ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.db_master[0].id
}

locals {
  # If using Secrets Manager and the secret exists, parse JSON and get credentials
  # Otherwise use the variables or generate secure credentials
  master_credentials = var.use_secrets_manager && length(data.aws_secretsmanager_secret_version.db_master) > 0 ? jsondecode(data.aws_secretsmanager_secret_version.db_master[0].secret_string) : { username = var.db_username, password = var.db_password }

  master_username = local.master_credentials.username
  master_password = local.master_credentials.password

  # Set a default value for app_username if not specified
  app_username = var.app_db_username == "" ? "app_user" : var.app_db_username
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  allocated_storage            = var.db_allocated_storage
  storage_type                 = "gp3"
  engine                       = "postgres"
  engine_version               = var.db_engine_version
  instance_class               = var.db_instance_class
  db_name                      = var.db_name
  username                     = local.master_username
  password                     = local.master_password
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
resource "aws_db_parameter_group" "postgres" {
  name   = "${var.prefix}-pg${split(".", var.db_engine_version)[0]}"
  family = "postgres${split(".", var.db_engine_version)[0]}"

  parameter {
    name  = "shared_preload_libraries"
    value = "postgis"
  }

  tags = {
    Name = "${var.prefix}-pg${split(".", var.db_engine_version)[0]}"
  }
}

# DB Setup script (for PostGIS and app user)
resource "null_resource" "db_setup" {
  depends_on = [aws_db_instance.postgres]

  # This will run every time the RDS endpoint changes (e.g., after creation)
  triggers = {
    db_instance_endpoint = aws_db_instance.postgres.endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Install PostgreSQL client if not already available
      which psql || (apt-get update && apt-get install -y postgresql-client awscli)
      
      # Sleep to allow RDS to fully initialize
      sleep 30
      
      # Get credentials securely from environment or assume role
      # The AWS CLI should be configured with appropriate permissions
      
      # Create a SQL script file for better escaping and readability
      cat > /tmp/db_setup.sql << 'SQLEOF'
      -- Enable PostGIS extension
      CREATE EXTENSION IF NOT EXISTS postgis;

      -- Create application user if it doesn't exist
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${local.app_username}') THEN
          -- Use a randomly generated strong password that will be stored in AWS Secrets Manager
          CREATE USER ${local.app_username} WITH PASSWORD '$${app_password}';
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
      
      # Generate a strong random password for the app user
      app_password=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9!@#$%^&*()_+?><~' | head -c 32)
      
      # Substitute the password in the SQL file
      sed -i "s/\$${app_password}/$app_password/g" /tmp/db_setup.sql
      
      # Get master password and username - either from our local variables or from Secrets Manager
      PGPASSWORD='${local.master_password}' psql -h ${aws_db_instance.postgres.address} -U ${local.master_username} -d ${var.db_name} -f /tmp/db_setup.sql
      
      # Update the App DB Secret in AWS Secrets Manager with the new password
      aws secretsmanager update-secret --secret-id "${var.prefix}/database-url" --secret-string "{\"url\":\"postgis://${local.app_username}:$app_password@${aws_db_instance.postgres.endpoint}/${var.db_name}\",\"username\":\"${local.app_username}\",\"password\":\"$app_password\",\"host\":\"${aws_db_instance.postgres.address}\",\"port\":\"${aws_db_instance.postgres.port}\",\"dbname\":\"${var.db_name}\"}"
      
      # Update the Master DB Secret in AWS Secrets Manager (for rotation purposes)
      aws secretsmanager update-secret --secret-id "${var.prefix}/database-master" --secret-string "{\"username\":\"${local.master_username}\",\"password\":\"${local.master_password}\",\"host\":\"${aws_db_instance.postgres.address}\",\"port\":\"${aws_db_instance.postgres.port}\",\"dbname\":\"${var.db_name}\"}"
      
      # Remove the temporary SQL file and unset the password variable
      rm /tmp/db_setup.sql
      unset app_password
    EOT
  }
}