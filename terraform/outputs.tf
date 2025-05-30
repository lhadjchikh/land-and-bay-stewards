output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "load_balancer_dns" {
  value = aws_lb.main.dns_name
}

output "website_url" {
  value = "https://${var.domain_name}"
}

output "database_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "database_name" {
  value = aws_db_instance.postgres.name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "subnets" {
  value = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

output "budget_info" {
  value = "Monthly budget alert of $${aws_budgets_budget.monthly.limit_amount} set with notifications at 70%, 90%, and forecast thresholds to ${var.alert_email}"
}
}