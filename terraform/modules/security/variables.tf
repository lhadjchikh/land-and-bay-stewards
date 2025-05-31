variable "prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "landandbay"
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "allowed_bastion_cidrs" {
  description = "List of CIDR blocks allowed to access the bastion host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "app_subnet_cidrs" {
  description = "List of CIDR blocks for application subnets"
  type        = list(string)
  default     = []
}

variable "database_subnet_cidrs" {
  description = "List of CIDR blocks for database subnets"
  type        = list(string)
  default     = []
}