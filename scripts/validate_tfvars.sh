#!/bin/bash

# Path to your tfvars file
TFVARS="terraform/environments/dev/terraform.tfvars"

# List of required variables
REQUIRED_VARS=(
  region environment vpc_name vpc_cidr_block public_subnets private_subnets azs
  frontend_bucket_name alb_logs_bucket_name cloudfront_logs_bucket_name
  ecs_name container_name container_port cpu memory desired_count container_definitions
  alb_name target_port health_check_path
  aliases comment price_class origin_access_identity
  log_retention_days dashboard_body ecs_cpu_threshold
  sns_email sns_slack_webhook
  api_dns_name route53_zone_id alb_zone_id
  athena_database_name athena_workgroup_name athena_output_location
  waf_enabled warm_standby app_secret_string
)

echo "Validating required variables in $TFVARS..."

missing=0
for var in "${REQUIRED_VARS[@]}"; do
  grep -q "^$var" "$TFVARS"
  if [ $? -ne 0 ]; then
    echo "❌ Missing variable: $var"
    missing=1
  fi
done

if [ $missing -eq 0 ]; then
  echo "✅ All required variables are present."
else
  echo "⚠️ Please add the missing variables above."
fi

# Check Athena S3 bucket exists
bucket=$(grep '^athena_output_location' "$TFVARS" | awk -F'"' '{print $2}' | sed 's|s3://||;s|/||g')
if [ -n "$bucket" ]; then
  aws s3 ls "s3://$bucket" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "✅ Athena output S3 bucket exists: $bucket"
  else
    echo "❌ Athena output S3 bucket does NOT exist: $bucket"
  fi
else
  echo "⚠️ Could not find athena_output_location in $TFVARS."
fi
