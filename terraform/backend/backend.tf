terraform {
  backend "s3" {
    bucket         = "<REPLACE_WITH_YOUR_BUCKET>"
    key            = "terraform/state/${var.environment}/terraform.tfstate"
    region         = "<REPLACE_WITH_REGION>"
    dynamodb_table = "<REPLACE_WITH_DYNAMODB_TABLE>"
    encrypt        = true
  }
}
