#!/bin/bash

# Handle VPC Limits Script
# This script addresses VPC limit exceeded errors

set -e

echo "🔍 Checking VPC limits and existing VPCs..."

# Get current VPC count
VPC_COUNT=$(aws ec2 describe-vpcs --query 'length(Vpcs)' --output text)
VPC_LIMIT=$(aws service-quotas get-service-quota --service-code ec2 --quota-code L-F678F1CE --query 'Quota.Value' --output text 2>/dev/null || echo "5")

echo "📊 Current VPC count: $VPC_COUNT"
echo "📊 VPC limit: $VPC_LIMIT"

if [ "$VPC_COUNT" -ge "$VPC_LIMIT" ]; then
    echo "⚠️  VPC limit reached! Current: $VPC_COUNT, Limit: $VPC_LIMIT"
    echo "🔍 Listing existing VPCs:"
    aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,State,Tags[?Key==`Name`].Value|[0]]' --output table
    
    echo ""
    echo "💡 Solutions:"
    echo "1. Delete unused VPCs to free up quota"
    echo "2. Request a VPC limit increase from AWS Support"
    echo "3. Use existing VPCs instead of creating new ones"
    
    echo ""
    echo "🔧 To delete unused VPCs (BE CAREFUL!):"
    echo "aws ec2 delete-vpc --vpc-id <vpc-id>"
    
    echo ""
    echo "📞 To request limit increase:"
    echo "1. Go to AWS Support Center"
    echo "2. Create a case for 'Service Limit Increase'"
    echo "3. Select 'EC2' service and 'VPC' quota"
    echo "4. Request increase to 10 or 20 VPCs"
    
else
    echo "✅ VPC count is within limits"
fi

echo ""
echo "🔍 Checking for existing VPCs that might be usable:"
aws ec2 describe-vpcs --query 'Vpcs[?State==`available`].[VpcId,Tags[?Key==`Name`].Value|[0],CidrBlock]' --output table

echo ""
echo "💡 If you want to use an existing VPC, you can:"
echo "1. Import it into Terraform state"
echo "2. Modify the Terraform configuration to use the existing VPC"
echo "3. Use data sources to reference existing VPCs"
