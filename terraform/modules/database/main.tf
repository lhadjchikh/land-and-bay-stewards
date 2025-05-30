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

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres" {
  allocated_storage      = var.db_allocated_storage
  storage_type           = "gp3"
  engine                 = "postgres"
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  name                   = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.postgres.name
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.db_security_group_id]
  skip_final_snapshot    = false
  final_snapshot_identifier = "${var.prefix}-final-snapshot"
  deletion_protection    = true
  multi_az               = false
  backup_retention_period = var.db_backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  performance_insights_enabled = false
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.rds.arn
  monitoring_interval   = 0
  publicly_accessible   = false
  
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
      which psql || (apt-get update && apt-get install -y postgresql-client)
      
      # Sleep to allow RDS to fully initialize
      sleep 30
      
      # Create a SQL script file for better escaping and readability
      cat > /tmp/db_setup.sql << 'SQLEOF'
      -- Enable PostGIS extension
      CREATE EXTENSION IF NOT EXISTS postgis;

      -- Create application user if it doesn't exist
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${var.app_db_username}') THEN
          CREATE USER ${var.app_db_username} WITH PASSWORD '${var.app_db_password}';
        END IF;
      END
      $$;
      
      -- Grant basic connect privileges
      GRANT CONNECT ON DATABASE ${var.db_name} TO ${var.app_db_username};
      
      -- Grant schema usage
      GRANT USAGE ON SCHEMA public TO ${var.app_db_username};
      
      -- Grant table privileges
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${var.app_db_username};
      
      -- Grant sequence privileges
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO ${var.app_db_username};
      
      -- Set default privileges for future tables and sequences
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${var.app_db_username};
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO ${var.app_db_username};
      SQLEOF
      
      # Execute the SQL script
      PGPASSWORD=${var.db_password} psql -h ${aws_db_instance.postgres.address} -U ${var.db_username} -d ${var.db_name} -f /tmp/db_setup.sql
      
      # Remove the temporary SQL file
      rm /tmp/db_setup.sql
    EOT
  }
}