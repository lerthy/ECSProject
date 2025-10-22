# CI/CD Module

This module creates a complete CI/CD pipeline using AWS CodePipeline and CodeBuild for the e-commerce platform.

## Resources Created

- **CodePipeline**: Main pipeline orchestrating the build and deployment process
- **CodeBuild Projects**: 
	- Terraform project for infrastructure deployment
	- Web App project for application build and deployment
- **S3 Bucket**: Artifact storage for pipeline
- **IAM Roles**: Service roles for CodePipeline and CodeBuild with appropriate permissions

## Pipeline Stages

1. **Source**: Pulls code from GitHub repository
2. **Infrastructure**: Runs Terraform to provision/update AWS infrastructure
3. **Application**: Builds and deploys the web application
4. **Notify**: (Optional) Sends notifications via SNS

## Setup for Contributors

If you're not the original repository owner, you'll need to:

1. **Fork the Repository**: Create your own fork of the original repository
2. **Update Configuration**: Set `github_owner` to your GitHub username
3. **GitHub Token**: Create a personal access token with repository permissions
4. **S3 Backend**: Use your own S3 bucket for Terraform state storage

## Usage

```hcl
module "cicd" {
		source = "../iac/cicd"

	# GitHub Configuration (use your own GitHub account)
	github_owner    = "your-github-username"  # Your GitHub username (not the original repo owner)
	github_repo     = "ECSProject"            # Repository name (can be your fork)
	github_branch   = "main"                  # Branch to build from
	github_token    = var.github_token        # Your GitHub personal access token

	# Terraform backend configuration
	terraform_state_bucket = "your-terraform-state-bucket"
	terraform_state_key    = "state/terraform.tfstate"

	# Application configuration
	ecr_repository_url         = module.ecr.repository_url
	ecs_cluster_name          = module.ecs.cluster_name
	ecs_service_name          = module.ecs.service_name
	frontend_bucket_name      = module.s3.frontend_bucket_name
	cloudfront_distribution_id = module.cloudfront.distribution_id
	alb_name                  = module.alb.name
	app_health_url            = "https://your-app-domain.com"
	# Optional
	sns_topic_arn = module.sns.topic_arn
	tags = {
		Environment = "dev"
		Project     = "ecommerce"
	}
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| github_owner | GitHub repository owner | `string` | n/a | yes |
| github_repo | GitHub repository name | `string` | n/a | yes |
| github_branch | GitHub branch to build from | `string` | `"main"` | no |
| github_token | GitHub OAuth token | `string` | n/a | yes |
| sns_topic_arn | SNS topic ARN for notifications | `string` | `""` | no |
| terraform_state_bucket | S3 bucket for Terraform state | `string` | n/a | yes |
| terraform_state_key | S3 key for Terraform state file | `string` | `"state/terraform.tfstate"` | no |
| terraform_dynamodb_table | DynamoDB table for Terraform state locking | `string` | n/a | yes |
| ecr_repository_url | ECR repository URL for Docker images | `string` | n/a | yes |
| ecs_cluster_name | ECS cluster name | `string` | n/a | yes |
| ecs_service_name | ECS service name | `string` | n/a | yes |
| frontend_bucket_name | S3 bucket name for frontend assets | `string` | n/a | yes |
| cloudfront_distribution_id | CloudFront distribution ID | `string` | `""` | no |
| alb_name | Application Load Balancer name | `string` | n/a | yes |
| app_health_url | Application health check URL | `string` | n/a | yes |
| tags | A map of tags to assign to the resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| pipeline_name | Name of the CodePipeline |
| pipeline_arn | ARN of the CodePipeline |
| artifacts_bucket_name | Name of the S3 bucket used for pipeline artifacts |
| artifacts_bucket_arn | ARN of the S3 bucket used for pipeline artifacts |
| terraform_build_project_name | Name of the Terraform CodeBuild project |
| frontend_build_project_name | Name of the Frontend CodeBuild project |
| backend_build_project_name | Name of the Backend CodeBuild project |
| codepipeline_role_arn | ARN of the CodePipeline service role |
| codebuild_role_arn | ARN of the CodeBuild service role |

## Buildspec Files

The module expects the following buildspec files in your repository:

- `ops/iac/buildspec-terraform.yml` - For Terraform operations
- `ops/packages/buildspec-frontend.yml` - For frontend web application build and deployment
- `ops/packages/buildspec-backend.yml` - For backend API build and deployment

## IAM Permissions

The module creates comprehensive IAM roles with permissions for:

- **CodePipeline**: S3 access for artifacts, CodeBuild project execution, SNS publishing
- **CodeBuild**: 
	- AWS service access (EC2, ECS, ECR, ELB, Route53, CloudFront, S3, IAM, etc.)
	- Terraform state management (S3, DynamoDB)
	- Docker operations and ECR push/pull
	- Application deployment and health checks

## Security Features

- S3 bucket encryption enabled
- Public access blocked on artifact bucket
- Least privilege IAM policies
- Secure handling of GitHub tokens

## GitHub Token Setup

For contributors using their own GitHub account:

1. Go to GitHub Settings > Developer settings > Personal access tokens
2. Generate a new token with these permissions:
	 - `repo` (Full control of private repositories)
	 - `admin:repo_hook` (Read and write repository hooks)
3. Set the token as an environment variable:
	 ```bash
	 export TF_VAR_github_token="your_github_token_here"
	 ```
4. Or store it in AWS Secrets Manager and reference it in your configuration