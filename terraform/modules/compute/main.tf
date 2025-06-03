# Compute Module

# API ECR Repository
resource "aws_ecr_repository" "api" {
  name                 = "${var.prefix}-api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = {
    Name = "${var.prefix}-api"
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

resource "aws_iam_policy" "secrets_access" {
  name        = "SecretsManagerAccess"
  description = "Allow access to Secrets Manager and KMS for ECS tasks"

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
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Resource = var.secrets_kms_key_arn
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
          "cloudwatch:PutMetricData"
        ],
        Resource = "*" # CloudWatch metrics only support * as resource
      },
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ],
        Resource = [
          "${aws_cloudwatch_log_group.ecs_logs.arn}:*",
          aws_cloudwatch_log_group.ecs_logs.arn
        ]
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

# ECS Task Definition with both Django and Node.js SSR
resource "aws_ecs_task_definition" "app" {
  family                   = var.prefix
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory != null ? var.task_memory : (var.enable_ssr ? 512 : 256)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = var.enable_ssr ? jsonencode([
    # Django API Container
    {
      name      = "app"
      image     = "${aws_ecr_repository.api.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
          name          = "django-api"
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
          valueFrom = "${var.db_url_secret_arn}:url::"
        }
      ]
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"
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
          "awslogs-stream-prefix" = "django"
        }
      }
    },
    # SSR Container
    {
      name      = "ssr"
      image     = "${aws_ecr_repository.ssr.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
          name          = "ssr-app"
        }
      ]
      environment = [
        {
          name  = "NODE_ENV"
          value = "production"
        },
        {
          name  = "API_URL"
          value = "http://localhost:${var.container_port}"
        },
        {
          name  = "NEXT_PUBLIC_API_URL"
          value = "https://${var.domain_name}"
        },
        {
          name  = "PORT"
          value = "3000"
        }
      ]
      healthCheck = {
        command = [
          "CMD-SHELL",
          "node /app/healthcheck.js"
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
          "awslogs-stream-prefix" = "ssr"
        }
      }
      dependsOn = [
        {
          containerName = "app"
          condition     = "HEALTHY"
        }
      ]
    }
    ]) : jsonencode([
    # Django API Container only (when enable_ssr is false)
    {
      name      = "app"
      image     = "${aws_ecr_repository.api.repository_url}:latest"
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
          name          = "django-api"
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
          valueFrom = "${var.db_url_secret_arn}:url::"
        }
      ]
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:${var.container_port}${var.health_check_path} || exit 1"
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
          "awslogs-stream-prefix" = "django"
        }
      }
    }
  ])

  tags = {
    Name = "${var.prefix}-task-definition"
  }
}

# SSR ECR repository - always created regardless of SSR being enabled
resource "aws_ecr_repository" "ssr" {
  name                 = "${var.prefix}-ssr"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "KMS"
  }

  tags = {
    Name = "${var.prefix}-ssr"
  }
}

# Load balancer configuration

# ECS Service with both target groups registered to the same ALB
resource "aws_ecs_service" "app" {
  name            = "${var.prefix}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.app_security_group_id]
    assign_public_ip = false # Changed from true to improve security
  }

  # Load balancer configuration for Django API
  load_balancer {
    target_group_arn = var.api_target_group_arn
    container_name   = "app"
    container_port   = var.container_port
  }

  # Load balancer configuration for SSR (only if SSR is enabled and target group is provided)
  dynamic "load_balancer" {
    for_each = var.enable_ssr && var.ssr_target_group_arn != "" ? [1] : []
    content {
      target_group_arn = var.ssr_target_group_arn
      container_name   = "ssr"
      container_port   = 3000
    }
  }

  # Enable deployment circuit breaker for safe deployments
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Using default deployment configuration

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
    aws_iam_role_policy_attachment.ecs_task_policy_attachment,
    aws_iam_role_policy_attachment.ecs_task_execution_secrets_policy
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

# Create a key pair only if explicitly instructed to do so
# This approach ensures we avoid conflicts with existing key pairs
resource "aws_key_pair" "bastion" {
  count      = var.create_new_key_pair ? 1 : 0
  key_name   = var.bastion_key_name
  public_key = var.bastion_public_key

  # Fail the apply if create_new_key_pair is true but no public key was provided
  lifecycle {
    precondition {
      condition     = var.bastion_public_key != ""
      error_message = "When create_new_key_pair is set to true, you must provide a bastion_public_key value."
    }
  }
}

resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t4g.nano"
  # Use the key_name provided in the variable
  # This will refer to an existing key pair or one we're creating with the aws_key_pair resource
  # When bastion_public_key is empty, it is assumed the key pair already exists in AWS
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