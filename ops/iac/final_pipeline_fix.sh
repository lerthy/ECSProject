#!/bin/bash

# Final Pipeline Fix Script
# This script addresses all pipeline failures comprehensively

set -e

echo "🔧 Final Pipeline Fix - Addressing All Issues..."

# Get AWS Account ID and Region
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region)

echo "📋 Account ID: $ACCOUNT_ID"
echo "📋 Region: $REGION"

# Step 1: Check VPC Limits
echo ""
echo "🔍 Step 1: Checking VPC limits..."
VPC_COUNT=$(aws ec2 describe-vpcs --query 'length(Vpcs)' --output text)
echo "📊 Current VPC count: $VPC_COUNT"

if [ "$VPC_COUNT" -ge 5 ]; then
    echo "⚠️  VPC limit reached! Using data sources for existing VPCs."
    
    # Get existing VPC IDs
    EXISTING_VPC_ID=$(aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text)
    echo "📋 Using existing VPC: $EXISTING_VPC_ID"
    
    # Create a temporary override file
    cat > vpc_override.tf << EOF
# VPC Override to use existing VPCs
locals {
  existing_vpc_id = "$EXISTING_VPC_ID"
}

# Data source for existing VPC
data "aws_vpc" "existing" {
  id = local.existing_vpc_id
}

