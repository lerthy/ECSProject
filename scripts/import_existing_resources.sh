#!/bin/bash

# Script to import existing AWS resources into Terraform state
# This resolves "ResourceAlreadyExists" errors

set -e

echo "Starting import of existing AWS resources..."

# Change to the Terraform directory
cd /Users/lerdisalihi/Downloads/ECSProject-main\ 2/ops/iac

# Import existing IAM roles
echo "Importing IAM roles..."
terraform import aws_iam_role.config config-recorder-role || echo "Config role already imported or doesn't exist"
terraform import aws_iam_role.codepipeline ecommerce-codepipeline-role || echo "CodePipeline role already imported or doesn't exist"
terraform import aws_iam_role.codebuild ecommerce-codebuild-role || echo "CodeBuild role already imported or doesn't exist"

# Import existing secrets
echo "Importing Secrets Manager secrets..."
terraform import aws_secretsmanager_secret.app app/secret || echo "App secret already imported or doesn't exist"
terraform import module.rds.aws_secretsmanager_secret.rds_credentials ecommerce-ecs-dev-db-rds-credentials || echo "RDS credentials already imported or doesn't exist"
terraform import module.rds_standby.aws_secretsmanager_secret.rds_credentials ecommerce-ecs-dev-db-standby-rds-credentials || echo "RDS standby credentials already imported or doesn't exist"
terraform import module.rds_dr.aws_secretsmanager_secret.rds_credentials ecommerce-ecs-dev-db-dr-rds-credentials || echo "RDS DR credentials already imported or doesn't exist"

# Import existing WAF WebACLs
echo "Importing WAF WebACLs..."
terraform import aws_wafv2_web_acl.cloudfront cloudfront-waf || echo "CloudFront WAF already imported or doesn't exist"
terraform import aws_wafv2_web_acl.alb alb-waf || echo "ALB WAF already imported or doesn't exist"

# Import existing Athena workgroups
echo "Importing Athena workgroups..."
terraform import module.athena.aws_athena_workgroup.logs ecommerce_workgroup || echo "Athena workgroup already imported or doesn't exist"
terraform import module.athena_dr.aws_athena_workgroup.logs ecommerce_workgroup || echo "Athena DR workgroup already imported or doesn't exist"

# Import existing CloudWatch log groups
echo "Importing CloudWatch log groups..."
terraform import module.cloudwatch.aws_cloudwatch_log_group.ecs /ecs/ecommerce-ecs-dev || echo "CloudWatch log group already imported or doesn't exist"
terraform import module.cloudwatch_dr.aws_cloudwatch_log_group.ecs /ecs/ecommerce-ecs-dev || echo "CloudWatch DR log group already imported or doesn't exist"

# Import existing ECR repositories
echo "Importing ECR repositories..."
terraform import module.ecr.aws_ecr_repository.backend ecommerce-backend-dev || echo "ECR repository already imported or doesn't exist"
terraform import module.ecr_dr.aws_ecr_repository.backend ecommerce-backend-dev || echo "ECR DR repository already imported or doesn't exist"

# Import existing ECS task execution roles
echo "Importing ECS task execution roles..."
terraform import module.ecs.aws_iam_role.ecs_task_execution ecommerce-ecs-dev-ecs-task-execution || echo "ECS task execution role already imported or doesn't exist"
terraform import module.ecs_standby.aws_iam_role.ecs_task_execution ecommerce-ecs-dev-standby-ecs-task-execution || echo "ECS standby task execution role already imported or doesn't exist"
terraform import module.ecs_dr.aws_iam_role.ecs_task_execution ecommerce-ecs-dev-dr-ecs-task-execution || echo "ECS DR task execution role already imported or doesn't exist"

