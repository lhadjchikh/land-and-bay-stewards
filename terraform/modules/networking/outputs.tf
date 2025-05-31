output "vpc_id" {
  description = "The ID of the VPC"
  value       = local.vpc_id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = var.create_vpc ? var.vpc_cidr : local.existing_vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = local.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private app subnet IDs"
  value       = local.private_subnet_ids
}

output "private_db_subnet_ids" {
  description = "List of private database subnet IDs"
  value       = local.private_db_subnet_ids
}

output "app_subnet_cidrs" {
  description = "List of private app subnet CIDR blocks"
  value       = var.create_private_subnets ? [var.private_subnet_a_cidr, var.private_subnet_b_cidr] : []
}

output "db_subnet_cidrs" {
  description = "List of private database subnet CIDR blocks"
  value       = var.create_db_subnets ? [var.private_db_subnet_a_cidr, var.private_db_subnet_b_cidr] : []
}

output "s3_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = length(aws_vpc_endpoint.s3) > 0 ? aws_vpc_endpoint.s3[0].id : null
}

output "s3_endpoint_prefix_list_id" {
  description = "Prefix list ID of the S3 VPC endpoint"
  value       = length(aws_vpc_endpoint.s3) > 0 ? aws_vpc_endpoint.s3[0].prefix_list_id : null
}