# Configure remote state storage in S3 with DynamoDB locking
# All backend configuration should be provided via backend.hcl or -backend-config
terraform {
  backend "s3" {}
}