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
  value       = aws_db_instance.postgres.name
}

output "db_kms_key_arn" {
  description = "The ARN of the KMS key used for RDS encryption"
  value       = aws_kms_key.rds.arn
}