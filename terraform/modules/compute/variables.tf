variable "prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "landandbay"
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the task (increased for multi-container)"
  type        = number
  default     = 512
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8000
}

variable "desired_count" {
  description = "Desired count of tasks"
  type        = number
  default     = 1
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the ECS service"
  type        = list(string)
}

variable "public_subnet_id" {
  description = "Public subnet ID for the bastion host"
  type        = string
}

variable "app_security_group_id" {
  description = "ID of the application security group"
  type        = string
}

variable "bastion_security_group_id" {
  description = "ID of the bastion security group"
  type        = string
}

variable "target_group_arn" {
  description = "ARN of the target group for the ECS service"
  type        = string
}

variable "db_url_secret_arn" {
  description = "ARN of the database URL secret"
  type        = string
}

variable "secret_key_secret_arn" {
  description = "ARN of the Django secret key secret"
  type        = string
}

variable "secrets_kms_key_arn" {
  description = "ARN of the KMS key used for Secrets Manager"
  type        = string
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

  validation {
    condition     = var.bastion_public_key == "" || length(var.bastion_public_key) <= 2048
    error_message = "The bastion_public_key exceeds AWS's limit of 2048 characters."
  }
}

variable "create_new_key_pair" {
  description = "Whether to create a new key pair or use an existing one. Set to false if the key pair already exists in AWS."
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "The domain name for the application (used in SSR environment variables)"
  type        = string
  default     = ""
}

# Variables for SSR target group
variable "api_target_group_arn" {
  description = "ARN of the API target group for the ECS service"
  type        = string
  default     = ""
}

variable "ssr_target_group_arn" {
  description = "ARN of the SSR target group for the ECS service"
  type        = string
  default     = ""
}