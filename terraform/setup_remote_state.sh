#!/bin/bash
# This script sets up the remote state resources for Terraform

set -euo pipefail

# Configuration
S3_BUCKET_NAME="landandbay-terraform-state"
DYNAMODB_TABLE_NAME="landandbay-terraform-locks"
REGION="us-east-1"

# Create S3 bucket for state if it doesn't exist
if ! aws s3api head-bucket --bucket $S3_BUCKET_NAME 2>/dev/null; then
  echo "Creating S3 bucket for Terraform state..."
  aws s3api create-bucket \
    --bucket $S3_BUCKET_NAME \
    --region $REGION

  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket $S3_BUCKET_NAME \
    --versioning-configuration Status=Enabled

  # Enable encryption
  aws s3api put-bucket-encryption \
    --bucket $S3_BUCKET_NAME \
    --server-side-encryption-configuration '{
      "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }
      ]
    }'

  # Block public access
  aws s3api put-public-access-block \
    --bucket $S3_BUCKET_NAME \
    --public-access-block-configuration '{
      "BlockPublicAcls": true,
      "IgnorePublicAcls": true,
      "BlockPublicPolicy": true,
      "RestrictPublicBuckets": true
    }'
    
  echo "S3 bucket created and configured."
else
  echo "S3 bucket already exists."
fi

# Create DynamoDB table for state locking if it doesn't exist
if ! aws dynamodb describe-table --table-name $DYNAMODB_TABLE_NAME 2>/dev/null; then
  echo "Creating DynamoDB table for Terraform state locking..."
  aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION
    
  echo "DynamoDB table created."
else
  echo "DynamoDB table already exists."
fi

echo "Remote state setup complete. Terraform is now configured to use remote state."