#!/bin/bash

# Final Comprehensive Import Script for ALL Existing Resources
# This script imports all the resources that are causing conflicts

set -e

echo "=== Importing ALL Existing Resources ==="

cd ops/iac

# Function to safely import resources
safe_import() {
    local resource="$1"
    local id="$2"
    local description="$3"
    
    echo "Importing $description..."
    if terraform import "$resource" "$id" 2>/dev/null; then
        echo "✓ Successfully imported $description"
        return 0
    else
        echo "⚠ $description already imported or doesn't exist"
        return 1
    fi
}

echo "=== Importing IAM Roles ==="
safe_import "aws_iam_role.config" "config-recorder-role" "Config Role"
safe_import "module.cicd.aws_iam_role.codepipeline" "ecommerce-codepipeline-role" "CodePipeline Role"
safe_import "module.cicd.aws_iam_role.codebuild" "ecommerce-codebuild-role" "CodeBuild Role"
safe_import "module.ecs.aws_iam_role.ecs_task_execution" "ecommerce-ecs-dev-ecs-task-execution" "ECS Task Execution Role"
safe_import "module.ecs_dr.aws_iam_role.ecs_task_execution" "ecommerce-ecs-dev-dr-ecs-task-execution" "ECS DR Task Execution Role"
safe_import "module.ecs_standby.aws_iam_role.ecs_task_execution" "ecommerce-ecs-dev-standby-ecs-task-execution" "ECS Standby Task Execution Role"
safe_import "module.rds.aws_iam_role.rds_enhanced_monitoring" "ecommerce-ecs-dev-db-rds-enhanced-monitoring" "RDS Enhanced Monitoring Role"
safe_import "module.rds_dr.aws_iam_role.rds_enhanced_monitoring" "ecommerce-ecs-dev-db-dr-rds-enhanced-monitoring" "RDS DR Enhanced Monitoring Role"
safe_import "module.rds_standby.aws_iam_role.rds_enhanced_monitoring" "ecommerce-ecs-dev-db-standby-rds-enhanced-monitoring" "RDS Standby Enhanced Monitoring Role"
safe_import "module.sns.aws_iam_role.lambda_slack_notifier[0]" "lambda-sns-slack-notifier-alerts" "SNS Lambda Role"
safe_import "module.sns_dr.aws_iam_role.lambda_slack_notifier[0]" "lambda-sns-slack-notifier-alerts-dr" "SNS DR Lambda Role"
safe_import "module.xray.aws_iam_role.xray" "ecommerce-ecs-dev-xray-role" "X-Ray Role"
safe_import "module.xray_dr.aws_iam_role.xray" "ecommerce-ecs-dev-xray-role" "X-Ray DR Role"

echo "=== Importing Secrets Manager Secrets ==="
safe_import "aws_secretsmanager_secret.app" "app/secret" "App Secret"
safe_import "module.rds.aws_secretsmanager_secret.rds_credentials" "ecommerce-ecs-dev-db-rds-credentials" "RDS Credentials Secret"
safe_import "module.rds_dr.aws_secretsmanager_secret.rds_credentials" "ecommerce-ecs-dev-db-dr-rds-credentials" "RDS DR Credentials Secret"
safe_import "module.rds_standby.aws_secretsmanager_secret.rds_credentials" "ecommerce-ecs-dev-db-standby-rds-credentials" "RDS Standby Credentials Secret"

echo "=== Importing WAF Web ACLs ==="
safe_import "aws_wafv2_web_acl.cloudfront" "cloudfront-waf" "CloudFront WAF"
safe_import "aws_wafv2_web_acl.alb" "alb-waf" "ALB WAF"

echo "=== Importing Athena WorkGroups ==="
safe_import "module.athena.aws_athena_workgroup.logs" "ecommerce_workgroup" "Athena WorkGroup"
safe_import "module.athena_dr.aws_athena_workgroup.logs" "ecommerce_workgroup" "Athena DR WorkGroup"

echo "=== Importing CloudWatch Log Groups ==="
safe_import "module.cloudwatch.aws_cloudwatch_log_group.ecs" "/ecs/ecommerce-ecs-dev" "ECS Log Group"
safe_import "module.cloudwatch_dr.aws_cloudwatch_log_group.ecs" "/ecs/ecommerce-ecs-dev" "ECS DR Log Group"

echo "=== Importing DMS Resources ==="
safe_import "module.dms.aws_dms_replication_instance.this" "cross-region-dms-instance" "DMS Replication Instance"
safe_import "module.dms.aws_dms_endpoint.source" "source-db-endpoint" "DMS Source Endpoint"
safe_import "module.dms.aws_dms_endpoint.target" "target-db-endpoint" "DMS Target Endpoint"

echo "=== Importing ECR Repositories ==="
safe_import "module.ecr.aws_ecr_repository.backend" "ecommerce-backend-dev" "ECR Repository"
safe_import "module.ecr_dr.aws_ecr_repository.backend" "ecommerce-backend-dev" "ECR DR Repository"

echo "=== Importing RDS Resources ==="
safe_import "module.rds.aws_db_subnet_group.this" "ecommerce-ecs-dev-db-db-subnet-group" "RDS Subnet Group"
safe_import "module.rds_standby.aws_db_subnet_group.this" "ecommerce-ecs-dev-db-standby-db-subnet-group" "RDS Standby Subnet Group"
safe_import "module.rds.aws_db_parameter_group.this" "ecommerce-ecs-dev-db-db-parameter-group" "RDS Parameter Group"
safe_import "module.rds_dr.aws_db_parameter_group.this" "ecommerce-ecs-dev-db-dr-db-parameter-group" "RDS DR Parameter Group"
safe_import "module.rds_standby.aws_db_parameter_group.this" "ecommerce-ecs-dev-db-standby-db-parameter-group" "RDS Standby Parameter Group"

echo "=== Importing S3 Buckets ==="
safe_import "module.s3.aws_s3_bucket.frontend" "ecommerce-frontend-dev" "Frontend S3 Bucket"
safe_import "module.s3_dr.aws_s3_bucket.frontend" "ecommerce-frontend-dr" "Frontend DR S3 Bucket"
safe_import "module.s3.aws_s3_bucket.alb_logs" "ecommerce-alb-logs-dev" "ALB Logs S3 Bucket"
safe_import "module.s3_dr.aws_s3_bucket.alb_logs" "ecommerce-alb-logs-dr" "ALB Logs DR S3 Bucket"
safe_import "module.s3.aws_s3_bucket.cloudfront_logs" "ecommerce-cloudfront-logs-dev" "CloudFront Logs S3 Bucket"
safe_import "module.s3_dr.aws_s3_bucket.cloudfront_logs" "ecommerce-cloudfront-logs-dr" "CloudFront Logs DR S3 Bucket"

echo "=== Importing X-Ray Groups ==="
safe_import "module.xray.aws_xray_group.default" "ecommerce-ecs-dev" "X-Ray Group"
safe_import "module.xray_dr.aws_xray_group.default" "ecommerce-ecs-dev" "X-Ray DR Group"

echo "=== Importing ALB Target Groups ==="
safe_import "module.alb.aws_lb_target_group.api" "ecommerce-alb-dev-api" "ALB Target Group"
safe_import "module.alb_standby.aws_lb_target_group.api" "ecommerce-alb-dev-standby-api" "ALB Standby Target Group"

echo "=== Import Complete ==="
echo "All existing resources have been imported!"
echo "You can now run 'terraform plan' to see what changes are needed."
