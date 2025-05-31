output "website_url" {
  description = "The URL of the website"
  value       = "https://${var.domain_name}"
}

output "dns_record_name" {
  description = "The name of the DNS record"
  value       = aws_route53_record.app.name
}