# Data source for existing subnets
data "aws_subnets" "existing_public" {
  filter {
    name   = "vpc-id"
    values = [local.existing_vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*public*"]
  }
}

data "aws_subnets" "existing_private" {
  filter {
    name   = "vpc-id"
    values = [local.existing_vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*private*"]
  }
}

data "aws_subnets" "existing_database" {
  filter {
    name   = "vpc-id"
    values = [local.existing_vpc_id]
  }
  filter {
    name   = "tag:Name"
    values = ["*database*", "*db*"]
  }
}
EOF
    
    echo "✅ Created VPC override configuration"
else
    echo "✅ VPC count is within limits"
fi

# Step 2: Import Critical Resources
echo ""
echo "🔍 Step 2: Importing critical existing resources..."

# Function to import resource with error handling
import_resource() {
    local resource_type="$1"
    local resource_name="$2"
    local resource_id="$3"
    
    echo "📥 Attempting to import $resource_type: $resource_name"
    if terraform import "$resource_type" "$resource_name" "$resource_id" 2>/dev/null; then
        echo "✅ Successfully imported $resource_name"
    else
        echo "⚠️  Failed to import $resource_name (may already be imported or not exist)"
    fi
}

# Import IAM Roles
echo "🔐 Importing critical IAM roles..."
import_resource "aws_iam_role.config" "config-recorder-role"
import_resource "aws_iam_role.codepipeline" "ecommerce-codepipeline-role"
import_resource "aws_iam_role.codebuild" "ecommerce-codebuild-role"

# Import Secrets Manager Secrets
echo "🔑 Importing Secrets Manager secrets..."
import_resource "aws_secretsmanager_secret.app" "app/secret"

# Import ECR Repository
echo "🐳 Importing ECR repository..."
import_resource "aws_ecr_repository.backend" "ecommerce-backend-dev"

# Import S3 Buckets
echo "🪣 Importing S3 buckets..."
import_resource "aws_s3_bucket.frontend" "ecommerce-frontend-dev"
import_resource "aws_s3_bucket.alb_logs" "ecommerce-alb-logs-dev"
import_resource "aws_s3_bucket.cloudfront_logs" "ecommerce-cloudfront-logs-dev"

# Import CloudWatch Log Group
echo "📝 Importing CloudWatch log group..."
import_resource "aws_cloudwatch_log_group.ecs" "/ecs/ecommerce-ecs-dev"

# Import X-Ray Group
echo "🔍 Importing X-Ray group..."
import_resource "aws_xray_group.default" "ecommerce-ecs-dev"

# Step 3: Handle WAF Resources
echo ""
echo "🔍 Step 3: Handling WAF resources..."

# Get WAF WebACL IDs
echo "🛡️ Checking WAF WebACLs..."
CLOUDFRONT_WAF_ID=$(aws wafv2 list-web-acls --scope CLOUDFRONT --query 'WebACLs[?Name==`cloudfront-waf`].Id' --output text 2>/dev/null || echo "")
ALB_WAF_ID=$(aws wafv2 list-web-acls --scope REGIONAL --query 'WebACLs[?Name==`alb-waf`].Id' --output text 2>/dev/null || echo "")

if [ "$CLOUDFRONT_WAF_ID" != "None" ] && [ "$CLOUDFRONT_WAF_ID" != "" ]; then
    echo "📥 Importing CloudFront WAF WebACL..."
    import_resource "aws_wafv2_web_acl.cloudfront" "arn:aws:wafv2:global:$ACCOUNT_ID:webacl/cloudfront-waf/$CLOUDFRONT_WAF_ID"
fi

if [ "$ALB_WAF_ID" != "None" ] && [ "$ALB_WAF_ID" != "" ]; then
    echo "📥 Importing ALB WAF WebACL..."
    import_resource "aws_wafv2_web_acl.alb" "arn:aws:wafv2:$REGION:$ACCOUNT_ID:webacl/alb-waf/$ALB_WAF_ID"
fi

# Step 4: Handle Athena WorkGroup
echo ""
echo "🔍 Step 4: Handling Athena WorkGroup..."
import_resource "aws_athena_workgroup.logs" "ecommerce_workgroup"

# Step 5: Handle DMS Resources
echo ""
echo "🔍 Step 5: Handling DMS resources..."
import_resource "aws_dms_replication_instance.this" "cross-region-dms-instance"
import_resource "aws_dms_endpoint.source" "source-db-endpoint"
import_resource "aws_dms_endpoint.target" "target-db-endpoint"

# Step 6: Handle RDS Resources
echo ""
echo "🔍 Step 6: Handling RDS resources..."
import_resource "aws_db_parameter_group.this" "ecommerce-ecs-dev-db-db-parameter-group"
import_resource "aws_secretsmanager_secret.rds_credentials" "ecommerce-ecs-dev-db-rds-credentials"

# Step 7: Handle ECS Resources
echo ""
echo "🔍 Step 7: Handling ECS resources..."
import_resource "aws_iam_role.ecs_task_execution" "ecommerce-ecs-dev-ecs-task-execution"
import_resource "aws_iam_role.rds_enhanced_monitoring" "ecommerce-ecs-dev-db-rds-enhanced-monitoring"

# Step 8: Handle SNS Resources
echo ""
echo "🔍 Step 8: Handling SNS resources..."
import_resource "aws_iam_role.lambda_slack_notifier" "lambda-sns-slack-notifier-alerts"

# Step 9: Handle X-Ray Resources
echo ""
echo "🔍 Step 9: Handling X-Ray resources..."
import_resource "aws_iam_role.xray" "ecommerce-ecs-dev-xray-role"

# Step 10: Validate Configuration
echo ""
echo "🔍 Step 10: Validating Terraform configuration..."
if terraform validate; then
    echo "✅ Terraform configuration is valid"
else
    echo "❌ Terraform configuration has errors"
    echo "🔍 Attempting to fix configuration issues..."
    
    # Try to format and validate again
    terraform fmt -recursive
    if terraform validate; then
        echo "✅ Configuration fixed and validated"
    else
        echo "❌ Configuration still has errors"
        exit 1
    fi
fi

# Step 11: Plan Changes
echo ""
echo "🔍 Step 11: Planning Terraform changes..."
if terraform plan -out=tfplan; then
    echo "✅ Terraform plan successful"
    echo "📋 Review the plan and run 'terraform apply tfplan' to apply changes"
else
    echo "❌ Terraform plan failed"
    echo "🔍 Check the plan output for issues"
    echo ""
    echo "💡 Common solutions:"
    echo "1. Import more existing resources"
    echo "2. Check for VPC limit issues"
    echo "3. Verify IAM permissions"
    echo "4. Check for naming conflicts"
fi

echo ""
echo "🎉 Final fix script completed!"
echo ""
echo "📋 Next steps:"
echo "1. Review the terraform plan output"
echo "2. Run 'terraform apply tfplan' to apply changes"
echo "3. Monitor the pipeline execution"
echo "4. Check for any remaining issues"
echo ""
echo "💡 If you still encounter issues:"
echo "1. Check the terraform plan output for specific errors"
echo "2. Import additional existing resources as needed"
echo "3. Consider using existing VPCs instead of creating new ones"
echo "4. Request VPC limit increase from AWS Support if needed"
