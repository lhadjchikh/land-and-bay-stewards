variable "prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "coalition"
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
}

# Variables for creating a new VPC
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

variable "vpc_cidr" {
  description = "CIDR block for the VPC (if create_vpc is true)"
  type        = string
  default     = "10.0.0.0/16"
}

# Variables for public subnets
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

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet in AZ a (if create_public_subnets is true)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet in AZ b (if create_public_subnets is true)"
  type        = string
  default     = "10.0.2.0/24"
}

# Variables for private app subnets
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

variable "private_subnet_a_cidr" {
  description = "CIDR block for private app subnet in AZ a (if create_private_subnets is true)"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for private app subnet in AZ b (if create_private_subnets is true)"
  type        = string
  default     = "10.0.4.0/24"
}

# Variables for private database subnets
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

variable "private_db_subnet_a_cidr" {
  description = "CIDR block for private database subnet in AZ a (if create_db_subnets is true)"
  type        = string
  default     = "10.0.5.0/24"
}

variable "private_db_subnet_b_cidr" {
  description = "CIDR block for private database subnet in AZ b (if create_db_subnets is true)"
  type        = string
  default     = "10.0.6.0/24"
}

# Variables for VPC Endpoints
variable "create_vpc_endpoints" {
  description = "Whether to create VPC endpoints for AWS services (S3, ECR, CloudWatch Logs, Secrets Manager)"
  type        = bool
  default     = true
}

variable "existing_endpoints_security_group_id" {
  description = "ID of an existing security group to use for VPC endpoints (if not creating a new one)"
  type        = string
  default     = ""
}