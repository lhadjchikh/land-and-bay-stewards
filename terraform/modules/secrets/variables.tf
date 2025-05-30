variable "prefix" {
  description = "Prefix to use for resource names"
  type        = string
  default     = "landandbay"
}

variable "app_db_username" {
  description = "Application database username"
  type        = string
}

variable "db_endpoint" {
  description = "Database endpoint"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}