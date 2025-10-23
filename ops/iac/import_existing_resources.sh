#!/bin/bash

# Import Existing Resources Script
# This script imports all existing AWS resources into Terraform state

set -e

echo "🚀 Starting import of existing AWS resources..."

# Get AWS Account ID and Region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)
DR_REGION="eu-north-1"

echo "📋 Account ID: $ACCOUNT_ID"
echo "📋 Primary Region: $REGION"
echo "📋 DR Region: $DR_REGION"

# Function to import resource with error handling
import_resource() {
    local resource_type="$1"
    local resource_name="$2"
    local resource_id="$3"
    
    echo "📥 Importing $resource_type: $resource_name"
    if terraform import "$resource_type" "$resource_name" "$resource_id" 2>/dev/null; then
        echo "✅ Successfully imported $resource_name"
    else
        echo "⚠️  Failed to import $resource_name (may already be imported or not exist)"
    fi
}

# IAM Roles
echo "🔐 Importing IAM Roles..."
import_resource "aws_iam_role.config" "config-recorder-role"
import_resource "aws_iam_role.dms_vpc_role" "dms-vpc-role"
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

# Secrets Manager
echo "🔑 Importing Secrets Manager Secrets..."
import_resource "aws_secretsmanager_secret.app" "app/secret"
import_resource "aws_secretsmanager_secret.rds_credentials" "ecommerce-ecs-dev-db-rds-credentials"
import_resource "aws_secretsmanager_secret.rds_credentials" "ecommerce-ecs-dev-db-dr-rds-credentials"
import_resource "aws_secretsmanager_secret.rds_credentials" "ecommerce-ecs-dev-db-standby-rds-credentials"

# WAFv2 WebACLs
echo "🛡️ Importing WAFv2 WebACLs..."
# Get WAF WebACL IDs
CLOUDFRONT_WAF_ID=$(aws wafv2 list-web-acls --scope CLOUDFRONT --query 'WebACLs[?Name==`cloudfront-waf`].Id' --output text)
ALB_WAF_ID=$(aws wafv2 list-web-acls --scope REGIONAL --query 'WebACLs[?Name==`alb-waf`].Id' --output text)

if [ "$CLOUDFRONT_WAF_ID" != "None" ] && [ "$CLOUDFRONT_WAF_ID" != "" ]; then
    import_resource "aws_wafv2_web_acl.cloudfront" "arn:aws:wafv2:global:$ACCOUNT_ID:webacl/cloudfront-waf/$CLOUDFRONT_WAF_ID"
fi

if [ "$ALB_WAF_ID" != "None" ] && [ "$ALB_WAF_ID" != "" ]; then
    import_resource "aws_wafv2_web_acl.alb" "arn:aws:wafv2:$REGION:$ACCOUNT_ID:webacl/alb-waf/$ALB_WAF_ID"
fi

# Athena WorkGroups
echo "📊 Importing Athena WorkGroups..."
import_resource "aws_athena_workgroup.logs" "ecommerce_workgroup"

# CloudWatch Log Groups
echo "📝 Importing CloudWatch Log Groups..."
import_resource "aws_cloudwatch_log_group.ecs" "/ecs/ecommerce-ecs-dev"

# DMS Resources
echo "🔄 Importing DMS Resources..."
import_resource "aws_dms_replication_instance.this" "cross-region-dms-instance"
import_resource "aws_dms_endpoint.source" "source-db-endpoint"
import_resource "aws_dms_endpoint.target" "target-db-endpoint"

# ECR Repositories
echo "🐳 Importing ECR Repositories..."
import_resource "aws_ecr_repository.backend" "ecommerce-backend-dev"

# RDS Parameter Groups
echo "🗄️ Importing RDS Parameter Groups..."
import_resource "aws_db_parameter_group.this" "ecommerce-ecs-dev-db-db-parameter-group"
import_resource "aws_db_parameter_group.this" "ecommerce-ecs-dev-db-dr-db-parameter-group"
import_resource "aws_db_parameter_group.this" "ecommerce-ecs-dev-db-standby-db-parameter-group"

# S3 Buckets
echo "🪣 Importing S3 Buckets..."
import_resource "aws_s3_bucket.frontend" "ecommerce-frontend-dev"
import_resource "aws_s3_bucket.frontend" "ecommerce-frontend-dr"
import_resource "aws_s3_bucket.alb_logs" "ecommerce-alb-logs-dev"
import_resource "aws_s3_bucket.alb_logs" "ecommerce-alb-logs-dr"
import_resource "aws_s3_bucket.cloudfront_logs" "ecommerce-cloudfront-logs-dev"
import_resource "aws_s3_bucket.cloudfront_logs" "ecommerce-cloudfront-logs-dr"

# X-Ray Groups
echo "🔍 Importing X-Ray Groups..."
import_resource "aws_xray_group.default" "ecommerce-ecs-dev"

echo "✅ Import script completed!"
echo "📋 Next steps:"
echo "1. Run 'terraform plan' to verify imports"
echo "2. Run 'terraform apply' to complete deployment"
echo "3. Check for any remaining issues"
