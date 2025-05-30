terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Compute Module

# ECR Repository
resource "aws_ecr_repository" "app" {
  name                 = var.prefix
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = {
    Name = var.prefix
  }
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = {
    Name = "${var.prefix}-cluster"
  }
}

# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${var.prefix}"
  retention_in_days = 30

  tags = {
    Name = "${var.prefix}-logs"
  }
}

# ECS Task Execution Role
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

# Permissions to access Secrets Manager
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
          var.db_url_secret_arn,
          var.secret_key_secret_arn
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

# ECS Task Role
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

# Minimal permissions for the task role
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

# ECS Task Definition
resource "aws_ecs_task_definition" "app" {
  family                   = var.prefix
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${aws_ecr_repository.app.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
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
          name      = "SECRET_KEY",
          valueFrom = var.secret_key_secret_arn
        },
        {
          name      = "DATABASE_URL",
          valueFrom = var.db_url_secret_arn
        }
      ]
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${var.container_port}/api/campaigns/ || exit 1"
        ],
        interval    = 30,
        timeout     = 5,
        retries     = 3,
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])

  tags = {
    Name = "${var.prefix}-task-definition"
  }
}

# ECS Service
resource "aws_ecs_service" "app" {
  name            = "${var.prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.app_security_group_id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "app"
    container_port   = var.container_port
  }

  # Enable deployment circuit breaker for safe deployments
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Simple deployment configuration
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
    aws_iam_role_policy_attachment.ecs_task_policy_attachment
  ]

  tags = {
    Name = "${var.prefix}-service"
  }
}

# Bastion Host
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

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = "t4g.nano"
  key_name                    = var.bastion_key_name
  vpc_security_group_ids      = [var.bastion_security_group_id]
  subnet_id                   = var.public_subnet_id
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
    Name = "${var.prefix}-bastion"
  }

  lifecycle {
    create_before_destroy = true
  }
}