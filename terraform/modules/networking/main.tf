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

locals {
  # Use the created IGW or the existing one
  igw_id = var.create_vpc ? aws_internet_gateway.igw[0].id : (length(data.aws_internet_gateway.existing) > 0 ? data.aws_internet_gateway.existing[0].id : null)
}

# Public route table - only created if create_public_subnets is true
resource "aws_route_table" "public" {
  count = var.create_public_subnets && local.igw_id != null ? 1 : 0
  
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = local.igw_id
  }

  tags = {
    Name = "${var.prefix}-public-rt"
  }
}

# App subnet route table - direct to IGW - only created if create_private_subnets is true
resource "aws_route_table" "private_app" {
  count = var.create_private_subnets ? 1 : 0
  
  vpc_id = local.vpc_id

  dynamic "route" {
    for_each = local.igw_id != null ? [1] : []
    content {
      cidr_block = "0.0.0.0/0"
      gateway_id = local.igw_id
    }
  }

  tags = {
    Name = "${var.prefix}-private-app-rt"
  }
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

# VPC Endpoint for S3 - allows DB to access S3 without internet - only created if create_db_subnets is true
resource "aws_vpc_endpoint" "s3" {
  count = var.create_db_subnets && length(aws_route_table.private_db) > 0 ? 1 : 0
  
  vpc_id            = local.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private_db[0].id]

  tags = {
    Name = "${var.prefix}-s3-endpoint"
  }
}