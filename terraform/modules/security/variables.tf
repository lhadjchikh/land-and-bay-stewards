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