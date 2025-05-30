output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "private_subnet_ids" {
  description = "List of private app subnet IDs"
  value       = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  value       = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]
}

output "app_subnet_cidrs" {
  description = "List of private app subnet CIDR blocks"
  value       = [var.private_subnet_a_cidr, var.private_subnet_b_cidr]
}

output "db_subnet_cidrs" {
  description = "List of private database subnet CIDR blocks"
  value       = [var.private_db_subnet_a_cidr, var.private_db_subnet_b_cidr]
}

output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

output "s3_endpoint_prefix_list_id" {
  description = "Prefix list ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.prefix_list_id
}