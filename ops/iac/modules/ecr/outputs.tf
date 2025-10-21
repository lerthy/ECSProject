output "ecr_backend_repository_arn" {
  description = "ARN of the ECR backend repository"
  value       = aws_ecr_repository.backend.arn
}
