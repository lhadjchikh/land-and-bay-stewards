provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.tags
  }
}

# VPC and Networking
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "landandbay-vpc"
  }
}

# Public subnets for ALB
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "landandbay-public-a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "landandbay-public-b"
  }
}

# Private subnets for database and ECS tasks
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = false
  
  tags = {
    Name = "landandbay-private-a"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = false
  
  tags = {
    Name = "landandbay-private-b"
  }
}

# VPC Flow Logs for security monitoring - focus on database subnet for data protection
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_log_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log_group.arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
  
  tags = {
    Name = "landandbay-vpc-flow-logs"
  }
}

# Add S3 VPC endpoint to allow database to access S3 for backup without internet
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_db.id]
  
  tags = {
    Name = "landandbay-s3-endpoint"
  }
}

resource "aws_cloudwatch_log_group" "vpc_flow_log_group" {
  name              = "/vpc/flow-logs"
  retention_in_days = 30  # Reduced retention to save costs
  
  tags = {
    Name = "landandbay-vpc-flow-logs"
  }
}

resource "aws_iam_role" "vpc_flow_log_role" {
  name = "vpc-flow-log-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = {
    Name = "vpc-flow-log-role"
  }
}

resource "aws_iam_role_policy" "vpc_flow_log_policy" {
  name = "vpc-flow-log-policy"
  role = aws_iam_role.vpc_flow_log_role.id
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "landandbay-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "landandbay-public-rt"
  }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Use an alternative to full NAT Gateway
# Note: This approach uses a self-managed NAT instance that is more cost-effective
# Comment out this resource in production if you need to use the more reliable AWS NAT Gateway

# Define a security group for the NAT instance
resource "aws_security_group" "nat_instance" {
  name        = "nat-instance-sg"
  description = "Security group for NAT instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
    description = "Allow all traffic from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "nat-instance-sg"
  }
}

# Use a hybrid approach for private subnets
# Since the database protection is the priority, we'll use an isolated subnet for the database
# with no internet access at all, while allowing the app to have direct internet access

# For database - completely isolated with no internet route
resource "aws_route_table" "private_db" {
  vpc_id = aws_vpc.main.id
  # No route to internet - completely isolated
  
  tags = {
    Name = "landandbay-private-db-rt"
  }
}

# For application - direct access to internet gateway
resource "aws_route_table" "private_app" {
  vpc_id = aws_vpc.main.id
  
  route {
    cidr_block  = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.igw.id
  }
  
  tags = {
    Name = "landandbay-private-app-rt"
  }
}

# Add two more private subnets specifically for the database with no internet access
resource "aws_subnet" "private_db_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.5.0/24"
  availability_zone = "${var.aws_region}a"
  map_public_ip_on_launch = false
  
  tags = {
    Name = "landandbay-private-db-a"
  }
}

resource "aws_subnet" "private_db_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "${var.aws_region}b"
  map_public_ip_on_launch = false
  
  tags = {
    Name = "landandbay-private-db-b"
  }
}

# App subnet associations
resource "aws_route_table_association" "private_app_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_app.id
}

resource "aws_route_table_association" "private_app_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_app.id
}

# DB subnet associations - no internet access
resource "aws_route_table_association" "private_db_a" {
  subnet_id      = aws_subnet.private_db_a.id
  route_table_id = aws_route_table.private_db.id
}

resource "aws_route_table_association" "private_db_b" {
  subnet_id      = aws_subnet.private_db_b.id
  route_table_id = aws_route_table.private_db.id
}

# Security Group
resource "aws_security_group" "app_sg" {
  name        = "landandbay-sg"
  description = "Allow inbound traffic for Land and Bay application"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from internet"
  }

  # Restricted egress rules
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound traffic"
  }
  
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound traffic"
  }
  
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.db_sg.id]
    description = "PostgreSQL access"
  }

  tags = {
    Name = "landandbay-sg"
  }
}

# Bastion host security group
resource "aws_security_group" "bastion_sg" {
  name        = "landandbay-bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_bastion_cidrs
    description = "SSH access from allowed IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "landandbay-bastion-sg"
  }
}

# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "landandbay"
  image_tag_mutability = "IMMUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
  }
  
  encryption_configuration {
    encryption_type = "KMS"
  }
  
  tags = {
    Name = "landandbay"
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "landandbay-cluster"
  
  setting {
    name  = "containerInsights"
    value = "disabled"
  }
  
  tags = {
    Name = "landandbay-cluster"
  }
}

