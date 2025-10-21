terraform {
  backend "s3" {
    bucket         = "observability-terraform-backend"                      # S3 bucket for Terraform state
    key            = "terraform/state/${var.environment}/terraform.tfstate" # State file path per environment
    region         = "us-east-1"                                            # AWS region
    dynamodb_table = "terraform-state-lock"                                 # DynamoDB table for state locking
    encrypt        = true
  }
}
