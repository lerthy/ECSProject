#!/bin/bash

# Quick fix script for common issues
echo "=== Quick Fix Script ==="

# Fix VPC limit issue by using existing VPCs
echo "Checking for existing VPCs..."
EXISTING_VPC=$(aws ec2 describe-vpcs --query 'Vpcs[0].VpcId' --output text 2>/dev/null || echo "")

if [ -n "$EXISTING_VPC" ] && [ "$EXISTING_VPC" != "None" ]; then
    echo "Found existing VPC: $EXISTING_VPC"
    echo "You can modify the VPC module to use this existing VPC instead of creating new ones"
    echo "Update the VPC module calls in main.tf to reference existing VPC ID: $EXISTING_VPC"
fi

# Check for existing resources that might conflict
echo "Checking for existing resources..."
aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
aws s3 ls | grep ecommerce
aws iam list-roles --query 'Roles[?contains(RoleName, `ecommerce`)].RoleName' --output table

echo "=== Quick Fix Complete ==="
