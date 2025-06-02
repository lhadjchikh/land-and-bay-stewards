# Terraform Infrastructure for Land and Bay Stewards

This directory contains the Terraform configuration for deploying the Land and Bay Stewards application to AWS. The infrastructure is designed to be secure, scalable, and SOC 2 compliant.

## Architecture Overview

The infrastructure architecture consists of the following components:

- **Networking**: VPC, subnets, route tables, security groups
- **Compute**: ECS Fargate for containerized application
- **Database**: RDS PostgreSQL with PostGIS extension
- **Load Balancing**: Application Load Balancer with dedicated security group
- **Secrets Management**: AWS Secrets Manager for secure credentials with proper URL encoding
- **Monitoring**: CloudWatch for logs and metrics
- **DNS**: Route53 for domain management

## Security Architecture

The infrastructure implements a layered security model with separate security groups for each component:

### Security Groups

- **Load Balancer Security Group**: Allows HTTP/HTTPS (80/443) from internet, sends traffic to application on port 8000
- **Application Security Group**: Accepts traffic from load balancer on port 8000, connects to database on port 5432
- **Database Security Group**: Accepts connections from application and bastion host on port 5432
- **Bastion Security Group**: Allows SSH (22) from specified IP ranges

This separation ensures each component has only the minimum required network access (principle of least privilege).

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

## Database Setup Process

The database setup has been improved for better reliability and security:

### Automated Setup (Recommended)

- Uses a robust shell script (`db_setup.sh`) with proper error handling
- Implements secure password URL encoding with fallback methods
- Validates prerequisites before execution
- Provides clear error messages and recovery instructions

### Manual Setup (Alternative)

- Run the setup script manually after Terraform deployment
- Full control over the setup process
- Better for troubleshooting and custom environments

## Security Features

The infrastructure includes the following security features:

- **AWS Secrets Manager** for secure credential storage with proper URL encoding
- **Secure credential generation** for database users with URL-safe characters
- **IAM roles with least privilege** for all services
- **KMS encryption** for sensitive data
- **Layered security groups** with component isolation
- **Network isolation** for database resources
- **Application-level separation of privileges**
- **WAF protection** for web applications

## Secure Credentials Management

### Database Credentials

Database credentials are managed securely through AWS Secrets Manager:

1. **Master Database User**: Administrative user with full database privileges

   - Credentials stored in AWS Secrets Manager
   - Used only for initial setup and maintenance
   - Not exposed to application code

2. **Application Database User**: Restricted user for application access
   - Automatically generated secure, URL-safe password
   - Limited privileges based on principle of least privilege
   - Credentials injected into application via Secrets Manager
   - Proper URL encoding to handle special characters in connection strings

### Credential Lifecycle

1. **Initial Setup**:

   - If secrets don't exist, they are created with secure passwords
   - If secrets exist, they are used for deployment
   - Database setup script handles both scenarios gracefully

2. **Manual Password Updates**:

   - Passwords can be updated manually through AWS Secrets Manager console
   - No need to update Terraform configuration
   - Re-run database setup script to sync changes

3. **Future Enhancement**:

   - Automated password rotation is not currently configured
   - May be implemented in future releases using AWS Lambda and Secrets Manager rotation schedules

4. **Access Control**:
   - IAM policies restrict access to secrets
   - KMS encryption adds another layer of security
   - Audit logging tracks all access to secrets

## Database Setup Script

The infrastructure includes an improved database setup script (`db_setup.sh`) with the following features:

### Features

- **Robust error handling**: Validates prerequisites and provides clear error messages
- **Secure password handling**: Generates URL-safe passwords and handles encoding properly
- **Multiple execution methods**: Direct PostgreSQL variables or file-based with safe substitution
- **Cross-platform compatibility**: Works on various operating systems
- **Detailed logging**: Color-coded output and progress indicators

### Prerequisites

- Python3 (for secure password URL encoding)
- AWS CLI (properly configured with appropriate permissions)
- PostgreSQL client (`psql`)
- OpenSSL (for password generation)

### Usage

```bash
# Basic usage
./db_setup.sh --endpoint your-rds-endpoint.amazonaws.com

# Full options
./db_setup.sh --endpoint your-rds-endpoint.amazonaws.com \
              --database myapp \
              --master-user admin \
              --app-user app_service \
              --prefix myapp \
              --region us-east-1
```

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

2. **Let the setup script create secrets** (development/testing):
   - Run Terraform to create infrastructure
   - Run the database setup script which will create and populate secrets
   - Script generates secure, URL-safe passwords automatically

### Accessing Secrets

To view the secrets:

