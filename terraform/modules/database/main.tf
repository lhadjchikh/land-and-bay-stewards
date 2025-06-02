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
resource "null_resource" "db_setup_auto" {
  count = var.auto_setup_database ? 1 : 0

  depends_on = [aws_db_instance.postgres]

  triggers = {
    db_instance_endpoint = aws_db_instance.postgres.endpoint
    script_hash          = filesha256("${path.root}/db_setup.sh")
  }

  provisioner "local-exec" {
    command = <<-EOT
      echo "🤖 AUTOMATED DATABASE SETUP"
      echo "Running database setup automatically..."
      
      # Check prerequisites
      for cmd in python3 aws psql; do
        if ! command -v $cmd >/dev/null 2>&1; then
          echo "❌ ERROR: $cmd is required but not found"
          exit 1
        fi
      done
      
      # Make script executable and run it
      chmod +x ${path.root}/db_setup.sh
      
      ${path.root}/db_setup.sh \
        --endpoint "${aws_db_instance.postgres.endpoint}" \
        --database "${var.db_name}" \
        --master-user "${local.master_username}" \
        --app-user "${local.app_username}" \
        --prefix "${var.prefix}" \
        --region "${var.aws_region}"
    EOT

    working_dir = path.root
    environment = {
      AWS_DEFAULT_REGION = var.aws_region
    }
  }
}
