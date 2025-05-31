output "alb_logs_bucket" {
  description = "Name of the S3 bucket for ALB logs"
  value       = aws_s3_bucket.alb_logs.bucket
}

output "vpc_flow_logs_group" {
  description = "Name of the CloudWatch log group for VPC flow logs"
  value       = aws_cloudwatch_log_group.vpc_flow_log_group.name
}

output "budget_info" {
  description = "Budget configuration summary"
  value       = "Monthly budget alert of $${aws_budgets_budget.monthly.limit_amount} set with notifications at 70%, 90%, and forecast thresholds to ${var.alert_email}"
}