#!/bin/bash

# Comprehensive Import Script for All Existing Resources
set -e

echo "=== Importing All Existing Resources ==="

cd ops/iac

# Function to safely import resources
safe_import() {
    local resource="$1"
    local id="$2"
    local description="$3"
    
    echo "Importing $description..."
    if terraform import "$resource" "$id" 2>/dev/null; then
        echo "✓ Successfully imported $description"
    else
        echo "⚠ $description already imported or doesn't exist"
    fi
}

# Import IAM Roles
safe_import "aws_iam_role.config" "config-recorder-role" "Config Role"
safe_import "module.cicd.aws_iam_role.codepipeline" "ecommerce-codepipeline-role" "CodePipeline Role"
safe_import "module.cicd.aws_iam_role.codebuild" "ecommerce-codebuild-role" "CodeBuild Role"

# Import Secrets
safe_import "aws_secretsmanager_secret.app" "app/secret" "App Secret"

# Import S3 Buckets
safe_import "module.s3.aws_s3_bucket.frontend" "ecommerce-frontend-dev" "Frontend S3 Bucket"
safe_import "module.s3.aws_s3_bucket.alb_logs" "ecommerce-alb-logs-dev" "ALB Logs S3 Bucket"
safe_import "module.s3.aws_s3_bucket.cloudfront_logs" "ecommerce-cloudfront-logs-dev" "CloudFront Logs S3 Bucket"

# Import ECR
safe_import "module.ecr.aws_ecr_repository.backend" "ecommerce-backend-dev" "ECR Repository"

# Import CloudWatch
safe_import "module.cloudwatch.aws_cloudwatch_log_group.ecs" "/ecs/ecommerce-ecs-dev" "ECS Log Group"

# Import Athena
safe_import "module.athena.aws_athena_workgroup.logs" "ecommerce_workgroup" "Athena WorkGroup"

# Import X-Ray
safe_import "module.xray.aws_xray_group.default" "ecommerce-ecs-dev" "X-Ray Group"

# Import RDS Resources
safe_import "module.rds.aws_db_parameter_group.this" "ecommerce-ecs-dev-db-db-parameter-group" "RDS Parameter Group"
safe_import "module.rds.aws_iam_role.rds_enhanced_monitoring" "ecommerce-ecs-dev-db-rds-enhanced-monitoring" "RDS Monitoring Role"
safe_import "module.rds.aws_secretsmanager_secret.rds_credentials" "ecommerce-ecs-dev-db-rds-credentials" "RDS Credentials Secret"

# Import ECS Resources
safe_import "module.ecs.aws_iam_role.ecs_task_execution" "ecommerce-ecs-dev-ecs-task-execution" "ECS Task Execution Role"

# Import SNS Resources
safe_import "module.sns.aws_iam_role.lambda_slack_notifier[0]" "lambda-sns-slack-notifier-alerts" "SNS Lambda Role"

# Import X-Ray Role
safe_import "module.xray.aws_iam_role.xray" "ecommerce-ecs-dev-xray-role" "X-Ray Role"

echo "=== Import Process Complete ==="
