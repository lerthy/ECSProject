# CI/CD Pipeline Module

# Data sources
data "aws_caller_identity" "current" {}

# S3 bucket for pipeline artifacts
resource "aws_s3_bucket" "artifacts" {
	bucket        = "ecommerce-cicd-artifacts-${random_string.suffix.result}"
	force_destroy = true

	tags = var.tags
}

resource "aws_s3_bucket_versioning" "artifacts" {
	bucket = aws_s3_bucket.artifacts.id
	versioning_configuration {
		status = "Enabled"
	}
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
	bucket = aws_s3_bucket.artifacts.id

	rule {
		apply_server_side_encryption_by_default {
			sse_algorithm = "AES256"
		}
	}
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
	bucket = aws_s3_bucket.artifacts.id

	block_public_acls       = true
	block_public_policy     = true
	ignore_public_acls      = true
	restrict_public_buckets = true
}

resource "random_string" "suffix" {
	length  = 8
	special = false
	upper   = false
}

# CodeBuild projects
resource "aws_codebuild_project" "terraform" {
	name         = "ecommerce-terraform"
	description  = "Terraform infrastructure build project"
	service_role = aws_iam_role.codebuild.arn

	artifacts {
		type = "CODEPIPELINE"
	}

	environment {
		compute_type                = "BUILD_GENERAL1_MEDIUM"
		image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
		type                        = "LINUX_CONTAINER"
		image_pull_credentials_type = "CODEBUILD"

		environment_variable {
			name  = "TF_BACKEND_BUCKET"
			value = var.terraform_state_bucket
		}

		environment_variable {
			name  = "TF_BACKEND_KEY"
			value = var.terraform_state_key
		}

		environment_variable {
			name  = "AWS_DEFAULT_REGION"
			value = var.aws_region
		}
	}

	source {
		type      = "CODEPIPELINE"
		buildspec = "buildspec-terraform.yml"
	}

	tags = var.tags
}

# Added security scanning project per best practices
resource "aws_codebuild_project" "security_scan" {
	name         = "ecommerce-security-scan"
	description  = "Security scanning for infrastructure code"
	service_role = aws_iam_role.codebuild.arn

	artifacts {
		type = "CODEPIPELINE"
	}

	environment {
		compute_type                = "BUILD_GENERAL1_SMALL"
		image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
		type                        = "LINUX_CONTAINER"
		image_pull_credentials_type = "CODEBUILD"
	}

	source {
		type      = "CODEPIPELINE"
		buildspec = "buildspec-security-scan.yml"
	}

	tags = var.tags
}

resource "aws_codebuild_project" "frontend" {
	name         = "ecommerce-frontend"
	description  = "Frontend web application build and deploy project"
	service_role = aws_iam_role.codebuild.arn

	artifacts {
		type = "CODEPIPELINE"
	}

	environment {
		compute_type                = "BUILD_GENERAL1_MEDIUM"
		image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
		type                        = "LINUX_CONTAINER"
		image_pull_credentials_type = "CODEBUILD"

		environment_variable {
			name  = "FRONTEND_BUCKET"
			value = var.frontend_bucket_name
		}

		environment_variable {
			name  = "CLOUDFRONT_DIST_ID"
			value = var.cloudfront_distribution_id
		}

		environment_variable {
			name  = "AWS_DEFAULT_REGION"
			value = var.aws_region
		}
	}

	source {
		type      = "CODEPIPELINE"
		buildspec = "ops/packages/buildspec-frontend.yml"
	}

	tags = var.tags
}

resource "aws_codebuild_project" "backend" {
	name         = "ecommerce-backend"
	description  = "Backend API build and deploy project"
	service_role = aws_iam_role.codebuild.arn

	artifacts {
		type = "CODEPIPELINE"
	}

	environment {
		compute_type                = "BUILD_GENERAL1_MEDIUM"
		image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
		type                        = "LINUX_CONTAINER"
		image_pull_credentials_type = "CODEBUILD"
		privileged_mode             = true

		environment_variable {
			name  = "ECR_REPO"
			value = var.ecr_repository_url
		}

		environment_variable {
			name  = "ECS_CLUSTER"
			value = var.ecs_cluster_name
		}

		environment_variable {
			name  = "ECS_SERVICE"
			value = var.ecs_service_name
		}

		environment_variable {
			name  = "ALB_NAME"
			value = var.alb_name
		}

		environment_variable {
			name  = "APP_HEALTH_URL"
			value = var.app_health_url
		}

		environment_variable {
			name  = "AWS_DEFAULT_REGION"
			value = var.aws_region
		}
	}

	source {
		type      = "CODEPIPELINE"
		buildspec = "ops/packages/buildspec-backend.yml"
	}

	tags = var.tags
}

