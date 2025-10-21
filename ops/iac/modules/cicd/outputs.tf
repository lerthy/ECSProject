# Outputs for CI/CD module

output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.pipeline.arn
}

output "artifacts_bucket_name" {
  description = "Name of the S3 bucket used for pipeline artifacts"
  value       = aws_s3_bucket.artifacts.bucket
}

output "artifacts_bucket_arn" {
  description = "ARN of the S3 bucket used for pipeline artifacts"
  value       = aws_s3_bucket.artifacts.arn
}

output "terraform_build_project_name" {
  description = "Name of the Terraform CodeBuild project"
  value       = aws_codebuild_project.terraform.name
}

output "webapp_build_project_name" {
  description = "Name of the Web App CodeBuild project"
  value       = aws_codebuild_project.webapp.name
}

output "codepipeline_role_arn" {
  description = "ARN of the CodePipeline service role"
  value       = aws_iam_role.codepipeline.arn
}

output "codebuild_role_arn" {
  description = "ARN of the CodeBuild service role"
  value       = aws_iam_role.codebuild.arn
}