# Import existing RDS parameter groups
echo "Importing RDS parameter groups..."
terraform import module.rds.aws_db_parameter_group.this ecommerce-ecs-dev-db-db-parameter-group || echo "RDS parameter group already imported or doesn't exist"
terraform import module.rds_standby.aws_db_parameter_group.this ecommerce-ecs-dev-db-standby-db-parameter-group || echo "RDS standby parameter group already imported or doesn't exist"
terraform import module.rds_dr.aws_db_parameter_group.this ecommerce-ecs-dev-db-dr-db-parameter-group || echo "RDS DR parameter group already imported or doesn't exist"

# Import existing RDS enhanced monitoring roles
echo "Importing RDS enhanced monitoring roles..."
terraform import module.rds.aws_iam_role.rds_enhanced_monitoring ecommerce-ecs-dev-db-rds-enhanced-monitoring || echo "RDS enhanced monitoring role already imported or doesn't exist"
terraform import module.rds_standby.aws_iam_role.rds_enhanced_monitoring ecommerce-ecs-dev-db-standby-rds-enhanced-monitoring || echo "RDS standby enhanced monitoring role already imported or doesn't exist"
terraform import module.rds_dr.aws_iam_role.rds_enhanced_monitoring ecommerce-ecs-dev-db-dr-rds-enhanced-monitoring || echo "RDS DR enhanced monitoring role already imported or doesn't exist"

# Import existing S3 buckets (if they exist and are owned by you)
echo "Importing S3 buckets..."
terraform import module.s3.aws_s3_bucket.frontend ecommerce-frontend-dev || echo "S3 frontend bucket already imported or doesn't exist"
terraform import module.s3.aws_s3_bucket.alb_logs ecommerce-alb-logs-dev || echo "S3 ALB logs bucket already imported or doesn't exist"
terraform import module.s3.aws_s3_bucket.cloudfront_logs ecommerce-cloudfront-logs-dev || echo "S3 CloudFront logs bucket already imported or doesn't exist"
terraform import module.s3_dr.aws_s3_bucket.frontend ecommerce-frontend-dr || echo "S3 DR frontend bucket already imported or doesn't exist"
terraform import module.s3_dr.aws_s3_bucket.alb_logs ecommerce-alb-logs-dr || echo "S3 DR ALB logs bucket already imported or doesn't exist"
terraform import module.s3_dr.aws_s3_bucket.cloudfront_logs ecommerce-cloudfront-logs-dr || echo "S3 DR CloudFront logs bucket already imported or doesn't exist"

# Import existing SNS Lambda roles
echo "Importing SNS Lambda roles..."
terraform import module.sns.aws_iam_role.lambda_slack_notifier[0] lambda-sns-slack-notifier-alerts || echo "SNS Lambda role already imported or doesn't exist"
terraform import module.sns_dr.aws_iam_role.lambda_slack_notifier[0] lambda-sns-slack-notifier-alerts-dr || echo "SNS DR Lambda role already imported or doesn't exist"

# Import existing X-Ray groups and roles
echo "Importing X-Ray resources..."
terraform import module.xray.aws_xray_group.default ecommerce-ecs-dev || echo "X-Ray group already imported or doesn't exist"
terraform import module.xray_dr.aws_xray_group.default ecommerce-ecs-dev || echo "X-Ray DR group already imported or doesn't exist"
terraform import module.xray.aws_iam_role.xray ecommerce-ecs-dev-xray-role || echo "X-Ray role already imported or doesn't exist"
terraform import module.xray_dr.aws_iam_role.xray ecommerce-ecs-dev-xray-role || echo "X-Ray DR role already imported or doesn't exist"

# Import existing DMS endpoints (if they exist)
echo "Importing DMS endpoints..."
terraform import module.dms.aws_dms_endpoint.source source-db-endpoint || echo "DMS source endpoint already imported or doesn't exist"
terraform import module.dms.aws_dms_endpoint.target target-db-endpoint || echo "DMS target endpoint already imported or doesn't exist"

echo "Import process completed. Some resources may not exist and that's expected."
echo "Now you can run 'terraform plan' to see what still needs to be created."
