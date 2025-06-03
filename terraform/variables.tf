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

# Networking Variables - for using existing VPC/subnets
variable "create_vpc" {
  description = "Whether to create a new VPC (true) or use an existing one (false)"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "ID of an existing VPC to use (if create_vpc is false)"
  type        = string
  default     = ""
}

variable "create_public_subnets" {
  description = "Whether to create new public subnets (true) or use existing ones (false)"
  type        = bool
  default     = true
}

variable "public_subnet_ids" {
  description = "IDs of existing public subnets to use (if create_public_subnets is false)"
  type        = list(string)
  default     = []
}

variable "create_private_subnets" {
  description = "Whether to create new private app subnets (true) or use existing ones (false)"
  type        = bool
  default     = true
}

variable "private_subnet_ids" {
  description = "IDs of existing private app subnets to use (if create_private_subnets is false)"
  type        = list(string)
  default     = []
}

variable "create_db_subnets" {
  description = "Whether to create new private database subnets (true) or use existing ones (false)"
  type        = bool
  default     = true
}

variable "db_subnet_ids" {
  description = "IDs of existing private database subnets to use (if create_db_subnets is false)"
  type        = list(string)
  default     = []
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

variable "app_db_password" {
  description = "Application database password (only used for initial setup, then stored in Secrets Manager)"
  type        = string
  sensitive   = true
  default     = "" # Will be auto-generated if empty
}

variable "auto_setup_database" {
  description = "Whether to automatically run database setup after RDS creation"
  type        = bool
  default     = false # Default to manual for safety
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
  default     = "landandbay-bastion"
}

variable "bastion_public_key" {
  description = "SSH public key for the bastion host (leave empty to skip key pair creation)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "create_new_key_pair" {
  description = "Whether to create a new key pair or use an existing one. Set to false if the key pair already exists in AWS."
  type        = bool
  default     = false
}

variable "enable_ssr" {
  description = "Enable Server-Side Rendering with Node.js"
  type        = bool
  default     = true
}

variable "health_check_path" {
  description = "Path for API health checks"
  type        = string
  default     = "/api/health/"
}
