# VPC and Networking Module

# Use existing VPC or create a new one
locals {
  vpc_id = var.create_vpc ? aws_vpc.main[0].id : var.vpc_id

  # Subnet outputs will be either the created subnets or the provided existing ones
  public_subnet_ids = var.create_public_subnets ? [
    aws_subnet.public_a[0].id,
    aws_subnet.public_b[0].id
  ] : var.public_subnet_ids

  private_subnet_ids = var.create_private_subnets ? [
    aws_subnet.private_a[0].id,
    aws_subnet.private_b[0].id
  ] : var.private_subnet_ids

  private_db_subnet_ids = var.create_db_subnets ? [
    aws_subnet.private_db_a[0].id,
    aws_subnet.private_db_b[0].id
  ] : var.db_subnet_ids
}

# VPC configuration - only created if create_vpc is true
resource "aws_vpc" "main" {
  count = var.create_vpc ? 1 : 0

  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}

# Data source to get existing VPC information when using an existing VPC
data "aws_vpc" "existing" {
  count = var.create_vpc ? 0 : 1
  id    = var.vpc_id
}

locals {
  # Use existing VPC information for outputs and validations
  existing_vpc_cidr = var.create_vpc ? "" : join("", data.aws_vpc.existing[*].cidr_block)
}

# Public subnets for ALB - only created if create_public_subnets is true
resource "aws_subnet" "public_a" {
  count = var.create_public_subnets ? 1 : 0

  vpc_id                  = local.vpc_id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-a"
  }
}

resource "aws_subnet" "public_b" {
  count = var.create_public_subnets ? 1 : 0

  vpc_id                  = local.vpc_id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.prefix}-public-b"
  }
}

# Private app subnets - only created if create_private_subnets is true
resource "aws_subnet" "private_a" {
  count = var.create_private_subnets ? 1 : 0

  vpc_id                  = local.vpc_id
  cidr_block              = var.private_subnet_a_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.prefix}-private-a"
  }
}

resource "aws_subnet" "private_b" {
  count = var.create_private_subnets ? 1 : 0

  vpc_id                  = local.vpc_id
  cidr_block              = var.private_subnet_b_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.prefix}-private-b"
  }
}

# Private database subnets - only created if create_db_subnets is true
resource "aws_subnet" "private_db_a" {
  count = var.create_db_subnets ? 1 : 0

  vpc_id                  = local.vpc_id
  cidr_block              = var.private_db_subnet_a_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.prefix}-private-db-a"
  }
}

resource "aws_subnet" "private_db_b" {
  count = var.create_db_subnets ? 1 : 0

  vpc_id                  = local.vpc_id
  cidr_block              = var.private_db_subnet_b_cidr
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.prefix}-private-db-b"
  }
}

# Internet Gateway - only created if create_vpc is true
resource "aws_internet_gateway" "igw" {
  count = var.create_vpc ? 1 : 0

  vpc_id = local.vpc_id

  tags = {
    Name = "${var.prefix}-igw"
  }
}