# CodePipeline for Infrastructure
resource "aws_codepipeline" "terraform" {
	name     = "ecommerce-terraform-pipeline"
	role_arn = aws_iam_role.codepipeline.arn

	artifact_store {
		location = aws_s3_bucket.artifacts.bucket
		type     = "S3"
	}

	stage {
		name = "Source"

		action {
			name             = "Source"
			category         = "Source"
			owner            = "ThirdParty"
			provider         = "GitHub"
			version          = "1"
			output_artifacts = ["terraform_source"]

			configuration = {
				Owner      = var.github_owner
				Repo       = var.github_repo
				Branch     = var.github_branch
				OAuthToken = var.github_token
			}
		}
	}

	stage {
		name = "Plan"

		action {
			name             = "TerraformPlan"
			category         = "Build"
			owner            = "AWS"
			provider         = "CodeBuild"
			input_artifacts  = ["terraform_source"]
			output_artifacts = ["terraform_plan"]
			version          = "1"

			configuration = {
				ProjectName = aws_codebuild_project.terraform.name
				EnvironmentVariables = jsonencode([
					{
						name  = "TF_COMMAND"
						value = "plan"
					}
				])
			}
		}
	}

	# Added security scanning stage per best practices
	stage {
		name = "SecurityScan"

		action {
			name             = "SecurityScan"
			category         = "Build"
			owner            = "AWS"
			provider         = "CodeBuild"
			input_artifacts  = ["terraform_source"]
			output_artifacts = ["security_scan_results"]
			version          = "1"

			configuration = {
				ProjectName = aws_codebuild_project.security_scan.name
			}
		}
	}

	stage {
		name = "Approval"

		action {
			name     = "ManualApproval"
			category = "Approval"
			owner    = "AWS"
			provider = "Manual"
			version  = "1"

			configuration = {
				CustomData = "Please review the Terraform plan and approve the infrastructure changes. Check the plan output in the previous stage for any unexpected modifications."
			}
		}
	}

	stage {
		name = "Apply"

		action {
			name            = "TerraformApply"
			category        = "Build"
			owner           = "AWS"
			provider        = "CodeBuild"
			input_artifacts = ["terraform_source"]
			version         = "1"

			configuration = {
				ProjectName = aws_codebuild_project.terraform.name
				EnvironmentVariables = jsonencode([
					{
						name  = "TF_COMMAND"
						value = "apply"
					}
				])
			}
		}
	}

	tags = var.tags
}

# CodePipeline for Frontend
resource "aws_codepipeline" "frontend" {
	name     = "ecommerce-frontend-pipeline"
	role_arn = aws_iam_role.codepipeline.arn

	artifact_store {
		location = aws_s3_bucket.artifacts.bucket
		type     = "S3"
	}

	stage {
		name = "Source"

		action {
			name             = "Source"
			category         = "Source"
			owner            = "ThirdParty"
			provider         = "GitHub"
			version          = "1"
			output_artifacts = ["frontend_source"]

			configuration = {
				Owner      = var.github_owner
				Repo       = var.github_repo
				Branch     = var.github_branch
				OAuthToken = var.github_token
			}
		}
	}

	stage {
		name = "Build"

		action {
			name             = "FrontendBuild"
			category         = "Build"
			owner            = "AWS"
			provider         = "CodeBuild"
			input_artifacts  = ["frontend_source"]
			output_artifacts = ["frontend_build"]
			version          = "1"

			configuration = {
				ProjectName = aws_codebuild_project.frontend.name
			}
		}
	}

	stage {
		name = "Approval"

		action {
			name     = "FrontendDeploymentApproval"
			category = "Approval"
			owner    = "AWS"
			provider = "Manual"
			version  = "1"

			configuration = {
				CustomData = "Please review the frontend build and approve the deployment to S3/CloudFront. Verify that the static assets have been built successfully and are ready for production."
			}
		}
	}

	stage {
		name = "Deploy"

		action {
			name            = "FrontendDeploy"
			category        = "Build"
			owner           = "AWS"
			provider        = "CodeBuild"
			input_artifacts = ["frontend_build"]
			version         = "1"

			configuration = {
				ProjectName = aws_codebuild_project.frontend.name
				EnvironmentVariables = jsonencode([
					{
						name  = "DEPLOYMENT_ACTION"
						value = "deploy"
					}
				])
			}
		}
	}

	tags = var.tags
}

# CodePipeline for Backend
resource "aws_codepipeline" "backend" {
	name     = "ecommerce-backend-pipeline"
	role_arn = aws_iam_role.codepipeline.arn

	artifact_store {
		location = aws_s3_bucket.artifacts.bucket
		type     = "S3"
	}

	stage {
		name = "Source"

		action {
			name             = "Source"
			category         = "Source"
			owner            = "ThirdParty"
			provider         = "GitHub"
			version          = "1"
			output_artifacts = ["backend_source"]

			configuration = {
				Owner      = var.github_owner
				Repo       = var.github_repo
				Branch     = var.github_branch
				OAuthToken = var.github_token
			}
		}
	}

	stage {
		name = "Build"

		action {
			name             = "BackendBuild"
			category         = "Build"
			owner            = "AWS"
			provider         = "CodeBuild"
			input_artifacts  = ["backend_source"]
			output_artifacts = ["backend_build"]
			version          = "1"

			configuration = {
				ProjectName = aws_codebuild_project.backend.name
			}
		}
	}

	stage {
		name = "Approval"

		action {
			name     = "DeploymentApproval"
			category = "Approval"
			owner    = "AWS"
			provider = "Manual"
			version  = "1"

			configuration = {
				CustomData = "Please review the application build and approve the deployment to ECS. Verify that the Docker image has been built successfully and security scans have passed."
			}
		}
	}

	stage {
		name = "Deploy"

		action {
			name            = "BackendDeploy"
			category        = "Build"
			owner           = "AWS"
			provider        = "CodeBuild"
			input_artifacts = ["backend_build"]
			version         = "1"

			configuration = {
				ProjectName = aws_codebuild_project.backend.name
				EnvironmentVariables = jsonencode([
					{
						name  = "DEPLOYMENT_ACTION"
						value = "deploy"
					}
				])
			}
		}
	}

	tags = var.tags
}