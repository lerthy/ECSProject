#!/bin/bash

echo "=== Pipeline Debug Information ==="

# Check AWS credentials
echo "Checking AWS credentials..."
aws sts get-caller-identity || echo "AWS credentials not configured"

# Check for existing resources
echo "Checking for existing resources..."
echo "VPCs:"
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,State,Tags[?Key==`Name`].Value|[0]]' --output table 2>/dev/null || echo "No VPCs found"

echo "S3 Buckets:"
aws s3 ls | grep ecommerce || echo "No ecommerce S3 buckets found"

echo "IAM Roles:"
aws iam list-roles --query 'Roles[?contains(RoleName, `ecommerce`) || contains(RoleName, `config`)].RoleName' --output table 2>/dev/null || echo "No ecommerce IAM roles found"

echo "Secrets Manager:"
aws secretsmanager list-secrets --query 'SecretList[?contains(Name, `ecommerce`) || contains(Name, `app`)].Name' --output table 2>/dev/null || echo "No ecommerce secrets found"

echo "=== Debug complete ==="
