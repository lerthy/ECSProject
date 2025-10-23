#!/bin/bash
set -e

echo "=== Complete Terraform Infrastructure Deployment ==="
echo "This script will deploy the remaining infrastructure components"
echo ""

# Change to the Terraform directory
cd "/Users/lerdisalihi/Downloads/ECSProject-main 2/ops/iac"

echo "Step 1: Cleaning up Terraform state..."
rm -rf .terraform .terraform.lock.hcl

echo "Step 2: Initializing Terraform..."
terraform init

echo "Step 3: Importing any remaining existing resources..."
# Import any resources that might have been missed
terraform import 'module.athena.aws_athena_workgroup.logs' 'ecommerce_workgroup' 2>/dev/null || true
terraform import 'module.cloudwatch.aws_cloudwatch_log_group.ecs' '/ecs/ecommerce-ecs-dev' 2>/dev/null || true
terraform import 'module.s3.aws_s3_bucket.alb_logs' 'ecommerce-alb-logs-dev' 2>/dev/null || true
terraform import 'module.s3.aws_s3_bucket.cloudfront_logs' 'ecommerce-cloudfront-logs-dev' 2>/dev/null || true
terraform import 'module.s3.aws_s3_bucket.frontend' 'ecommerce-frontend-dev' 2>/dev/null || true
terraform import 'module.s3.aws_s3_bucket.athena_results' 'ecommerce-athena-results' 2>/dev/null || true

# Import IAM roles
terraform import 'module.sns.aws_iam_role.lambda_slack_notifier[0]' 'lambda-sns-slack-notifier-alerts' 2>/dev/null || true
terraform import 'module.xray.aws_iam_role.xray' 'ecommerce-ecs-dev-xray-role' 2>/dev/null || true
terraform import 'module.ecs.aws_iam_role.ecs_task_execution' 'ecommerce-ecs-dev-ecs-task-execution' 2>/dev/null || true
terraform import 'module.rds.aws_iam_role.rds_enhanced_monitoring' 'ecommerce-ecs-dev-db-rds-enhanced-monitoring' 2>/dev/null || true

# Import other resources
terraform import 'module.ecr.aws_ecr_repository.backend' 'ecommerce-backend-dev' 2>/dev/null || true
terraform import 'module.rds.aws_db_subnet_group.this' 'ecommerce-ecs-dev-db-db-subnet-group' 2>/dev/null || true
terraform import 'module.rds.aws_db_parameter_group.this' 'ecommerce-ecs-dev-db-db-parameter-group' 2>/dev/null || true

# Import secrets manager if it exists
SECRET_ARN=$(aws secretsmanager describe-secret --secret-id ecommerce-ecs-dev-db-rds-credentials --query 'ARN' --output text 2>/dev/null || echo "")
if [ ! -z "$SECRET_ARN" ]; then
    terraform import 'module.rds.aws_secretsmanager_secret.rds_credentials' "$SECRET_ARN" 2>/dev/null || true
fi

# Import ALB target group if it exists
TG_ARN=$(aws elbv2 describe-target-groups --names ecommerce-alb-dev-api --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
if [ ! -z "$TG_ARN" ]; then
    terraform import 'module.alb.aws_lb_target_group.api' "$TG_ARN" 2>/dev/null || true
fi

echo "Step 4: Running Terraform plan to see what needs to be created..."
terraform plan -out=tfplan_final

echo "Step 5: Applying the Terraform configuration..."
echo "This will create the remaining infrastructure components including:"
echo "- DR infrastructure (VPC, ECS, RDS, ALB in eu-north-1)"
echo "- Standby RDS instances"
echo "- Route53 failover routing"
echo "- CloudFront distributions"
echo "- WAF rules"
echo "- DMS replication"
echo "- Complete monitoring stack"
echo ""

read -p "Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Deploying infrastructure..."
    terraform apply tfplan_final
    
    echo ""
    echo "=== Deployment Complete! ==="
    echo "Infrastructure has been successfully deployed."
    echo ""
    echo "Key outputs:"
    terraform output
    
    echo ""
    echo "Resources in state:"
    terraform state list | wc -l
else
    echo "Deployment cancelled."
fi
