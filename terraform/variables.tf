variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  # Removed default value for security
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "landandbay"
}

variable "app_db_username" {
  description = "Application database username with restricted privileges"
  type        = string
  # Removed default value for security
}

variable "app_db_password" {
  description = "Application database password"
  type        = string
  sensitive   = true
}

variable "route53_zone_id" {
  description = "The Route 53 zone ID to create records in"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the application"
  type        = string
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate to use for HTTPS"
  type        = string
}

variable "alert_email" {
  description = "Email address to receive budget and other alerts"
  type        = string
}

variable "tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "landandbay"
    Environment = "Production"
  }
}

variable "django_secret_key" {
  description = "Secret key for Django application"
  type        = string
  sensitive   = true
}

variable "allowed_bastion_cidrs" {
  description = "List of CIDR blocks allowed to access the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Replace with your IP address for security
}

variable "bastion_key_name" {
  description = "SSH key pair name for the bastion host"
  type        = string
  default     = "landandbay-bastion" # Create this key pair in AWS console
}