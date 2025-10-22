# CI/CD Pipeline Module

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

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
      value = data.aws_region.current.id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "terraform/buildspec-terraform.yml"
  }

  tags = var.tags
}

resource "aws_codebuild_project" "webapp" {
  name         = "ecommerce-webapp"
  description  = "Web application build and deploy project"
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
      name  = "FRONTEND_BUCKET"
      value = var.frontend_bucket_name
    }

    environment_variable {
      name  = "CLOUDFRONT_DIST_ID"
      value = var.cloudfront_distribution_id
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
      value = data.aws_region.current.id
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "web_app/buildspec-webapp.yml"
  }

  tags = var.tags
}

# CodePipeline
resource "aws_codepipeline" "pipeline" {
  name     = "ecommerce-pipeline"
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
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_owner
        Repo       = var.github_repo
        Branch     = var.github_branch
        OAuthToken = var.github_token
      }
    }
  }

  stage {
    name = "Infrastructure"

    action {
      name             = "TerraformBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["terraform_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.terraform.name
      }
    }
  }

  stage {
    name = "Application"

    action {
      name             = "WebAppBuild"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["webapp_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.webapp.name
      }
    }
  }

  # SNS notification action not available in us-east-1
  # Using CloudWatch Events for notifications instead

  tags = var.tags
}
