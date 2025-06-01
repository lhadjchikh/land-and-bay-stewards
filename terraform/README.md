# Terraform Infrastructure for Land and Bay Stewards

This directory contains the Terraform configuration for deploying the Land and Bay Stewards application to AWS. The infrastructure is designed to be secure, scalable, and SOC 2 compliant.

## Architecture Overview

The infrastructure architecture consists of the following components:

- **Networking**: VPC, subnets, route tables, security groups
- **Compute**: ECS Fargate for containerized application
- **Database**: RDS PostgreSQL with PostGIS extension
- **Load Balancing**: Application Load Balancer
- **Secrets Management**: AWS Secrets Manager for secure credentials
- **Monitoring**: CloudWatch for logs and metrics
- **DNS**: Route53 for domain management

## Flexible Deployment Options

The infrastructure is designed to be flexible and adaptable to different deployment scenarios:

### New Infrastructure Deployment

By default, the Terraform configuration creates all required resources from scratch, including:

- New VPC with public and private subnets
- Security groups, route tables, and internet gateways
- RDS database instance
- ECS cluster and services

### Using Existing VPC Resources

The infrastructure can also be deployed into an existing VPC environment by setting the appropriate variables:

- Use an existing VPC and create new subnets
- Use an existing VPC with existing subnets
- Mix and match by using some existing resources and creating others

This flexibility makes it ideal for enterprise environments where network infrastructure may already be established.

## Security Features

The infrastructure includes the following security features:

- **AWS Secrets Manager** for secure credential storage
- **Secure credential generation** for database users
- **IAM roles with least privilege** for all services
- **KMS encryption** for sensitive data
- **VPC security groups** with restricted access
- **Network isolation** for database resources
- **Application-level separation of privileges**

## Secure Credentials Management

### Database Credentials

Database credentials are managed securely through AWS Secrets Manager:

1. **Master Database User**: Administrative user with full database privileges
   - Credentials stored in AWS Secrets Manager
   - Used only for initial setup and maintenance
   - Not exposed to application code

2. **Application Database User**: Restricted user for application access
   - Automatically generated secure password
   - Limited privileges based on principle of least privilege
   - Credentials injected into application via Secrets Manager

### Credential Lifecycle

1. **Initial Setup**:
   - If secrets don't exist, they are created with secure passwords
   - If secrets exist, they are used for deployment

2. **Manual Password Updates**:
   - Passwords can be updated manually through AWS Secrets Manager console
   - No need to update Terraform configuration

3. **Future Enhancement**:
   - Automated password rotation is not currently configured
   - May be implemented in future releases using AWS Lambda and Secrets Manager rotation schedules

4. **Access Control**:
   - IAM policies restrict access to secrets
   - KMS encryption adds another layer of security
   - Audit logging tracks all access to secrets

## Using Secrets Manager

### For Initial Deployment

For the initial deployment, you have two options:

1. **Pre-create secrets** (recommended for production):

   ```bash
   # Create master credentials secret
   aws secretsmanager create-secret \
     --name landandbay/database-master \
     --description "PostgreSQL master database credentials" \
     --secret-string '{"username":"your_secure_username","password":"your_secure_password"}'
   
   # Optional: Create application credentials secret
   aws secretsmanager create-secret \
     --name landandbay/database-app \
     --description "PostgreSQL application database credentials" \
     --secret-string '{"username":"app_user","password":"your_secure_app_password"}'
   ```

2. **Let Terraform create secrets** (development/testing only):
   - Set `TF_VAR_use_secrets_manager=true`
   - Provide initial values for `TF_VAR_db_username` and `TF_VAR_db_password` for first run only
   - Terraform creates secrets with secure passwords for application database

### Accessing Secrets

To view the secrets:

```bash
# View master credentials
aws secretsmanager get-secret-value --secret-id landandbay/database-master --query SecretString --output text | jq .

# View application credentials
aws secretsmanager get-secret-value --secret-id landandbay/database-app --query SecretString --output text | jq .
```

## Bastion Host SSH Key Management

A bastion host is provisioned to allow secure access to the database. You have several options for SSH key management.

### Option 1: Manual Key Pair Creation (Recommended for Production)

1. Create an SSH key pair locally:
   ```bash
   ssh-keygen -t rsa -b 2048 -f ~/.ssh/landandbay-bastion -C "landandbay-bastion"
   ```

2. Store the public key as a GitHub secret with the name `TF_VAR_BASTION_PUBLIC_KEY`.
   - Copy the contents of `~/.ssh/landandbay-bastion.pub` 
   - Go to your GitHub repository → Settings → Secrets and Variables → Actions
   - Add new repository secret with name `TF_VAR_BASTION_PUBLIC_KEY` and paste the public key as value

3. Keep the private key (`~/.ssh/landandbay-bastion`) secure for connecting to the bastion host.

4. To connect to the bastion host:
   ```bash
   ssh -i ~/.ssh/landandbay-bastion ec2-user@<bastion-host-public-ip>
   ```

### Option 2: Using AWS Console to Create a Key Pair

1. Create a key pair in the AWS Console:
   - Go to EC2 → Key Pairs → Create Key Pair
   - Name it `landandbay-bastion` (or whatever matches your `bastion_key_name` variable)
   - Download and save the private key file securely

2. In your Terraform configuration, set:
   ```hcl
   bastion_key_name = "landandbay-bastion"  # Match the name you used in AWS
   bastion_public_key = ""                  # Leave empty to use existing key
   ```

3. The infrastructure will automatically detect and use the existing key pair.

### Option 3: Using an Existing Key Pair

