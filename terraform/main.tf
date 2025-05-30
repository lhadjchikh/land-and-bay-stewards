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

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
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
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "landandbay-sg"
  }
}

# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = "landandbay"
  image_tag_mutability = "MUTABLE"
  
  image_scanning_configuration {
    scan_on_push = true
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
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  
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
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "landandbay-db-sg"
  }
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
  skip_final_snapshot    = true
  deletion_protection    = true
  multi_az               = false
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  performance_insights_enabled = false
  
  tags = {
    Name = "landandbay-db"
  }
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

# Secrets Management for the application
resource "aws_secretsmanager_secret" "db_url" {
  name        = "landandbay/database-url"
  description = "PostgreSQL database connection URL for the Land and Bay application"
  
  tags = {
    Name = "landandbay-db-url"
  }
}

resource "aws_secretsmanager_secret_version" "db_url" {
  secret_id     = aws_secretsmanager_secret.db_url.id
  secret_string = "postgis://${var.app_db_username}:${var.app_db_password}@${aws_db_instance.postgres.endpoint}/${var.db_name}"
}

resource "aws_secretsmanager_secret" "secret_key" {
  name        = "landandbay/secret-key"
  description = "Django secret key for the Land and Bay application"
  
  tags = {
    Name = "landandbay-secret-key"
  }
}

resource "aws_secretsmanager_secret_version" "secret_key" {
  secret_id     = aws_secretsmanager_secret.secret_key.id
  secret_string = var.django_secret_key
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
resource "aws_lb" "main" {
  name               = "landandbay-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  
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
  ssl_policy        = "ELBSecurityPolicy-2016-08"
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
    subnets          = [aws_subnet.public_a.id, aws_subnet.public_b.id]
    security_groups  = [aws_security_group.app_sg.id]
    assign_public_ip = true
  }
  
  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8000
  }
  
  depends_on = [
    aws_lb_listener.http,
    aws_lb_listener.https,
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy
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