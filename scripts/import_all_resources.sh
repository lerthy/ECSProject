#!/bin/bash
set -e

cd "/Users/lerdisalihi/Downloads/ECSProject-main 2/ops/iac"

echo "=== Importing All Existing Resources ==="

# Import monitoring and observability resources
echo "Importing Athena resources..."
terraform import 'module.athena.aws_athena_workgroup.logs' 'ecommerce_workgroup' 2>/dev/null || true
terraform import 'module.athena.aws_athena_database.logs' 'ecommerce_logs' 2>/dev/null || true

echo "Importing CloudWatch resources..."
terraform import 'module.cloudwatch.aws_cloudwatch_log_group.ecs' '/ecs/ecommerce-ecs-dev' 2>/dev/null || true

echo "Importing S3 buckets..."
terraform import 'module.s3.aws_s3_bucket.alb_logs' 'ecommerce-alb-logs-dev' 2>/dev/null || true
terraform import 'module.s3.aws_s3_bucket.cloudfront_logs' 'ecommerce-cloudfront-logs-dev' 2>/dev/null || true
terraform import 'module.s3.aws_s3_bucket.frontend' 'ecommerce-frontend-dev' 2>/dev/null || true
terraform import 'module.s3.aws_s3_bucket.athena_results' 'ecommerce-athena-results' 2>/dev/null || true

echo "Importing SNS Lambda resources..."
terraform import 'module.sns.aws_iam_role.lambda_slack_notifier[0]' 'lambda-sns-slack-notifier-alerts' 2>/dev/null || true
terraform import 'module.sns.aws_lambda_function.slack_notifier[0]' 'sns-slack-notifier-alerts' 2>/dev/null || true

echo "Importing X-Ray resources..."
terraform import 'module.xray.aws_iam_role.xray' 'ecommerce-ecs-dev-xray-role' 2>/dev/null || true
terraform import 'module.xray.aws_xray_group.default' 'ecommerce-ecs-dev' 2>/dev/null || true

echo "Importing RDS resources..."
terraform import 'module.rds.aws_db_subnet_group.this' 'ecommerce-ecs-dev-db-db-subnet-group' 2>/dev/null || true
terraform import 'module.rds.aws_db_parameter_group.this' 'ecommerce-ecs-dev-db-db-parameter-group' 2>/dev/null || true
terraform import 'module.rds.aws_iam_role.rds_enhanced_monitoring' 'ecommerce-ecs-dev-db-rds-enhanced-monitoring' 2>/dev/null || true

# Get Secrets Manager ARN and import
SECRET_ARN=$(aws secretsmanager describe-secret --secret-id ecommerce-ecs-dev-db-rds-credentials --query 'ARN' --output text 2>/dev/null || echo "")
if [ ! -z "$SECRET_ARN" ]; then
    echo "Importing Secrets Manager secret..."
    terraform import 'module.rds.aws_secretsmanager_secret.rds_credentials' "$SECRET_ARN" 2>/dev/null || true
fi

echo "Importing ECS resources..."
terraform import 'module.ecs.aws_iam_role.ecs_task_execution' 'ecommerce-ecs-dev-ecs-task-execution' 2>/dev/null || true

echo "Importing ECR repository..."
terraform import 'module.ecr.aws_ecr_repository.backend' 'ecommerce-backend-dev' 2>/dev/null || true

echo "Importing ALB Target Group..."
TG_ARN=$(aws elbv2 describe-target-groups --names ecommerce-alb-dev-api --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || echo "")
if [ ! -z "$TG_ARN" ]; then
    echo "Importing ALB target group..."
    terraform import 'module.alb.aws_lb_target_group.api' "$TG_ARN" 2>/dev/null || true
fi

echo ""
echo "=== Import Complete ==="
echo "Resources in state:"
terraform state list | wc -l

echo ""
echo "=== Running terraform plan to see remaining resources ==="
terraform plan -out=tfplan_after_import

