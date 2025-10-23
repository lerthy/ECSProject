# Variables for CI/CD module

variable "aws_region" {
	description = "AWS region"
	type        = string
}

variable "github_owner" {
	description = "GitHub repository owner (your username, not necessarily the original repo owner)"
	type        = string
}

variable "github_repo" {
	description = "GitHub repository name (can be a fork)"
	type        = string
}

variable "github_branch" {
	description = "GitHub branch to build from"
	type        = string
	default     = "main"
}

variable "github_token" {
	description = "GitHub OAuth token for your account"
	type        = string
	sensitive   = true
}

variable "sns_topic_arn" {
	description = "SNS topic ARN for notifications (optional)"
	type        = string
	default     = ""
}

variable "terraform_state_bucket" {
	description = "S3 bucket for Terraform state"
	type        = string
}

variable "terraform_state_key" {
	description = "S3 key for Terraform state file"
	type        = string
	default     = "state/terraform.tfstate"
}

variable "ecr_repository_url" {
	description = "ECR repository URL for Docker images"
	type        = string
}

variable "ecs_cluster_name" {
	description = "ECS cluster name"
	type        = string
}

variable "ecs_service_name" {
	description = "ECS service name"
	type        = string
}

variable "frontend_bucket_name" {
	description = "S3 bucket name for frontend assets"
	type        = string
}

variable "cloudfront_distribution_id" {
	description = "CloudFront distribution ID"
	type        = string
	default     = ""
}

variable "alb_name" {
	description = "Application Load Balancer name"
	type        = string
}

variable "app_health_url" {
	description = "Application health check URL"
	type        = string
}

variable "tags" {
	description = "A map of tags to assign to the resources"
	type        = map(string)
	default     = {}
}