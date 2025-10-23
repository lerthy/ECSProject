#!/bin/bash
set -e

echo "=== Handling Existing Resources ==="

cd "/Users/lerdisalihi/Downloads/ECSProject-main 2/ops/iac"

# Import existing resources that are causing conflicts
echo "Importing existing resources..."

# Import existing IAM roles
terraform import aws_iam_role.config config-recorder-role || true
terraform import module.cicd.aws_iam_role.codepipeline ecommerce-codepipeline-role || true
terraform import module.cicd.aws_iam_role.codebuild ecommerce-codebuild-role || true

# Import existing secrets
terraform import aws_secretsmanager_secret.app app/secret || true

# Import existing WAF resources (these might need to be handled differently)
# WAF resources can't be easily imported, so we'll need to handle them separately

# Import existing S3 buckets
terraform import module.s3.aws_s3_bucket.frontend ecommerce-frontend-dev || true
terraform import module.s3.aws_s3_bucket.alb_logs ecommerce-alb-logs-dev || true
terraform import module.s3.aws_s3_bucket.cloudfront_logs ecommerce-cloudfront-logs-dev || true

# Import existing ECR repositories
terraform import module.ecr.aws_ecr_repository.backend ecommerce-backend-dev || true

# Import existing CloudWatch log groups
terraform import module.cloudwatch.aws_cloudwatch_log_group.ecs /ecs/ecommerce-ecs-dev || true

# Import existing Athena workgroups
terraform import module.athena.aws_athena_workgroup.logs ecommerce_workgroup || true

# Import existing X-Ray groups
terraform import module.xray.aws_xray_group.default ecommerce-ecs-dev || true

# Import existing RDS resources
terraform import module.rds.aws_db_subnet_group.this ecommerce-ecs-dev-db-db-subnet-group || true
terraform import module.rds.aws_db_parameter_group.this ecommerce-ecs-dev-db-db-parameter-group || true
terraform import module.rds.aws_iam_role.rds_enhanced_monitoring ecommerce-ecs-dev-db-rds-enhanced-monitoring || true
terraform import module.rds.aws_secretsmanager_secret.rds_credentials ecommerce-ecs-dev-db-rds-credentials || true

# Import existing ECS IAM roles
terraform import module.ecs.aws_iam_role.ecs_task_execution ecommerce-ecs-dev-ecs-task-execution || true

# Import existing SNS Lambda roles
terraform import module.sns.aws_iam_role.lambda_slack_notifier[0] lambda-sns-slack-notifier-alerts || true

# Import existing X-Ray IAM roles
terraform import module.xray.aws_iam_role.xray ecommerce-ecs-dev-xray-role || true

# Import existing ALB target groups
ALB_TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --names ecommerce-alb-dev-api --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null || true)
if [ -n "$ALB_TARGET_GROUP_ARN" ]; then
  terraform import module.alb.aws_lb_target_group.api "$ALB_TARGET_GROUP_ARN" || true
fi

# Import existing DMS endpoints
terraform import module.dms.aws_dms_endpoint.source source-db-endpoint || true
terraform import module.dms.aws_dms_endpoint.target target-db-endpoint || true

echo "=== Import Complete ==="
echo "Running terraform plan to see remaining resources..."
terraform plan -out=tfplan_after_import

echo "=== Applying remaining resources ==="
terraform apply tfplan_after_import -auto-approve

echo "=== Deployment Complete ==="