# RDS PostgreSQL with PostGIS
resource "aws_db_subnet_group" "main" {
  name       = "landandbay-db-subnet"
  subnet_ids = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]  # Use isolated DB subnets
  
  tags = {
    Name = "landandbay-db-subnet"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "landandbay-db-sg"
  description = "Allow PostgreSQL inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
    description     = "PostgreSQL from application"
  }
  
  # Allow access from the bastion host
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
    description     = "PostgreSQL from bastion host"
  }

  # Since database is in isolated subnet with no internet access,
  # we need to be careful about what outbound traffic we allow
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.app_sg.id]
    description = "Allow return traffic to the application"
  }
  
  # Allow return traffic to the bastion host
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.bastion_sg.id]
    description = "Allow return traffic to the bastion host"
  }

  tags = {
    Name = "landandbay-db-sg"
  }
}

resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name = "landandbay-rds-kms-key"
  }
}

resource "aws_kms_alias" "rds" {
  name          = "alias/landandbay-rds"
  target_key_id = aws_kms_key.rds.key_id
}

resource "aws_db_instance" "postgres" {
  allocated_storage      = 20
  storage_type           = "gp3"
  engine                 = "postgres"
  engine_version         = "16.9"
  instance_class         = "db.t4g.micro"
  name                   = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = aws_db_parameter_group.postgres16.name
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot    = false  # Create a final snapshot for data protection
  final_snapshot_identifier = "landandbay-final-snapshot"
  deletion_protection    = true
  multi_az               = false  # Keep single-AZ for cost savings as uptime isn't critical
  backup_retention_period = 14     # Increase backup retention since data protection is important
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  performance_insights_enabled = false # Skip Performance Insights to save costs
  storage_encrypted     = true  # Keep encryption since data protection is important
  kms_key_id            = aws_kms_key.rds.arn
  monitoring_interval   = 0     # Skip enhanced monitoring to save costs
  publicly_accessible   = false # Ensure the database is not publicly accessible
  
  tags = {
    Name = "landandbay-db"
  }
}

# Monitoring role is defined but not used in dev/staging to save costs
# Uncomment the monitoring_interval and monitoring_role_arn in the RDS instance for production
resource "aws_iam_role" "rds_monitoring_role" {
  name = "rds-monitoring-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  
  tags = {
    Name = "rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_monitoring_policy" {
  role       = aws_iam_role.rds_monitoring_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_parameter_group" "postgres16" {
  name   = "landandbay-pg16"
  family = "postgres16"

  parameter {
    name  = "shared_preload_libraries"
    value = "postgis"
  }
  
  tags = {
    Name = "landandbay-pg16"
  }
}

# KMS key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  
  tags = {
    Name = "landandbay-secrets-kms-key"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/landandbay-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# Secrets Management for the application
resource "aws_secretsmanager_secret" "db_url" {
  name        = "landandbay/database-url"
  description = "PostgreSQL database connection URL for the Land and Bay application"
  kms_key_id  = aws_kms_key.secrets.arn
  
  tags = {
    Name = "landandbay-db-url"
  }
}

# Instead of storing secret value directly in Terraform state, use a lifecycle configuration
# for the actual secret value to be set manually or via a secure CI/CD pipeline
resource "aws_secretsmanager_secret_version" "db_url" {
  secret_id     = aws_secretsmanager_secret.db_url.id
  secret_string = "{\"url\":\"postgis://${var.app_db_username}@${aws_db_instance.postgres.endpoint}/${var.db_name}\"}"
  
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

resource "aws_secretsmanager_secret" "secret_key" {
  name        = "landandbay/secret-key"
  description = "Django secret key for the Land and Bay application"
  kms_key_id  = aws_kms_key.secrets.arn
  
  tags = {
    Name = "landandbay-secret-key"
  }
}

resource "aws_secretsmanager_secret_version" "secret_key" {
  secret_id     = aws_secretsmanager_secret.secret_key.id
  secret_string = "{\"key\":\"dummy-value-to-be-changed\"}"
  
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

# Create application user and enable PostGIS extension
resource "null_resource" "db_setup" {
  depends_on = [aws_db_instance.postgres]

  # This will run every time the RDS endpoint changes (e.g., after creation)
  triggers = {
    db_instance_endpoint = aws_db_instance.postgres.endpoint
  }

  provisioner "local-exec" {
    command = <<-EOT
      # Install PostgreSQL client if not already available
      which psql || (apt-get update && apt-get install -y postgresql-client)
      
      # Sleep to allow RDS to fully initialize
      sleep 30
      
      # Create a SQL script file for better escaping and readability
      cat > /tmp/db_setup.sql << 'SQLEOF'
      -- Enable PostGIS extension
      CREATE EXTENSION IF NOT EXISTS postgis;

      -- Create application user if it doesn't exist
      DO $$
      BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${var.app_db_username}') THEN
          CREATE USER ${var.app_db_username} WITH PASSWORD '${var.app_db_password}';
        END IF;
      END
      $$;
      
      -- Grant basic connect privileges
      GRANT CONNECT ON DATABASE ${var.db_name} TO ${var.app_db_username};
      
      -- Grant schema usage
      GRANT USAGE ON SCHEMA public TO ${var.app_db_username};
      
      -- Grant table privileges
      GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO ${var.app_db_username};
      
      -- Grant sequence privileges
      GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO ${var.app_db_username};
      
      -- Set default privileges for future tables and sequences
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO ${var.app_db_username};
      ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO ${var.app_db_username};
      SQLEOF
      
      # Execute the SQL script
      PGPASSWORD=${var.db_password} psql -h ${aws_db_instance.postgres.address} -U ${var.db_username} -d ${var.db_name} -f /tmp/db_setup.sql
      
      # Remove the temporary SQL file
      rm /tmp/db_setup.sql
    EOT
  }
}

# Load Balancer
resource "aws_s3_bucket" "alb_logs" {
  bucket = "landandbay-alb-logs"
  
  tags = {
    Name = "landandbay-alb-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "log-expiration"
    status = "Enabled"

    expiration {
      days = 30  # Reduced retention to save costs
    }
  }
}

resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        },
        Action = "s3:PutObject",
        Resource = "${aws_s3_bucket.alb_logs.arn}/AWSLogs/*"
      }
    ]
  })
}

