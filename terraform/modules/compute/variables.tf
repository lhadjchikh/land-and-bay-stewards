variable "prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "coalition"
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
}

variable "task_cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)"
  type        = number
  default     = 512

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.task_cpu)
    error_message = "Task CPU must be one of: 256, 512, 1024, 2048, 4096."
  }
}

variable "task_memory" {
  description = "Memory for the task in MiB. Must be compatible with CPU value."
  type        = number
  default     = null # When null, will be calculated based on enable_ssr and CPU

  validation {
    condition     = var.task_memory == null || var.task_memory >= 512
    error_message = "Task memory must be at least 512 MiB."
  }
}

# Add locals to calculate appropriate memory based on CPU and SSR settings
locals {
  # Calculate appropriate memory if not specified
  calculated_memory = var.task_memory != null ? var.task_memory : (
    var.enable_ssr ? (
      # For SSR (dual container), use higher memory
      var.task_cpu == 256 ? 1024 :  # 256 CPU -> 1GB
      var.task_cpu == 512 ? 2048 :  # 512 CPU -> 2GB  
      var.task_cpu == 1024 ? 4096 : # 1024 CPU -> 4GB
      var.task_cpu == 2048 ? 8192 : # 2048 CPU -> 8GB
      16384                         # 4096 CPU -> 16GB
      ) : (
      # For API-only (single container), use lower memory
      var.task_cpu == 256 ? 512 :   # 256 CPU -> 512MB
      var.task_cpu == 512 ? 1024 :  # 512 CPU -> 1GB
      var.task_cpu == 1024 ? 2048 : # 1024 CPU -> 2GB
      var.task_cpu == 2048 ? 4096 : # 2048 CPU -> 4GB
      8192                          # 4096 CPU -> 8GB
    )
  )
}

variable "container_port_api" {
  description = "Container port for API"
  type        = number
  default     = 8000
}

variable "container_port_ssr" {
  description = "Container port for SSR"
  type        = number
  default     = 3000
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
  default     = "coalition-bastion"
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

variable "enable_ssr" {
  description = "Enable Server-Side Rendering with Node.js"
  type        = bool
  default     = true
}
