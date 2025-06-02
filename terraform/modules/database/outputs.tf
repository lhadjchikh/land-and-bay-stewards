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
  value       = "./db_setup.sh --endpoint ${aws_db_instance.postgres.endpoint} --database ${var.db_name} --master-user ${local.master_username} --app-user ${local.app_username} --prefix ${var.prefix}"
}

output "setup_status" {
  description = "Database setup status"
  value       = var.auto_setup_database ? "Database setup ran automatically" : "Manual database setup required - see manual_setup_command output"
}