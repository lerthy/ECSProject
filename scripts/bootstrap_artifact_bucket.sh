#!/bin/bash
# Bootstrap artifact S3 bucket for CodePipeline
set -e

BUCKET_NAME="$1"
REGION="${2:-us-east-1}"

if [ -z "$BUCKET_NAME" ]; then
  echo "Usage: $0 <artifact-bucket-name> [region]"
  exit 1
fi

# Create S3 bucket if it doesn't exist

if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
  echo "S3 bucket $BUCKET_NAME already exists."
else
  echo "Creating S3 bucket: $BUCKET_NAME in $REGION..."
  if [ "$REGION" = "us-east-1" ]; then
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION"
  else
    aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
  fi
fi

# Enable versioning
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled

echo "✅ Artifact bucket $BUCKET_NAME is ready."
