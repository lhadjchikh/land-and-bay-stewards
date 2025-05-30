# Secrets Management Module

# KMS key for Secrets Manager
resource "aws_kms_key" "secrets" {
  description             = "KMS key for Secrets Manager encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = {
    Name = "${var.prefix}-secrets-kms-key"
  }
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${var.prefix}-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

# Database URL Secret
resource "aws_secretsmanager_secret" "db_url" {
  name        = "${var.prefix}/database-url"
  description = "PostgreSQL database connection URL for the application"
  kms_key_id  = aws_kms_key.secrets.arn

  tags = {
    Name = "${var.prefix}-db-url"
  }
}

# Django Secret Key Secret
resource "aws_secretsmanager_secret" "secret_key" {
  name        = "${var.prefix}/secret-key"
  description = "Django secret key for the application"
  kms_key_id  = aws_kms_key.secrets.arn

  tags = {
    Name = "${var.prefix}-secret-key"
  }
}

# Database Master Password Secret
resource "aws_secretsmanager_secret" "db_master" {
  name        = "${var.prefix}/database-master"
  description = "PostgreSQL master database credentials"
  kms_key_id  = aws_kms_key.secrets.arn

  tags = {
    Name = "${var.prefix}-db-master"
  }
}

# Secret versions - use lifecycle to avoid storing sensitive data in state
resource "aws_secretsmanager_secret_version" "db_url" {
  secret_id = aws_secretsmanager_secret.db_url.id
  secret_string = jsonencode({
    url      = "postgis://${var.app_db_username}:${var.app_db_password}@${var.db_endpoint}/${var.db_name}"
    username = var.app_db_username
    password = var.app_db_password
    host     = split(":", var.db_endpoint)[0]
    port     = try(split(":", var.db_endpoint)[1], "5432")
    dbname   = var.db_name
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
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

# Initial database master credentials - a randomly generated password will be used
# for production deployment
resource "aws_secretsmanager_secret_version" "db_master" {
  secret_id = aws_secretsmanager_secret.db_master.id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password != "" ? var.db_password : "dummy-password-to-be-generated"
    host     = var.db_endpoint != "" ? split(":", var.db_endpoint)[0] : "pending-db-creation"
    port     = var.db_endpoint != "" ? try(split(":", var.db_endpoint)[1], "5432") : "5432"
    dbname   = var.db_name
  })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}