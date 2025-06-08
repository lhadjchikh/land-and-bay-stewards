#!/bin/bash
# This script sets up the remote state resources for Terraform

set -euo pipefail

# Get AWS account ID for unique bucket naming
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Configuration
S3_BUCKET_NAME="coalition-terraform-state-${ACCOUNT_ID}"
DYNAMODB_TABLE_NAME="coalition-terraform-locks"
REGION="us-east-1"

echo "Using S3 bucket: $S3_BUCKET_NAME"

# Create S3 bucket for state if it doesn't exist
if ! aws s3api head-bucket --bucket "$S3_BUCKET_NAME" 2>/dev/null; then
  echo "Creating S3 bucket for Terraform state..."
  aws s3api create-bucket \
    --bucket "$S3_BUCKET_NAME" \
    --region $REGION

  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket "$S3_BUCKET_NAME" \
    --versioning-configuration Status=Enabled

  # Enable encryption
  aws s3api put-bucket-encryption \
    --bucket "$S3_BUCKET_NAME" \
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
    --bucket "$S3_BUCKET_NAME" \
    --public-access-block-configuration '{
      "BlockPublicAcls": true,
      "IgnorePublicAcls": true,
      "BlockPublicPolicy": true,
      "RestrictPublicBuckets": true
    }'

  # Add lifecycle policy to automatically delete test state files
  aws s3api put-bucket-lifecycle-configuration \
    --bucket "$S3_BUCKET_NAME" \
    --lifecycle-configuration '{
      "Rules": [
        {
          "ID": "DeleteTestStates",
          "Status": "Enabled",
          "Filter": {"Prefix": "tests/"},
          "Expiration": {"Days": 7}
        },
        {
          "ID": "DeleteOldVersions",
          "Status": "Enabled",
          "Filter": {},
          "NoncurrentVersionExpiration": {"NoncurrentDays": 90}
        }
      ]
    }'

  echo "S3 bucket created and configured with lifecycle policies."
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

# Create backend configuration file for this account
cat >backend.hcl <<EOF
bucket         = "${S3_BUCKET_NAME}"
key            = "production/terraform.tfstate"
region         = "${REGION}"
encrypt        = true
dynamodb_table = "${DYNAMODB_TABLE_NAME}"
EOF

echo "Remote state setup complete!"
echo "S3 bucket: ${S3_BUCKET_NAME}"
echo "DynamoDB table: ${DYNAMODB_TABLE_NAME}"
echo ""
echo "To initialize Terraform with this backend, run:"
echo "  terraform init -backend-config=backend.hcl"