# Data source to get existing Internet Gateway if using existing VPC
data "aws_internet_gateway" "existing" {
  count = var.create_vpc ? 0 : 1

  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

# Public route table - only created if create_public_subnets is true
resource "aws_route_table" "public" {
  count = var.create_public_subnets ? 1 : 0

  vpc_id = local.vpc_id

  tags = {
    Name = "${var.prefix}-public-rt"
  }
}

# Routes for the public route table
# Route for the newly created IGW
resource "aws_route" "public_internet_gateway_new" {
  count = var.create_public_subnets && var.create_vpc ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id

  depends_on = [aws_route_table.public, aws_internet_gateway.igw]
}

# Route for the existing IGW
resource "aws_route" "public_internet_gateway_existing" {
  count = var.create_public_subnets && !var.create_vpc ? 1 : 0

  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.existing[0].id

  depends_on = [aws_route_table.public, data.aws_internet_gateway.existing]
}

# App subnet route table - only created if create_private_subnets is true
resource "aws_route_table" "private_app" {
  count = var.create_private_subnets ? 1 : 0

  vpc_id = local.vpc_id

  tags = {
    Name = "${var.prefix}-private-app-rt"
  }
}

# Routes for the private app route table
# Route for the newly created IGW
resource "aws_route" "private_app_internet_gateway_new" {
  count = var.create_private_subnets && var.create_vpc ? 1 : 0

  route_table_id         = aws_route_table.private_app[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id

  depends_on = [aws_route_table.private_app, aws_internet_gateway.igw]
}

# Route for the existing IGW
resource "aws_route" "private_app_internet_gateway_existing" {
  count = var.create_private_subnets && !var.create_vpc ? 1 : 0

  route_table_id         = aws_route_table.private_app[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = data.aws_internet_gateway.existing[0].id

  depends_on = [aws_route_table.private_app, data.aws_internet_gateway.existing]
}

# Database subnet route table - isolated - only created if create_db_subnets is true
resource "aws_route_table" "private_db" {
  count = var.create_db_subnets ? 1 : 0

  vpc_id = local.vpc_id
  # No route to internet - completely isolated

  tags = {
    Name = "${var.prefix}-private-db-rt"
  }
}

# Route table associations - only created if corresponding subnets are created
resource "aws_route_table_association" "public_a" {
  count = var.create_public_subnets && length(aws_route_table.public) > 0 ? 1 : 0

  subnet_id      = aws_subnet.public_a[0].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "public_b" {
  count = var.create_public_subnets && length(aws_route_table.public) > 0 ? 1 : 0

  subnet_id      = aws_subnet.public_b[0].id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_route_table_association" "private_app_a" {
  count = var.create_private_subnets && length(aws_route_table.private_app) > 0 ? 1 : 0

  subnet_id      = aws_subnet.private_a[0].id
  route_table_id = aws_route_table.private_app[0].id
}

resource "aws_route_table_association" "private_app_b" {
  count = var.create_private_subnets && length(aws_route_table.private_app) > 0 ? 1 : 0

  subnet_id      = aws_subnet.private_b[0].id
  route_table_id = aws_route_table.private_app[0].id
}

resource "aws_route_table_association" "private_db_a" {
  count = var.create_db_subnets && length(aws_route_table.private_db) > 0 ? 1 : 0

  subnet_id      = aws_subnet.private_db_a[0].id
  route_table_id = aws_route_table.private_db[0].id
}

resource "aws_route_table_association" "private_db_b" {
  count = var.create_db_subnets && length(aws_route_table.private_db) > 0 ? 1 : 0

  subnet_id      = aws_subnet.private_db_b[0].id
  route_table_id = aws_route_table.private_db[0].id
}

# VPC Endpoint for S3 - allows private resources to access S3 without internet
resource "aws_vpc_endpoint" "s3" {
  count = var.create_db_subnets && var.create_vpc_endpoints ? 1 : 0

  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_db[0].id]

  tags = {
    Name = "${var.prefix}-s3-endpoint"
  }
}

# Security Group for Interface VPC Endpoints
resource "aws_security_group" "ecs_endpoints" {
  count = var.create_vpc_endpoints && var.existing_endpoints_security_group_id == "" ? 1 : 0

  name   = "${var.prefix}-endpoints-sg"
  vpc_id = local.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.create_vpc ? var.vpc_cidr : local.existing_vpc_cidr]
    description = "Allow HTTPS from within VPC"
  }

  egress {
    from_port   = 1024
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.create_vpc ? var.vpc_cidr : local.existing_vpc_cidr]
    description = "Restrict egress to VPC for return traffic"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.create_vpc ? var.vpc_cidr : local.existing_vpc_cidr]
    description = "Allow DNS queries to VPC resolver"
  }

  tags = {
    Name = "${var.prefix}-endpoints-sg"
  }
}

# Use a local for the security group ID, which could be either the created one or an existing one
locals {
  endpoints_security_group_id = var.existing_endpoints_security_group_id != "" ? var.existing_endpoints_security_group_id : (length(aws_security_group.ecs_endpoints) > 0 ? aws_security_group.ecs_endpoints[0].id : "")
}

locals {
  vpc_endpoints = {
    ecr_api = {
      service_name = "com.amazonaws.${var.aws_region}.ecr.api"
      tag_name     = "${var.prefix}-ecr-api-endpoint"
    },
    ecr_dkr = {
      service_name = "com.amazonaws.${var.aws_region}.ecr.dkr"
      tag_name     = "${var.prefix}-ecr-dkr-endpoint"
    },
    logs = {
      service_name = "com.amazonaws.${var.aws_region}.logs"
      tag_name     = "${var.prefix}-logs-endpoint"
    },
    secretsmanager = {
      service_name = "com.amazonaws.${var.aws_region}.secretsmanager"
      tag_name     = "${var.prefix}-secretsmanager-endpoint"
    }
  }
}

resource "aws_vpc_endpoint" "interface" {
  for_each            = var.create_vpc_endpoints ? local.vpc_endpoints : {}
  vpc_id              = local.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.private_subnet_ids
  security_group_ids  = [local.endpoints_security_group_id]
  private_dns_enabled = true

  tags = {
    Name = each.value.tag_name
  }
}