```bash
# View master credentials
aws secretsmanager get-secret-value --secret-id landandbay/database-master --query SecretString --output text | jq .

# View application credentials
aws secretsmanager get-secret-value --secret-id landandbay/database-app --query SecretString --output text | jq .

# Get just the application password
aws secretsmanager get-secret-value --secret-id landandbay/database-url --query SecretString --output text | jq -r .password
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

### Option 2: Using an AWS-Managed Key Pair

Instead of providing your own public key, you can have AWS create and manage the key pair:

1. Create a key pair in the AWS Console:

   - Go to EC2 → Key Pairs → Create Key Pair
   - Name it `landandbay-bastion` (or whatever name you prefer)
   - Select RSA and .pem format
   - Download and save the private key file securely

2. In your Terraform configuration, set:

   ```hcl
   bastion_key_name = "landandbay-bastion"  # Must match the name you used in AWS Console
   bastion_public_key = ""                  # Leave empty to use existing key
   ```

3. The infrastructure will use this key pair for the bastion host.

> **Note**: By default, the infrastructure assumes that key pairs already exist in AWS and won't try to create them. To create a new key pair, you must:
>
> 1. Set `create_new_key_pair = true`
> 2. Provide a value for `bastion_public_key` (required when `create_new_key_pair = true`)
>
> If `create_new_key_pair = true` but no `bastion_public_key` is provided, the deployment will fail with an error message. This approach prevents conflicts when the key pair already exists in AWS.

4. Connect using the private key you downloaded:
   ```bash
   ssh -i /path/to/landandbay-bastion.pem ec2-user@<bastion-host-public-ip>
   ```

> **Note**: The key difference between Option 1 and Option 2 is who creates and manages the key pair. With Option 1, you create the key pair locally and provide the public key to Terraform. With Option 2, AWS creates and manages the key pair, and you only need to download the private key.

### SSH Tunnel for Database Access

To access the RDS database through the bastion host:

1. Create an SSH tunnel:

   ```bash
   ssh -i ~/.ssh/landandbay-bastion -L 5432:your-rds-endpoint:5432 ec2-user@<bastion-host-public-ip>
   ```

2. Connect to the database using localhost:5432 in your SQL client.

## Core Variables

| Variable Name        | Description                            | Default                                                  | Required                |
| -------------------- | -------------------------------------- | -------------------------------------------------------- | ----------------------- |
| `prefix`             | Prefix to use for resource names       | `landandbay`                                             | No                      |
| `aws_region`         | AWS region to deploy to                | `us-east-1`                                              | No                      |
| `tags`               | Default tags to apply to all resources | `{ Project = "landandbay", Environment = "Production" }` | No                      |
| `bastion_key_name`   | SSH key name for bastion host          | `landandbay-bastion`                                     | No                      |
| `bastion_public_key` | SSH public key for bastion host        | `""`                                                     | Yes, for bastion access |

## Networking Variables

| Variable Name            | Description                                                                | Default | Required                                  |
| ------------------------ | -------------------------------------------------------------------------- | ------- | ----------------------------------------- |
| `create_vpc`             | Whether to create a new VPC                                                | `true`  | No                                        |
| `vpc_id`                 | ID of existing VPC (if `create_vpc` is false)                              | `""`    | Yes, if `create_vpc` is false             |
| `create_public_subnets`  | Whether to create new public subnets                                       | `true`  | No                                        |
| `public_subnet_ids`      | IDs of existing public subnets (if `create_public_subnets` is false)       | `[]`    | Yes, if `create_public_subnets` is false  |
| `create_private_subnets` | Whether to create new private app subnets                                  | `true`  | No                                        |
| `private_subnet_ids`     | IDs of existing private app subnets (if `create_private_subnets` is false) | `[]`    | Yes, if `create_private_subnets` is false |
| `create_db_subnets`      | Whether to create new database subnets                                     | `true`  | No                                        |
| `db_subnet_ids`          | IDs of existing database subnets (if `create_db_subnets` is false)         | `[]`    | Yes, if `create_db_subnets` is false      |

## Database Variables

| Variable Name         | Description                                             | Default          | Required                    |
| --------------------- | ------------------------------------------------------- | ---------------- | --------------------------- |
| `use_secrets_manager` | Enable AWS Secrets Manager integration                  | `true`           | No                          |
| `db_username`         | Master database username (used only for initial setup)  | `postgres_admin` | No                          |
| `db_password`         | Master database password (used only for initial setup)  | n/a              | Yes, for initial setup only |
| `app_db_username`     | Application database username                           | `app_user`       | No                          |
| `app_db_password`     | Application database password (auto-generated if empty) | `""`             | No                          |
| `db_name`             | Database name                                           | `landandbay`     | No                          |
| `auto_setup_database` | Whether to automatically run database setup             | `false`          | No                          |

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

### Automated Database Setup

```hcl
module "infrastructure" {
  source = "./terraform"

  # Enable automated database setup
  auto_setup_database = true

