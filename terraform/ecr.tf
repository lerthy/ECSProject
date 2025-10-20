# ECR Repository for backend images
# Added for observability completion

resource "aws_ecr_repository" "backend" {
  name                 = "ecommerce-backend-${var.environment}"
  tags                 = var.tags
  image_tag_mutability = "MUTABLE"
}

output "ecr_backend_repository_arn" {
  description = "ARN of the ECR backend repository"
  value       = aws_ecr_repository.backend.arn
}
