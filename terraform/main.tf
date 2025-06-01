provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.tags
  }
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  prefix     = var.prefix
  aws_region = var.aws_region

  # VPC settings
  create_vpc = var.create_vpc
  vpc_id     = var.vpc_id

  # Subnet settings
  create_public_subnets = var.create_public_subnets
  public_subnet_ids     = var.public_subnet_ids

  create_private_subnets = var.create_private_subnets
  private_subnet_ids     = var.private_subnet_ids

  create_db_subnets = var.create_db_subnets
  db_subnet_ids     = var.db_subnet_ids
}

# Security Module
module "security" {
  source = "./modules/security"

  prefix                = var.prefix
  vpc_id                = module.networking.vpc_id
  allowed_bastion_cidrs = var.allowed_bastion_cidrs
  database_subnet_cidrs = module.networking.db_subnet_cidrs
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  prefix              = var.prefix
  vpc_id              = module.networking.vpc_id
  budget_limit_amount = var.budget_limit_amount
  alert_email         = var.alert_email
}

# Load Balancer Module
module "loadbalancer" {
  source = "./modules/loadbalancer"

  prefix                = var.prefix
  vpc_id                = module.networking.vpc_id
  public_subnet_ids     = module.networking.public_subnet_ids
  app_security_group_id = module.security.app_security_group_id
  alb_logs_bucket       = module.monitoring.alb_logs_bucket
  acm_certificate_arn   = var.acm_certificate_arn
  waf_web_acl_arn       = module.security.waf_web_acl_arn
  health_check_path     = "/api/campaigns/"
}

# Database Module
module "database" {
  source = "./modules/database"

  prefix                     = var.prefix
  db_subnet_ids              = module.networking.private_db_subnet_ids
  db_security_group_id       = module.security.db_security_group_id
  db_allocated_storage       = 20
  db_engine_version          = "16.9"
  db_instance_class          = "db.t4g.micro"
  db_name                    = var.db_name
  db_username                = var.db_username
  db_password                = var.db_password
  app_db_username            = var.app_db_username
  use_secrets_manager        = true
  db_backup_retention_period = 14
}

# Secrets Module
module "secrets" {
  source = "./modules/secrets"

  prefix          = var.prefix
  app_db_username = var.app_db_username
  app_db_password = var.app_db_password
  db_endpoint     = module.database.db_instance_endpoint
  db_name         = module.database.db_instance_name
}

# Compute Module
module "compute" {
  source = "./modules/compute"

  prefix                    = var.prefix
  aws_region                = var.aws_region
  private_subnet_ids        = module.networking.private_subnet_ids
  public_subnet_id          = module.networking.public_subnet_ids[0]
  app_security_group_id     = module.security.app_security_group_id
  bastion_security_group_id = module.security.bastion_security_group_id
  target_group_arn          = module.loadbalancer.target_group_arn
  db_url_secret_arn         = module.secrets.db_url_secret_arn
  secret_key_secret_arn     = module.secrets.secret_key_secret_arn
  secrets_kms_key_arn       = module.secrets.secrets_kms_key_arn
  bastion_key_name          = var.bastion_key_name
  bastion_public_key        = var.bastion_public_key
  container_port            = 8000

  # Make sure load balancer and secrets are created first
  depends_on = [
    module.loadbalancer,
    module.secrets
  ]
}

# DNS Module
module "dns" {
  source = "./modules/dns"

  route53_zone_id = var.route53_zone_id
  domain_name     = var.domain_name
  alb_dns_name    = module.loadbalancer.alb_dns_name
  alb_zone_id     = module.loadbalancer.alb_zone_id
}