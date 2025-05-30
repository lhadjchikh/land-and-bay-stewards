variable "prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "landandbay"
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "landandbay"
    Environment = "Production"
  }
}

# Database Variables
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "landandbay"
}

# While usernames are not as sensitive as passwords,
# they still should not be hardcoded for production environments
variable "db_username" {
  description = "Database master username (default value only for initial setup)"
  type        = string
  default     = "postgres_admin" # Default value used only for development
}

# Only used for initial setup or when Secrets Manager integration is disabled
# In production environments, this should be managed through Secrets Manager
variable "db_password" {
  description = "Database master password (only used for initial setup, then stored in Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "app_db_username" {
  description = "Application database username with restricted privileges (default value only for initial setup)"
  type        = string
  default     = "app_user" # Default value used only for development
}

# DNS and SSL Variables
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

# Monitoring Variables
variable "alert_email" {
  description = "Email address to receive budget and other alerts"
  type        = string
}

variable "budget_limit_amount" {
  description = "Monthly budget limit amount in USD"
  type        = string
  default     = "30"
}

# Bastion Host Variables
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
