#!/bin/bash

# Comprehensive Import Script for Existing AWS Resources
# This script imports all existing resources that are causing conflicts

set -e

echo "Starting comprehensive import of existing AWS resources..."

# Function to import resource with error handling
import_resource() {
    local resource_type="$1"
    local resource_name="$2"
    local resource_id="$3"
    
    echo "Importing $resource_type: $resource_name"
    
    if terraform import "$resource_type" "$resource_id" 2>/dev/null; then
        echo "✓ Successfully imported $resource_name"
    else
        echo "⚠ Failed to import $resource_name (may already be imported or not exist)"
    fi
}

# Function to import resource with different ID format
import_resource_with_id() {
    local resource_type="$1"
    local resource_name="$2"
    local resource_id="$3"
    local terraform_id="$4"
    
    echo "Importing $resource_type: $resource_name"
    
    if terraform import "$resource_type" "$terraform_id" "$resource_id" 2>/dev/null; then
        echo "✓ Successfully imported $resource_name"
    else
        echo "⚠ Failed to import $resource_name (may already be imported or not exist)"
    fi
}

# Change to the terraform directory
cd /Users/lerdisalihi/Downloads/ECSProject-main\ 2/ops/iac

echo "Current directory: $(pwd)"

# 1. Import IAM Roles
echo "=== Importing IAM Roles ==="
import_resource "aws_iam_role.config" "config-recorder-role"
import_resource "aws_iam_role.ecs_task_execution" "ecommerce-ecs-dev-ecs-task-execution"
import_resource "aws_iam_role.ecs_task_execution" "ecommerce-ecs-dev-dr-ecs-task-execution" 
import_resource "aws_iam_role.ecs_task_execution" "ecommerce-ecs-dev-standby-ecs-task-execution"
import_resource "aws_iam_role.rds_enhanced_monitoring" "ecommerce-ecs-dev-db-rds-enhanced-monitoring"
import_resource "aws_iam_role.rds_enhanced_monitoring" "ecommerce-ecs-dev-db-dr-rds-enhanced-monitoring"
import_resource "aws_iam_role.rds_enhanced_monitoring" "ecommerce-ecs-dev-db-standby-rds-enhanced-monitoring"
import_resource "aws_iam_role.lambda_slack_notifier" "lambda-sns-slack-notifier-alerts"
import_resource "aws_iam_role.lambda_slack_notifier" "lambda-sns-slack-notifier-alerts-dr"
import_resource "aws_iam_role.xray" "ecommerce-ecs-dev-xray-role"
import_resource "aws_iam_role.codepipeline" "ecommerce-codepipeline-role"
import_resource "aws_iam_role.codebuild" "ecommerce-codebuild-role"

# 2. Import Secrets Manager Secrets
echo "=== Importing Secrets Manager Secrets ==="
import_resource "aws_secretsmanager_secret.app" "app/secret"
import_resource "aws_secretsmanager_secret.rds_credentials" "ecommerce-ecs-dev-db-rds-credentials"
import_resource "aws_secretsmanager_secret.rds_credentials" "ecommerce-ecs-dev-db-dr-rds-credentials"
import_resource "aws_secretsmanager_secret.rds_credentials" "ecommerce-ecs-dev-db-standby-rds-credentials"

# 3. Import WAF Web ACLs
echo "=== Importing WAF Web ACLs ==="
import_resource "aws_wafv2_web_acl.cloudfront" "cloudfront-waf"
import_resource "aws_wafv2_web_acl.alb" "alb-waf"

# 4. Import Athena WorkGroups
echo "=== Importing Athena WorkGroups ==="
import_resource "aws_athena_workgroup.logs" "ecommerce_workgroup"

# 5. Import CloudWatch Log Groups
echo "=== Importing CloudWatch Log Groups ==="
import_resource "aws_cloudwatch_log_group.ecs" "/ecs/ecommerce-ecs-dev"

# 6. Import DMS Resources
echo "=== Importing DMS Resources ==="
import_resource "aws_dms_replication_instance.this" "cross-region-dms-instance"
import_resource "aws_dms_endpoint.source" "source-db-endpoint"
import_resource "aws_dms_endpoint.target" "target-db-endpoint"

# 7. Import ECR Repositories
echo "=== Importing ECR Repositories ==="
import_resource "aws_ecr_repository.backend" "ecommerce-backend-dev"

# 8. Import RDS Parameter Groups
echo "=== Importing RDS Parameter Groups ==="
import_resource "aws_db_parameter_group.this" "ecommerce-ecs-dev-db-db-parameter-group"
import_resource "aws_db_parameter_group.this" "ecommerce-ecs-dev-db-dr-db-parameter-group"
import_resource "aws_db_parameter_group.this" "ecommerce-ecs-dev-db-standby-db-parameter-group"

# 9. Import S3 Buckets
echo "=== Importing S3 Buckets ==="
import_resource "aws_s3_bucket.frontend" "ecommerce-frontend-dev"
import_resource "aws_s3_bucket.frontend" "ecommerce-frontend-dr"
import_resource "aws_s3_bucket.alb_logs" "ecommerce-alb-logs-dev"
import_resource "aws_s3_bucket.alb_logs" "ecommerce-alb-logs-dr"
import_resource "aws_s3_bucket.cloudfront_logs" "ecommerce-cloudfront-logs-dev"
import_resource "aws_s3_bucket.cloudfront_logs" "ecommerce-cloudfront-logs-dr"

# 10. Import X-Ray Groups
echo "=== Importing X-Ray Groups ==="
import_resource "aws_xray_group.default" "ecommerce-ecs-dev"

# 11. Import CloudWatch Dashboards (if they exist)
echo "=== Importing CloudWatch Dashboards ==="
import_resource "aws_cloudwatch_dashboard.main" "ecommerce-ecs-dev-dashboard"

# 12. Import CloudWatch Metric Alarms
echo "=== Importing CloudWatch Metric Alarms ==="
import_resource "aws_cloudwatch_metric_alarm.ecs_cpu_high" "ecommerce-ecs-dev-ecs-cpu-high"

# 13. Import CloudTrail
echo "=== Importing CloudTrail ==="
import_resource "aws_cloudtrail.main" "main-trail"

# 14. Import AWS Config Resources
echo "=== Importing AWS Config Resources ==="
import_resource "aws_config_configuration_recorder.main" "main-recorder"
import_resource "aws_config_delivery_channel.main" "main-channel"

# 15. Import Secrets Manager Secret Versions
echo "=== Importing Secrets Manager Secret Versions ==="
import_resource "aws_secretsmanager_secret_version.app" "app/secret"

echo "=== Import Process Complete ==="
echo "Note: Some resources may fail to import if they don't exist or have different names."
echo "This is normal and expected. The script will continue with other resources."

# Show current state
echo "=== Current Terraform State ==="
terraform state list

echo "=== Import script completed ==="
echo "You can now run 'terraform plan' to see what changes are needed."
