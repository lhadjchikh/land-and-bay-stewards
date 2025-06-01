output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.app.name
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.app.arn
}

output "bastion_key_pair_created" {
  description = "Whether the bastion key pair was created"
  value       = length(aws_key_pair.bastion) > 0 ? "Key pair was created" : "No key pair was created (empty public key)"
}

output "bastion_key_pair_name" {
  description = "Name of the bastion key pair if created"
  value       = length(aws_key_pair.bastion) > 0 ? aws_key_pair.bastion[0].key_name : "N/A"
}

output "bastion_public_key_length" {
  description = "Length of the public key provided (for debugging)"
  value       = length(var.bastion_public_key)
  sensitive   = true
}

output "bastion_key_configured" {
  description = "Whether a public key was configured"
  value       = length(var.bastion_public_key) > 0 ? true : false
}