If you already have a key pair in AWS:

1. Specify the key name in your Terraform configuration:
   ```hcl
   bastion_key_name = "your-existing-key-name"
   bastion_public_key = ""                  # Leave empty to use existing key
   ```

2. The infrastructure will automatically detect and use the existing key pair.

### SSH Tunnel for Database Access

To access the RDS database through the bastion host:

1. Create an SSH tunnel:
   ```bash
   ssh -i ~/.ssh/landandbay-bastion -L 5432:your-rds-endpoint:5432 ec2-user@<bastion-host-public-ip>
   ```

2. Connect to the database using localhost:5432 in your SQL client.

## Core Variables

| Variable Name | Description | Default | Required |
|---------------|-------------|---------|----------|
| `prefix` | Prefix to use for resource names | `landandbay` | No |
| `aws_region` | AWS region to deploy to | `us-east-1` | No |
| `tags` | Default tags to apply to all resources | `{ Project = "landandbay", Environment = "Production" }` | No |
| `bastion_key_name` | SSH key name for bastion host | `landandbay-bastion` | No |
| `bastion_public_key` | SSH public key for bastion host | `""` | Yes, for bastion access |

## Networking Variables

| Variable Name | Description | Default | Required |
|---------------|-------------|---------|----------|
| `create_vpc` | Whether to create a new VPC | `true` | No |
| `vpc_id` | ID of existing VPC (if `create_vpc` is false) | `""` | Yes, if `create_vpc` is false |
| `create_public_subnets` | Whether to create new public subnets | `true` | No |
| `public_subnet_ids` | IDs of existing public subnets (if `create_public_subnets` is false) | `[]` | Yes, if `create_public_subnets` is false |
| `create_private_subnets` | Whether to create new private app subnets | `true` | No |
| `private_subnet_ids` | IDs of existing private app subnets (if `create_private_subnets` is false) | `[]` | Yes, if `create_private_subnets` is false |
| `create_db_subnets` | Whether to create new database subnets | `true` | No |
| `db_subnet_ids` | IDs of existing database subnets (if `create_db_subnets` is false) | `[]` | Yes, if `create_db_subnets` is false |

## Database Variables

| Variable Name | Description | Default | Required |
|---------------|-------------|---------|----------|
| `use_secrets_manager` | Enable AWS Secrets Manager integration | `true` | No |
| `db_username` | Master database username (used only for initial setup) | `postgres_admin` | No |
| `db_password` | Master database password (used only for initial setup) | n/a | Yes, for initial setup only |
| `app_db_username` | Application database username | `app_user` | No |
| `app_db_password` | Application database password (auto-generated if empty) | `""` | No |
| `db_name` | Database name | `landandbay` | No |

## Usage Examples

### Default Deployment (Create All Resources)

```hcl
# No special configuration needed - defaults create everything
module "infrastructure" {
  source = "./terraform"
  
  # Only required variables
  db_password         = "your-secure-password"
  route53_zone_id     = "Z1234567890ABC"
  domain_name         = "landandbay.org"
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/uuid"
  alert_email         = "alerts@example.com"
}
```

### Using Existing VPC

```hcl
module "infrastructure" {
  source = "./terraform"
  
  # VPC configuration
  create_vpc = false
  vpc_id     = "vpc-01234567890abcdef"
  
  # Create new subnets in the existing VPC
  create_public_subnets  = true
  create_private_subnets = true
  create_db_subnets      = true
  
  # Bastion host configuration
  bastion_key_name    = "landandbay-bastion"
  bastion_public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAAD... landandbay-bastion-key" # Your actual public key
  
  # Required variables
  db_password         = "your-secure-password"
  route53_zone_id     = "Z1234567890ABC"
  domain_name         = "landandbay.org"
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/uuid"
  alert_email         = "alerts@example.com"
}
```

### Using Existing VPC and Subnets

```hcl
module "infrastructure" {
  source = "./terraform"
  
  # VPC configuration
  create_vpc = false
  vpc_id     = "vpc-01234567890abcdef"
  
  # Public subnet configuration
  create_public_subnets = false
  public_subnet_ids     = ["subnet-pub1", "subnet-pub2"]
  
  # Private subnet configuration
  create_private_subnets = false
  private_subnet_ids     = ["subnet-priv1", "subnet-priv2"]
  
  # DB subnet configuration
  create_db_subnets = false
  db_subnet_ids     = ["subnet-db1", "subnet-db2"]
  
  # Required variables
  db_password         = "your-secure-password"
  route53_zone_id     = "Z1234567890ABC"
  domain_name         = "landandbay.org"
  acm_certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/uuid"
  alert_email         = "alerts@example.com"
}
```

## Best Practices

### General
1. **Never hardcode credentials** in Terraform files or environment variables
2. **Use remote state storage** for production deployments
3. **Use Terraform workspaces** for different environments

### Security
1. **Use Secrets Manager** for all production deployments
2. **Update credentials** manually through AWS Secrets Manager when needed
3. **Limit access** to the secrets using IAM policies
4. **Monitor access** to secrets through CloudTrail
5. **Use encrypted communications** for all database connections
6. **Store SSH keys securely** and never commit private keys to repositories
7. **Store public keys as secrets** in your CI/CD platform rather than in code
8. **Rotate SSH keys periodically** for enhanced security

### Networking
1. **Evaluate existing VPC** resources before creating new ones
2. **Use private subnets** for applications where possible
3. **Isolate database subnets** from direct internet access
4. **Use bastion hosts** for controlled access to private resources
5. **Limit bastion host access** to specific IP addresses when possible