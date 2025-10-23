output "ecr_backend_repository_arn" {
  description = "ARN of the ECR backend repository"
  value       = var.create_repository ? aws_ecr_repository.backend[0].arn : data.aws_ecr_repository.backend[0].arn
}

output "repository_url" {
  description = "URL of the ECR backend repository"
  value       = var.create_repository ? aws_ecr_repository.backend[0].repository_url : data.aws_ecr_repository.backend[0].repository_url
}
