terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

resource "aws_ecr_repository" "backend" {
  count                = var.create_repository ? 1 : 0
  name                 = "ecommerce-backend-${var.environment}"
  tags                 = var.tags
  image_tag_mutability = "MUTABLE"
}

# Data source for existing ECR repository
data "aws_ecr_repository" "backend" {
  count = var.create_repository ? 0 : 1
  name  = "ecommerce-backend-${var.environment}"
}
