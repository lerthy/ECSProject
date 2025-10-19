#!/bin/bash
# Script to create Athena output S3 bucket for dev environment
BUCKET="ecommerce-athena-results-dev"

if aws s3 ls "s3://$BUCKET" > /dev/null 2>&1; then
  echo "✅ Bucket already exists: $BUCKET"
else
  echo "Creating bucket: $BUCKET"
  aws s3 mb "s3://$BUCKET"
  if [ $? -eq 0 ]; then
    echo "✅ Bucket created: $BUCKET"
  else
    echo "❌ Failed to create bucket: $BUCKET"
  fi
fi
