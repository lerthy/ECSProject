#!/bin/bash
# Bootstrap Terraform backend resources: S3 bucket and DynamoDB table
set -e

BUCKET="observability-terraform-backend"
REGION="eu-central-1"
TABLE="terraform-state-lock"

# Create S3 bucket if it doesn't exist
echo "Creating S3 bucket: $BUCKET in $REGION..."
aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null || aws s3 mb s3://$BUCKET --region $REGION

# Create DynamoDB table if it doesn't exist
echo "Creating DynamoDB table: $TABLE..."
if ! aws dynamodb describe-table --table-name "$TABLE" --region $REGION 2>/dev/null; then
  aws dynamodb create-table \
    --table-name "$TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $REGION
else
  echo "DynamoDB table $TABLE already exists."
fi

echo "✅ Terraform backend initialized."
