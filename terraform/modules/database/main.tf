# Database Module

# Local values for conditional resources
locals {
  # Extract PostgreSQL major version for parameter group naming
  pg_version = split(".", var.db_engine_version)[0]

  # Parameter group names based on prevent_destroy setting
  parameter_group_name = var.prevent_destroy ? aws_db_parameter_group.postgres[0].name : aws_db_parameter_group.postgres_testing[0].name

  db_setup_script_path = "${path.root}/scripts/db_setup.sh"
}

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
  parameter_group_name         = local.parameter_group_name
  db_subnet_group_name         = aws_db_subnet_group.main.name
  vpc_security_group_ids       = [var.db_security_group_id]
  skip_final_snapshot          = contains(["test", "dev"], var.prefix) ? true : false
  final_snapshot_identifier    = contains(["test", "dev"], var.prefix) ? null : "${var.prefix}-final-snapshot"
  deletion_protection          = contains(["test", "dev"], var.prefix) ? false : true
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

# PostgreSQL Parameter Group - Production (with prevent_destroy)
resource "aws_db_parameter_group" "postgres" {
  count  = var.prevent_destroy ? 1 : 0
  name   = "${var.prefix}-pg-${local.pg_version}-prod"
  family = "postgres${local.pg_version}"

  tags = {
    Name = "${var.prefix}-pg-${local.pg_version}-prod"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# PostgreSQL Parameter Group - Testing (without prevent_destroy)
resource "aws_db_parameter_group" "postgres_testing" {
  count  = var.prevent_destroy ? 0 : 1
  name   = "${var.prefix}-pg-${local.pg_version}-test"
  family = "postgres${local.pg_version}"

  tags = {
    Name = "${var.prefix}-pg-${local.pg_version}-test"
  }
}

# Static Parameter Group - Production (with prevent_destroy)
resource "aws_db_parameter_group" "postgres_static" {
  count  = var.prevent_destroy ? 1 : 0
  name   = "${var.prefix}-pg-${local.pg_version}-static-prod"
  family = "postgres${local.pg_version}"

  # Include static parameters with pending-reboot apply method
  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  tags = {
    Name = "${var.prefix}-pg-${local.pg_version}-static-prod"
  }

  lifecycle {
    prevent_destroy = true
  }

  depends_on = [
    aws_db_instance.postgres
  ]
}

# Static Parameter Group - Testing (without prevent_destroy)
resource "aws_db_parameter_group" "postgres_static_testing" {
  count  = var.prevent_destroy ? 0 : 1
  name   = "${var.prefix}-pg-${local.pg_version}-static-test"
  family = "postgres${local.pg_version}"

  # Include static parameters with pending-reboot apply method
  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  tags = {
    Name = "${var.prefix}-pg-${local.pg_version}-static-test"
  }

  depends_on = [
    aws_db_instance.postgres
  ]
}

# DB Setup script (for PostGIS and app user)
resource "null_resource" "db_setup" {
  count = var.auto_setup_database ? 1 : 0

  depends_on = [aws_db_instance.postgres]

  triggers = {
    # ✅ ESSENTIAL: Re-run when RDS instance endpoint changes
    db_instance_endpoint = aws_db_instance.postgres.endpoint

    # ✅ USEFUL: Re-run when setup script is modified
    script_hash = filesha256(local.db_setup_script_path)

    # ✅ FUNCTIONAL: Re-run when key database parameters change
    db_name      = var.db_name
    app_username = local.app_username

    # ✅ SECURE: Manual trigger for credential rotation
    # Change this value to force re-run after password changes
    credential_rotation_trigger = var.credential_rotation_trigger
  }

  # Prerequisites and validation check
  provisioner "local-exec" {
    command = <<-EOT
      echo "🔧 Preparing database setup..."
      
      # ✅ ADDED: Check if script exists
      if [ ! -f "${local.db_setup_script_path}" ]; then
        echo "❌ ERROR: db_setup.sh script not found in ${path.root}/scripts"
        echo "Please ensure the db_setup.sh script is in the scripts directory"
        echo "Expected location: ${local.db_setup_script_path}"
        exit 1
      fi
      
      # Check script is readable
      if [ ! -r "${local.db_setup_script_path}" ]; then
        echo "❌ ERROR: db_setup.sh script is not readable"
        echo "Please check file permissions for ${local.db_setup_script_path}"
        exit 1
      fi
      
      # Make script executable
      chmod +x "${local.db_setup_script_path}"
      
      # Verify script is now executable
      if [ ! -x "${local.db_setup_script_path}" ]; then
        echo "❌ ERROR: Failed to make db_setup.sh executable"
        echo "Please check file permissions and try manually: chmod +x \"${local.db_setup_script_path}\""
        exit 1
      fi
      
      # Check for Python3 (required by the improved script)
      if ! command -v python3 >/dev/null 2>&1; then
        echo "❌ ERROR: Python3 is required by db_setup.sh but not found"
        echo "Please install Python3 before running Terraform"
        exit 1
      fi
      
      # Check for AWS CLI
      if ! command -v aws >/dev/null 2>&1; then
        echo "❌ ERROR: AWS CLI is required but not found"
        echo "Please install and configure AWS CLI"
        exit 1
      fi
      
      # Check for PostgreSQL client
      if ! command -v psql >/dev/null 2>&1; then
        echo "❌ ERROR: PostgreSQL client (psql) is required but not found"
        echo "Please install PostgreSQL client"
        exit 1
      fi
      
      echo "✅ All prerequisites check passed"
      echo "✅ Script found and made executable: ${local.db_setup_script_path}"
    EOT
  }

  # Run the database setup script
  provisioner "local-exec" {
    command = <<-EOT
      echo "🚀 Database setup triggered by:"
      echo "  - Endpoint: ${aws_db_instance.postgres.endpoint}"
      echo "  - Script hash: ${filesha256(local.db_setup_script_path)}"
      echo "  - Script location: ${local.db_setup_script_path}"
      echo "  - Rotation trigger: ${var.credential_rotation_trigger}"
      echo ""
      
      # Run the script with comprehensive error handling
      if ! "${local.db_setup_script_path}" \
        --endpoint "${aws_db_instance.postgres.endpoint}" \
        --database "${var.db_name}" \
        --master-user "${local.master_username}" \
        --app-user "${local.app_username}" \
        --prefix "${var.prefix}" \
        --region "${var.aws_region}"; then
        
        echo ""
        echo "❌ Database setup failed!"
        echo ""
        echo "🔧 TROUBLESHOOTING:"
        echo "1. Verify script exists: ls -la \"${local.db_setup_script_path}\""
        echo "2. Check script permissions: chmod +x \"${local.db_setup_script_path}\""
        echo "3. Test script manually:"
        echo "   \"${local.db_setup_script_path}\" --endpoint ${aws_db_instance.postgres.endpoint} --database ${var.db_name} --master-user ${local.master_username} --app-user ${local.app_username} --prefix ${var.prefix}"
        echo ""
        exit 1
      fi
      
      echo "✅ Database setup completed successfully via Terraform!"
    EOT

    working_dir = path.root
    environment = {
      AWS_DEFAULT_REGION = var.aws_region
      PGCONNECT_TIMEOUT  = "30"
    }
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<-EOT
      echo "🗑️  Database setup resource destroyed"
      echo "Note: Database and users still exist - manual cleanup may be required"
    EOT
  }
}
