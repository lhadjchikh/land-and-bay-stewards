# Configure remote state storage in S3 with DynamoDB locking
terraform {
  backend "s3" {
    bucket         = "landandbay-terraform-state"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "landandbay-terraform-locks"
  }
}