resource "aws_ecr_repository" "backend" {
  name                 = "ecommerce-backend-${var.environment}"
  tags                 = var.tags
  image_tag_mutability = "MUTABLE"
}
