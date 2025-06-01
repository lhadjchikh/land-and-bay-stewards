# Network Outputs
output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

# Database Outputs
output "database_endpoint" {
  value = module.database.db_instance_endpoint
}

output "database_name" {
  value = module.database.db_instance_name
}

# Application Outputs
output "ecr_repository_url" {
  value = module.compute.ecr_repository_url
}

output "ecs_cluster_name" {
  value = module.compute.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.compute.ecs_service_name
}

# Load Balancer Outputs
output "load_balancer_dns" {
  value = module.loadbalancer.alb_dns_name
}

# DNS Outputs
output "website_url" {
  value = module.dns.website_url
}

# Bastion Host Outputs
output "bastion_public_ip" {
  value       = module.compute.bastion_public_ip
  description = "Public IP address of the bastion host"
}

output "ssh_tunnel_command" {
  value       = "ssh -i ${var.bastion_key_name}.pem ec2-user@${module.compute.bastion_public_ip} -L 5432:${module.database.db_instance_address}:5432"
  description = "Command to create SSH tunnel for database access"
}

output "pgadmin_connection_info" {
  value       = <<-EOT
    Set up pgAdmin with:
    - Host: localhost
    - Port: 5432
    - Username: ${var.db_username}
    - Database: ${var.db_name}
    
    Important: Connect to SSH tunnel first using the command above
  EOT
  description = "Connection information for pgAdmin"
  sensitive   = true
}

# Monitoring Outputs
output "budget_info" {
  value = module.monitoring.budget_info
}