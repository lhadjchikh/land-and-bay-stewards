variable "prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "landandbay"
}

variable "aws_region" {
  description = "The AWS region to deploy to"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet in AZ a"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet in AZ b"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for private app subnet in AZ a"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for private app subnet in AZ b"
  type        = string
  default     = "10.0.4.0/24"
}

variable "private_db_subnet_a_cidr" {
  description = "CIDR block for private database subnet in AZ a"
  type        = string
  default     = "10.0.5.0/24"
}

variable "private_db_subnet_b_cidr" {
  description = "CIDR block for private database subnet in AZ b"
  type        = string
  default     = "10.0.6.0/24"
}