data "aws_elb_service_account" "main" {}

# Bastion host for database access
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t4g.nano"
  key_name               = var.bastion_key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id              = aws_subnet.public_a.id
  associate_public_ip_address = true
  
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }
  
  user_data = <<-EOF
    #!/bin/bash
    # Install PostgreSQL client for troubleshooting if needed
    amazon-linux-extras enable postgresql13
    yum install -y postgresql
    
    # Set up automatic shutdown to save costs when idle
    # Auto-shutdown after 2 hours of idle time
    yum install -y bc
    
    cat > /usr/local/bin/check-idle.sh << 'IDLE'
    #!/bin/bash
    # Check if there are active SSH sessions
    ACTIVE_SSH=$(who | grep -c pts)
    # Check load average
    LOAD=$(uptime | awk '{print $(NF-2)}' | sed 's/,//')
    # If no SSH sessions and load is low, shut down
    if [ $ACTIVE_SSH -eq 0 ] && [ $(echo "$LOAD < 0.1" | bc) -eq 1 ]; then
      # Check how long it's been idle
      UPTIME=$(cat /proc/uptime | awk '{print $1}')
      LAST_LOGIN=$(last -n 1 | grep -v 'still logged in' | awk '{print $7,$8,$9,$10}')
      # If uptime is more than 2 hours, shut down
      if [ $(echo "$UPTIME > 7200" | bc) -eq 1 ]; then
        shutdown -h now "Auto-shutdown due to inactivity"
      fi
    fi
    IDLE
    
    chmod +x /usr/local/bin/check-idle.sh
    
    # Add cron job to check every 15 minutes
    echo "*/15 * * * * /usr/local/bin/check-idle.sh" > /etc/cron.d/idle-shutdown
    
    # Update server
    yum update -y
    
    # Create a welcome message with usage instructions
    cat > /etc/motd << 'MOTD'
    =======================================================
    Welcome to the Land and Bay Stewards Database Jump Box
    =======================================================
    
    This server is configured to automatically shut down after
    2 hours of inactivity to save costs.
    
    To use with pgAdmin on your local machine:
    1. Keep this SSH session open
    2. In pgAdmin, connect to:
       - Host: localhost
       - Port: 5432
       - Username: (your database username)
       - Password: (your database password)
    
    =======================================================
    MOTD
  EOF
  
  tags = {
    Name = "landandbay-bastion"
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Get the latest Amazon Linux 2 AMI for ARM64 (t4g instance type)
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-arm64-gp2"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Note: To start the bastion host, use the AWS Console or CLI:
# aws ec2 start-instances --instance-ids <bastion-instance-id>

# WAF is important for security but can be costly
# In development/staging, we can use a more basic configuration
# For production, consider adding more rule groups
resource "aws_wafv2_web_acl" "main" {
  name        = "landandbay-waf"
  description = "WAF for Land and Bay application"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # Only use the SQL Injection Protection ruleset to save costs
  # In production, add the Common Rule Set and other protections
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "landandbay-waf"
    sampled_requests_enabled   = true
  }
  
  tags = {
    Name = "landandbay-waf"
  }
}

resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

resource "aws_lb" "main" {
  name               = "landandbay-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  
  access_logs {
    bucket  = aws_s3_bucket.alb_logs.bucket
    prefix  = "alb-logs"
    enabled = true
  }
  
  tags = {
    Name = "landandbay-alb"
  }
}

resource "aws_lb_target_group" "app" {
  name        = "landandbay-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    enabled             = true
    path                = "/api/campaigns/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
  
  tags = {
    Name = "landandbay-tg"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" # Modern TLS policy
  certificate_arn   = var.acm_certificate_arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# ECS IAM Roles
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "ecsTaskExecutionRole"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Add permissions to access Secrets Manager
resource "aws_iam_policy" "secrets_access" {
  name        = "SecretsManagerAccess"
  description = "Allow access to Secrets Manager for ECS tasks"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "secretsmanager:GetSecretValue"
        ],
        Resource = [
          aws_secretsmanager_secret.db_url.arn,
          aws_secretsmanager_secret.secret_key.arn
        ]
      }
    ]
  })
  
  tags = {
    Name = "SecretsManagerAccess"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_secrets_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
  
  tags = {
    Name = "ecsTaskRole"
  }
}

# Provide minimal required permissions to the task role (least privilege)
resource "aws_iam_policy" "ecs_task_policy" {
  name        = "ecsTaskPolicy"
  description = "Policy for ECS tasks with least privilege permissions"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "cloudwatch:PutMetricData",
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ],
        Resource = "*"
      }
    ]
  })
  
  tags = {
    Name = "ecsTaskPolicy"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

# ECS Service
resource "aws_ecs_task_definition" "app" {
  family                   = "landandbay"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  
  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "DEBUG"
          value = "False"
        },
        {
          name  = "ALLOWED_HOSTS"
          value = "*"
        }
      ]
      secrets = [
        {
          name = "SECRET_KEY",
          valueFrom = aws_secretsmanager_secret.secret_key.arn
        },
        {
          name = "DATABASE_URL",
          valueFrom = aws_secretsmanager_secret.db_url.arn
        }
      ]
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:8000/api/campaigns/ || exit 1"
        ],
        interval = 30,
        timeout = 5,
        retries = 3,
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/landandbay"
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
  
  tags = {
    Name = "landandbay-task-definition"
  }
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/landandbay"
  retention_in_days = 7
  
  tags = {
    Name = "landandbay-logs"
  }
}

resource "aws_ecs_service" "app" {
  name            = "landandbay-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  network_configuration {
    subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id] # Use app private subnets
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = true # Enable public IP since we're using Internet Gateway directly
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8000
  }
  
  # Enable deployment circuit breaker for safe deployments
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  
  # Simple deployment configuration suitable for low-traffic site
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0  # Allow zero downtime since uptime isn't critical
  
  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.https,
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
    aws_iam_role_policy_attachment.ecs_task_policy_attachment
  ]
  
  tags = {
    Name = "landandbay-service"
  }
}

# Route 53 Record
resource "aws_route53_record" "app" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  
  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
  
  tags = {
    Name = var.domain_name
  }
}

# Budget Monitoring
resource "aws_budgets_budget" "monthly" {
  name              = "landandbay-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "30"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = formatdate("YYYY-MM-01_00:00", timestamp())
  
  # Add cost allocation tag to the budget - specifically filter by Project tag
  cost_filter {
    name = "TagKeyValue"
    values = ["user:Project$landandbay"]
  }

  # Early warning at 70% of budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 70
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Near limit warning at 90% of budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.alert_email]
  }

  # Forecast warning if we're projected to exceed budget
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.alert_email]
  }
}