# Networking Module

This module creates and manages the networking infrastructure for the Coalition Builder application.

## Features

- **VPC Creation**: Creates a new VPC or uses an existing one
- **Multi-AZ Subnets**: Creates subnets across multiple availability zones
- **Public Subnets**: For internet-facing resources like load balancers
- **Private Application Subnets**: For application containers (ECS tasks)
- **Private Database Subnets**: Isolated subnets for database instances
- **NAT Gateway**: Allows private resources to access the internet
- **VPC Endpoints**: Provides private connectivity to AWS services:
  - S3 Gateway Endpoint: For S3 access without going through the internet
  - Interface Endpoints: For ECR, CloudWatch Logs, and Secrets Manager
- **Security Groups**: Including a dedicated security group for VPC endpoints

## Usage

```hcl
module "networking" {
  source = "./modules/networking"

  prefix     = "coalition"
  aws_region = "us-east-1"

  # VPC Configuration
  create_vpc = true
  vpc_cidr   = "10.0.0.0/16"

  # Subnet Configuration
  create_public_subnets  = true
  create_private_subnets = true
  create_db_subnets      = true
}
```

## VPC Endpoints

The module creates the following VPC endpoints to allow private resources to access AWS services without going through the internet:

1. **S3 Gateway Endpoint**: Provides access to S3 using the AWS network instead of the internet
2. **Interface Endpoints**:
   - **ECR API**: For pulling container images
   - **ECR DKR**: For Docker registry operations
   - **CloudWatch Logs**: For sending logs to CloudWatch
   - **Secrets Manager**: For accessing secrets

A dedicated security group is created for interface endpoints with the following rules:

- Inbound: HTTPS (443) from within the VPC
- Outbound: Return traffic and DNS queries within the VPC

## Inputs

See `variables.tf` for a complete list of input parameters.

## Outputs

| Name                        | Description                                 |
| --------------------------- | ------------------------------------------- |
| vpc_id                      | The ID of the VPC                           |
| vpc_cidr                    | The CIDR block of the VPC                   |
| public_subnet_ids           | List of public subnet IDs                   |
| private_subnet_ids          | List of private app subnet IDs              |
| private_db_subnet_ids       | List of private database subnet IDs         |
| app_subnet_cidrs            | List of private app subnet CIDR blocks      |
| db_subnet_cidrs             | List of private database subnet CIDR blocks |
| s3_endpoint_id              | ID of the S3 VPC endpoint                   |
| s3_endpoint_prefix_list_id  | Prefix list ID of the S3 VPC endpoint       |
| endpoints_security_group_id | ID of the security group for VPC endpoints  |