  # Required variables
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
  create_new_key_pair = true  # Set to true to create a new key pair, false to use existing

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

## Deployment Workflows

### Automated Deployment (Recommended for Development)

```bash
# Option 1: Use terraform.tfvars file
# Create or update terraform.tfvars (safely)
if [ -f terraform.tfvars ] && grep -q "^auto_setup_database" terraform.tfvars; then
  # Update existing variable
  sed -i.bak 's/^auto_setup_database.*/auto_setup_database = true/' terraform.tfvars
else
  # Add new variable (safe append)
  echo 'auto_setup_database = true' >> terraform.tfvars
fi

# Deploy everything at once
terraform apply

# Option 2: Use command-line variable (recommended for CI/CD)
terraform apply -var="auto_setup_database=true"

# Database setup runs automatically
# ✅ Done!
```

### Manual Deployment (Recommended for Production)

```bash
# Option 1: Use terraform.tfvars
# Ensure manual setup in terraform.tfvars
if grep -q "^auto_setup_database" terraform.tfvars; then
  sed -i.bak 's/^auto_setup_database.*/auto_setup_database = false/' terraform.tfvars
else
  echo 'auto_setup_database = false' >> terraform.tfvars
fi

# Deploy infrastructure first
terraform apply

# Option 2: Use command-line variable
terraform apply -var="auto_setup_database=false"

# Run database setup manually with full control
./db_setup.sh --endpoint $(terraform output -raw database_endpoint)

# You'll be prompted for the master password
# ✅ Done!
```

### CI/CD Pipeline Deployment

```bash
# Method 1: Environment-specific tfvars files
# dev.tfvars
auto_setup_database = true

# prod.tfvars
auto_setup_database = false

# Deploy with specific file
terraform apply -var-file="dev.tfvars"
terraform apply -var-file="prod.tfvars"

# Method 2: Command-line overrides (safest)
# Development
terraform apply -var="auto_setup_database=true"

# Production
terraform apply -var="auto_setup_database=false"
if [ $? -eq 0 ]; then
  # Run database setup in controlled environment
  $(terraform output -raw database_setup_command)
fi

# ✅ Done with full logging and error handling
```

## Best Practices

### General

1. **Never hardcode credentials** in Terraform files or environment variables
2. **Use remote state storage** for production deployments
3. **Use Terraform workspaces** for different environments
4. **Validate prerequisites** before running deployments

### Security

1. **Use Secrets Manager** for all production deployments
2. **Update credentials** manually through AWS Secrets Manager when needed
3. **Limit access** to the secrets using IAM policies
4. **Monitor access** to secrets through CloudTrail
5. **Use encrypted communications** for all database connections
6. **Store SSH keys securely** and never commit private keys to repositories
7. **Store public keys as secrets** in your CI/CD platform rather than in code
8. **Rotate SSH keys periodically** for enhanced security
9. **Use separate security groups** for each component (load balancer, application, database)

### Database Management

1. **Run database setup script** after infrastructure deployment
2. **Validate password encoding** for special characters
3. **Use URL-safe passwords** to avoid connection string issues
4. **Test database connectivity** through bastion host
5. **Monitor database performance** and adjust instance sizes as needed

### Networking

1. **Evaluate existing VPC** resources before creating new ones
2. **Use private subnets** for applications where possible
3. **Isolate database subnets** from direct internet access
4. **Use bastion hosts** for controlled access to private resources
5. **Limit bastion host access** to specific IP addresses when possible
6. **Implement proper security group rules** following least privilege principle

### Troubleshooting

1. **Check prerequisite tools** (Python3, AWS CLI, psql) before deployment
2. **Review Terraform logs** for detailed error information
3. **Test database connectivity** manually if automated setup fails
4. **Verify AWS permissions** for Secrets Manager and RDS operations
5. **Use manual database setup** for debugging complex issues

## Common Issues and Solutions

### Database Setup Issues

**Problem**: Database setup fails with URL encoding errors

```
ERROR: Failed to URL encode password using Python3
```

**Solution**:

- Ensure Python3 is installed and available in PATH
- Regenerate password with only URL-safe characters
- Use manual database setup for full control

**Problem**: PostgreSQL client not found

```
ERROR: psql command not found
```

**Solutions**:

- **Ubuntu/Debian**: `sudo apt-get install postgresql-client`
- **CentOS/RHEL**: `sudo yum install postgresql`
- **macOS**: `brew install postgresql`

**Problem**: AWS CLI not configured properly

```
ERROR: AWS CLI is not properly configured or lacks permissions
```

**Solution**:

- Run `aws configure` to set up credentials
- Ensure IAM user has permissions for:
  - Secrets Manager (GetSecretValue, UpdateSecret, CreateSecret)
  - RDS (DescribeDBInstances)
  - KMS (Decrypt, DescribeKey)

### Terraform Issues

**Problem**: Security group unused variable warning

```
Warning: variable "app_security_group_id" is declared but not used
```

**Solution**: This is resolved in the updated configuration. The load balancer now uses its own dedicated security group (`alb_security_group_id`) instead of the application security group.

**Problem**: null_resource fails with script not found

```
ERROR: db_setup.sh not found
```

**Solution**: Ensure the `db_setup.sh` script is in the same directory as your main Terraform files and is executable:

```bash
chmod +x db_setup.sh
```

### Network Connectivity Issues

**Problem**: Cannot connect to RDS through bastion host

```
Connection timeout when accessing database
```

**Solutions**:

1. Verify security groups allow traffic:
   - Bastion SG allows SSH (22) from your IP
   - Database SG allows PostgreSQL (5432) from bastion SG
2. Check SSH tunnel command:
   ```bash
   ssh -i key.pem ec2-user@bastion-ip -L 5432:db-endpoint:5432
   ```
3. Verify RDS instance is in "available" state

**Problem**: Load balancer cannot reach application containers

```
502 Bad Gateway errors from load balancer
```

**Solution**: Ensure security groups are properly configured:

- ALB security group can send traffic to app on port 8000
- App security group accepts traffic from ALB security group on port 8000

## File Structure

Your complete project structure should look like this:

```
terraform/
├── main.tf                          # Main Terraform configuration
├── variables.tf                     # Input variables
├── outputs.tf                       # Output values
├── backend.tf                       # Remote state configuration
├── versions.tf                      # Provider version constraints
├── db_setup.sh                      # Database setup script (executable)
├── setup_remote_state.sh            # Remote state setup script
├── modules/
│   ├── compute/
│   │   ├── main.tf                  # ECS, ECR, Bastion host
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── database/
│   │   ├── main.tf                  # RDS, Parameter groups
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── versions.tf
│   │   └── README.md                # Database module documentation
│   ├── dns/
│   │   ├── main.tf                  # Route53 records
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── loadbalancer/
│   │   ├── main.tf                  # ALB, Target groups, Listeners
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── monitoring/
│   │   ├── main.tf                  # CloudWatch, S3 logs, Budgets
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── networking/
│   │   ├── main.tf                  # VPC, Subnets, Route tables
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── secrets/
│   │   ├── main.tf                  # Secrets Manager, KMS
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   └── security/
│       ├── main.tf                  # Security groups, WAF
│       ├── variables.tf
│       ├── outputs.tf
│       └── versions.tf
└── terraform.tfvars                 # Variable values (gitignored)
```

## Security Considerations

### Production Deployment Checklist

- [ ] **Secrets Management**: All credentials stored in AWS Secrets Manager
- [ ] **Network Security**: Proper security group rules implemented
- [ ] **Encryption**: KMS encryption enabled for RDS and Secrets Manager
- [ ] **Access Control**: IAM roles follow least privilege principle
- [ ] **Monitoring**: CloudWatch logging and budget alerts configured
- [ ] **Backup**: RDS automated backups enabled (14-day retention)
- [ ] **SSH Keys**: Secure key management for bastion host access
- [ ] **WAF**: Web Application Firewall rules active
- [ ] **Database Access**: No direct internet access to database

### Security Group Rules Summary

| Component         | Inbound                      | Outbound                             | Purpose                 |
| ----------------- | ---------------------------- | ------------------------------------ | ----------------------- |
| **Load Balancer** | 80,443 from 0.0.0.0/0        | 8000 to App SG                       | Internet → ALB → App    |
| **Application**   | 8000 from ALB SG             | 5432 to DB SG, 80,443 to 0.0.0.0/0   | ALB → App → DB/Internet |
| **Database**      | 5432 from App SG, Bastion SG | Return traffic to App SG, Bastion SG | App/Bastion → DB        |
| **Bastion**       | 22 from specified CIDRs      | All traffic to 0.0.0.0/0             | Admin SSH access        |

## Support and Maintenance

### Regular Maintenance Tasks

1. **Monthly**: Review CloudWatch logs and metrics
2. **Quarterly**: Update Terraform provider versions
3. **Bi-annually**: Rotate SSH keys and database passwords
4. **Annually**: Review and update security group rules

### Getting Help

1. **Terraform Issues**: Check Terraform plan output and state files
2. **AWS Issues**: Review CloudWatch logs and AWS service health
3. **Database Issues**: Use bastion host for direct troubleshooting
4. **Security Issues**: Review WAF logs and security group rules

### Version Information

- **Terraform**: >= 1.12.0
- **AWS Provider**: ~> 5.99.0
- **PostgreSQL**: 16.9
- **Node.js/Container Runtime**: As specified in application

This infrastructure configuration provides a robust, secure, and scalable foundation for the Land and Bay Stewards application with comprehensive documentation and troubleshooting guidance.
