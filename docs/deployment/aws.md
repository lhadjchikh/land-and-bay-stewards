# Deploying to Amazon ECS with Terraform

This guide explains how to deploy the Coalition Builder application to Amazon ECS (Elastic Container Service) using Terraform
and GitHub Actions. The application is built with Python 3.13 and PostgreSQL 16 with PostGIS extension.

## Overview

This deployment strategy uses:

- **Terraform** to provision and manage AWS infrastructure
- **GitHub Actions** for CI/CD pipeline
- **Amazon ECS** for container orchestration
- **Amazon ECR** for container registry
- **Amazon RDS** for PostgreSQL with PostGIS
- **Application Load Balancer** for routing traffic
- **AWS Secrets Manager** for secure credentials management

## Prerequisites

1. An AWS account with appropriate permissions
2. GitHub repository with your code
3. AWS credentials with the following permissions:
   - ECR full access
   - ECS full access
   - VPC and networking permissions
   - RDS permissions
   - CloudWatch Logs permissions
   - IAM permissions to create roles and policies

## Setup

### 1. Configure Environment Variables

For local testing and development with Terraform, you can use the `.env` file in the project root:

```bash
# AWS deployment settings
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key

# Domain and certificate settings
TF_VAR_aws_region=us-east-1
TF_VAR_db_name=your-db-name
TF_VAR_route53_zone_id=your-route53-zone-id
TF_VAR_domain_name=yourdomain.org
TF_VAR_acm_certificate_arn=your-acm-certificate-arn
TF_VAR_alert_email=your-email@example.com

# Secrets Manager configuration
TF_VAR_use_secrets_manager=true

# Terraform directory
TERRAFORM_DIR=terraform
```

> **IMPORTANT**: For security best practices, database credentials are stored in AWS Secrets Manager rather than specified directly in environment variables. See the "Secure Credentials Management" section below.

### 2. Configure GitHub Secrets

For CI/CD deployment, add the following secrets to your GitHub repository:

