variable "prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "landandbay"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "ID of the application security group"
  type        = string
}

variable "alb_logs_bucket" {
  description = "Name of the S3 bucket for ALB logs"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL"
  type        = string
}

variable "target_group_port" {
  description = "Port for the target group"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/api/campaigns/"
}