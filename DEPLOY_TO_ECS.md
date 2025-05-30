# Deploying to Amazon ECS with Terraform

This guide explains how to deploy the Land and Bay Stewards application to Amazon ECS (Elastic Container Service) using Terraform and GitHub Actions.

## Overview

This deployment strategy uses:
- **Terraform** to provision and manage AWS infrastructure
- **GitHub Actions** for CI/CD pipeline
- **Amazon ECS** for container orchestration
- **Amazon ECR** for container registry
- **Amazon RDS** for PostgreSQL with PostGIS
- **Application Load Balancer** for routing traffic

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

### 1. Configure GitHub Secrets

In your GitHub repository, add the following secrets:

1. `AWS_ACCESS_KEY_ID`: Your AWS access key
2. `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
3. `AWS_REGION`: The AWS region to deploy to (e.g., `us-west-2`)
4. `DB_USERNAME`: Database username (default: `postgres`)
5. `DB_PASSWORD`: A secure password for the database
6. `TF_VAR_route53_zone_id`: Your Route 53 hosted zone ID
7. `TF_VAR_domain_name`: Your domain name (e.g., `app.example.com`) 
8. `TF_VAR_acm_certificate_arn`: The ARN of your ACM certificate for HTTPS

To add these secrets:
1. Go to your GitHub repository
2. Click on "Settings" > "Secrets and variables" > "Actions"
3. Click "New repository secret" and add each secret

### 2. Initial Deployment

The initial deployment will be triggered automatically when you push to the main branch, or you can manually trigger it:

1. Go to the "Actions" tab in your GitHub repository
2. Select the "Deploy to Amazon ECS" workflow
3. Click "Run workflow" and select the main branch

The workflow consists of two jobs:
1. **Terraform**: Sets up all AWS infrastructure
2. **Deploy**: Builds and deploys the application container

### 3. PostGIS Extension Setup

After the initial deployment, you need to enable the PostGIS extension in the RDS database:

1. Connect to your RDS instance:
   ```bash
   psql -h <database_endpoint> -U postgres -d labs
   ```
   (Get the database_endpoint from Terraform outputs by running: `terraform -chdir=terraform output database_endpoint`)

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

3. **Container Infrastructure**:
   - ECR Repository
   - ECS Cluster
   - ECS Task Definition
   - ECS Service
   - IAM Roles for ECS tasks

4. **Load Balancing**:
   - Application Load Balancer
   - Target Group
   - Listener

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
   - `TF_VAR_domain_name`: Your domain name (e.g., `app.example.com`)
   - `TF_VAR_acm_certificate_arn`: The ARN of your ACM certificate

> **Note**: You must have already created an ACM certificate for your domain. If you don't have one, you can create it in the AWS console or use Terraform to provision it.

## Monitoring and Logs

Your application logs are sent to CloudWatch Logs:

1. Go to CloudWatch in the AWS Console
2. Navigate to "Log groups"
3. Find the `/ecs/land-and-bay-stewards` log group

## Cleanup

To clean up all AWS resources:

> **IMPORTANT**: Before attempting to destroy the infrastructure, you must disable deletion protection on the RDS database. The terraform destroy will fail if you don't complete this step first.

1. Disable RDS deletion protection by editing `terraform/main.tf` and setting `deletion_protection = false` in the `aws_db_instance` resource, then applying the change:

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
     TF_VAR_db_username: ${{ secrets.DB_USERNAME }}
     TF_VAR_db_password: ${{ secrets.DB_PASSWORD }}
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