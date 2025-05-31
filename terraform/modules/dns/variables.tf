variable "route53_zone_id" {
  description = "The Route 53 zone ID to create records in"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the application"
  type        = string
}

variable "alb_dns_name" {
  description = "DNS name of the load balancer"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID of the load balancer"
  type        = string
}