1.  `AWS_ACCESS_KEY_ID`: Your AWS access key
2.  `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
3.  `AWS_REGION`: The AWS region to deploy to (e.g., `us-east-1`)
4.  `TF_VAR_db_name`: Database name (default: `coalition`)
5.  `TF_VAR_route53_zone_id`: Your Route 53 hosted zone ID
6.  `TF_VAR_domain_name`: Your domain name (e.g., `app.mydomain.org` or `mydomain.org`)
7.  `TF_VAR_acm_certificate_arn`: The ARN of your ACM certificate for HTTPS
8.  `TF_VAR_alert_email`: Email address to receive budget and other alerts
9.  `TF_VAR_use_secrets_manager`: Set to `true` to use AWS Secrets Manager (recommended for production)

> **IMPORTANT**: Database credentials (`DB_USERNAME`, `DB_PASSWORD`, `APP_DB_USERNAME`, `APP_DB_PASSWORD`) are managed through AWS Secrets Manager for security rather than GitHub Secrets. For initial setup only, you may need to provide these values once, after which they will be securely stored.

To add these secrets:

1. Go to your GitHub repository
2. Click on "Settings" > "Secrets and variables" > "Actions"
3. Click "New repository secret" and add each secret

### 3. Secure Credentials Management with AWS Secrets Manager

Before deployment, set up your database credentials in AWS Secrets Manager:

1. **Create a secret for database master credentials**:

   ```bash
   aws secretsmanager create-secret \
     --name coalition/database-master \
     --description "PostgreSQL master database credentials" \
     --secret-string '{"username":"your_secure_username","password":"your_secure_password","host":"pending-db-creation","port":"5432","dbname":"coalition"}'
   ```

2. **Create a secret for application database credentials** (optional, will be auto-generated if not provided):

   ```bash
   aws secretsmanager create-secret \
     --name coalition/database-app \
     --description "PostgreSQL application database credentials" \
     --secret-string '{"username":"app_user","password":"your_secure_app_password","host":"pending-db-creation","port":"5432","dbname":"coalition"}'
   ```

> **IMPORTANT**: Once these secrets are created, Terraform will use them for all deployments. For initial setup, if no secrets exist yet, Terraform will create them using secure random passwords.

### 4. Initial Deployment

The initial deployment will be triggered automatically when you push to the main branch, or you can manually trigger it:

1. Go to the "Actions" tab in your GitHub repository
2. Select the "Deploy to Amazon ECS" workflow
3. Click "Run workflow" and select the main branch

The workflow consists of two jobs:

1. **Terraform**: Sets up all AWS infrastructure
2. **Deploy**: Builds and deploys the application container

### 5. PostGIS Extension Setup

After the initial deployment, you need to enable the PostGIS extension in the RDS database:

1. Connect to your RDS instance:

   ```bash
   # Get database connection details from Secrets Manager
   aws secretsmanager get-secret-value --secret-id coalition/database-master --query SecretString --output text | jq .

   # Connect to the database (replace values with those from the secret)
   psql -h <database_endpoint> -U <master_username> -d coalition
   ```

   (You can also get the database_endpoint from Terraform outputs by running: `terraform -chdir=terraform output database_endpoint`)

2. Create the PostGIS extension:

   ```sql
   CREATE EXTENSION postgis;
   ```

3. Verify the PostGIS installation:

   ```sql
   SELECT PostGIS_version();
   ```

## Infrastructure Details

The Terraform configuration creates:

1. **Networking**:

   - VPC with public subnets
   - Internet Gateway
   - Security Groups

2. **Database**:

   - Amazon RDS PostgreSQL instance
   - Custom parameter group for PostGIS

3. **Security**:

   - AWS Secrets Manager for secure credential storage
   - IAM roles with least privilege access
   - KMS keys for encryption
   - Secure credential management

4. **Container Infrastructure**:

   - ECR Repository
   - ECS Cluster
   - ECS Task Definition
   - ECS Service
   - IAM Roles for ECS tasks

5. **Load Balancing**:

   - Application Load Balancer
   - Target Group
   - Listener

6. **Cost Management**:

   - Monthly budget alert ($30)
   - Notification thresholds at 70%, 90%, and forecast
   - Email notifications for budget alerts

## Continuous Deployment

Every time you push to the main branch, the GitHub Actions workflow will:

1. Run the Terraform job to ensure infrastructure is up-to-date
2. Run tests to validate your application
3. Build a Docker image and push it to ECR
4. Deploy the updated image to ECS
5. Wait for the service to stabilize

## Customization

### Modifying Infrastructure

To modify the infrastructure:

1. Edit files in the `terraform` directory
2. Commit and push the changes
3. The GitHub Actions workflow will apply your changes

### Scaling the Application

To scale your application:

1. Edit the `desired_count` parameter in `terraform/main.tf`
2. Adjust the CPU and memory allocations in the task definition if needed
3. Commit and push the changes

### Custom Domain Name

To use a custom domain name:

1. The Route 53 and HTTPS configuration is already enabled in `terraform/main.tf`
2. You need to add the following GitHub secrets:
   - `TF_VAR_route53_zone_id`: Your Route 53 hosted zone ID
   - `TF_VAR_domain_name`: Your domain name (e.g., `app.mydomain.org` or `mydomain.org`)
   - `TF_VAR_acm_certificate_arn`: The ARN of your ACM certificate

> **Note**: You must have already created an ACM certificate for your domain. If you don't have one, you can create it
> in the AWS console or use Terraform to provision it.

## Monitoring and Logs

Your application logs are sent to CloudWatch Logs:

1. Go to CloudWatch in the AWS Console
2. Navigate to "Log groups"
3. Find the `/ecs/coalition` log group

### Cost Monitoring

A monthly budget alert is set up to help monitor AWS costs:

1. The budget is set to $30 per month
2. You'll receive email notifications at the following thresholds:
   - When you reach 70% of your budget ($21)
   - When you reach 90% of your budget ($27)
   - When AWS forecasts that you'll exceed your budget

To view or modify the budget:

1. Go to the AWS Billing Dashboard
2. Navigate to "Budgets"
3. Select the "coalition-monthly-budget"

> **Important**: Make sure to set the `TF_VAR_alert_email` variable with a valid email address to receive these alerts.
> If you change the email address, you'll need to redeploy the infrastructure.

#### Cost Allocation Tags

All resources are automatically tagged with essential AWS provider tags and two custom tags:

- `Project`: Identifies all resources as part of "Coalition Builder"
- `Environment`: Specifies the deployment environment (e.g., "Production")

AWS Cost Explorer and AWS Budgets can use these tags for cost tracking and allocation. Resources are also automatically
tracked by their creator (Terraform) for budget monitoring.

## Cleanup

To clean up all AWS resources:

> **IMPORTANT**: Before attempting to destroy the infrastructure, you must disable deletion protection on the RDS
> database. The terraform destroy will fail if you don't complete this step first.

1. Disable RDS deletion protection by editing `terraform/main.tf` and setting `deletion_protection = false` in the
   `aws_db_instance` resource, then applying the change:

   ```bash
   terraform -chdir=terraform apply -target=aws_db_instance.postgres
   ```

2. Create a new workflow file in `.github/workflows/terraform-destroy.yml`

   ```yaml
   name: Terraform Destroy

   on:
     workflow_dispatch:

   env:
     AWS_REGION: ${{ secrets.AWS_REGION }}
     TF_VAR_aws_region: ${{ secrets.AWS_REGION }}
     TF_VAR_db_name: ${{ secrets.TF_VAR_db_name || 'coalition' }}
     TF_VAR_route53_zone_id: ${{ secrets.TF_VAR_route53_zone_id }}
     TF_VAR_domain_name: ${{ secrets.TF_VAR_domain_name }}
     TF_VAR_acm_certificate_arn: ${{ secrets.TF_VAR_acm_certificate_arn }}
     TF_VAR_alert_email: ${{ secrets.TF_VAR_alert_email }}
     TF_VAR_use_secrets_manager: ${{ secrets.TF_VAR_use_secrets_manager || 'true' }}
     TERRAFORM_DIR: terraform

   jobs:
     destroy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4

         - name: Configure AWS credentials
           uses: aws-actions/configure-aws-credentials@v4
           with:
             aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
             aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
             aws-region: ${{ env.AWS_REGION }}

         - name: Setup Terraform
           uses: hashicorp/setup-terraform@v3

         - name: Terraform Init
           working-directory: ${{ env.TERRAFORM_DIR }}
           run: terraform init

         - name: Terraform Destroy
           working-directory: ${{ env.TERRAFORM_DIR }}
           run: terraform destroy -auto-approve
   ```

3. Run the "Terraform Destroy" workflow from the Actions tab
