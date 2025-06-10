variable "prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "coalition"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "ID of the load balancer security group"
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

variable "health_check_path_api" {
  description = "Path for load balancer health checks on Django backend"
  type        = string
  default     = "/health/"
}

variable "health_check_path_ssr" {
  description = "Path for load balancer health checks on frontend"
  type        = string
  default     = "/health"
}