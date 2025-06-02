output "db_instance_endpoint" {
  description = "The endpoint of the database"
  value       = aws_db_instance.postgres.endpoint
}

output "db_instance_address" {
  description = "The hostname of the database instance"
  value       = aws_db_instance.postgres.address
}

output "db_instance_port" {
  description = "The port of the database"
  value       = aws_db_instance.postgres.port
}

output "db_instance_name" {
  description = "The name of the database"
  value       = aws_db_instance.postgres.db_name
}

output "db_kms_key_arn" {
  description = "The ARN of the KMS key used for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "manual_setup_command" {
  description = "Command for manual database setup"
  value       = "./db_setup.sh --endpoint ${aws_db_instance.postgres.endpoint} --database ${var.db_name} --master-user ${local.master_username} --app-user ${local.app_username} --prefix ${var.prefix} --region ${var.aws_region}"
}

# Additional helpful outputs
output "setup_instructions" {
  description = "Complete setup instructions with all parameters"
  value       = <<-EOT
    
    📋 DATABASE SETUP REQUIRED
    
    Your RDS instance has been created successfully but needs additional setup.
    
    🔧 SETUP COMMAND:
    ./db_setup.sh --endpoint ${aws_db_instance.postgres.endpoint} \
                  --database ${var.db_name} \
                  --master-user ${local.master_username} \
                  --app-user ${local.app_username} \
                  --prefix ${var.prefix} \
                  --region ${data.aws_region.current.name}
    
    📝 WHAT THIS DOES:
    - Enables PostGIS extension
    - Creates application user with secure, URL-safe password
    - Updates AWS Secrets Manager with proper URL encoding
    - Sets up database permissions following least privilege principle
    
    🔍 PREREQUISITES:
    - Python3 (for secure password URL encoding)
    - AWS CLI (properly configured for region: ${data.aws_region.current.name})
    - PostgreSQL client (psql)
    
  EOT
}

output "setup_status" {
  description = "Database setup status and next steps"
  value       = var.auto_setup_database ? "Database setup configured to run automatically" : "Manual database setup required - use manual_setup_command output"
}

# Debug output for troubleshooting
output "database_connection_info" {
  description = "Database connection information for troubleshooting"
  value = {
    endpoint    = aws_db_instance.postgres.endpoint
    address     = aws_db_instance.postgres.address
    port        = aws_db_instance.postgres.port
    database    = aws_db_instance.postgres.db_name
    region      = data.aws_region.current.name
    master_user = local.master_username
    app_user    = local.app_username
  }
  sensitive = true # Hide sensitive information by default
}