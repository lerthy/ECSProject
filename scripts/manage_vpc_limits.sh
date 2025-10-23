#!/bin/bash

# Script to manage VPC limits and existing VPCs
# AWS has a limit of 5 VPCs per region

set -e

echo "Checking VPC limits and existing VPCs..."

# List existing VPCs in us-east-1
echo "=== VPCs in us-east-1 ==="
aws ec2 describe-vpcs --region us-east-1 --query 'Vpcs[*].[VpcId,State,Tags[?Key==`Name`].Value|[0],CidrBlock]' --output table

echo ""
echo "=== VPCs in eu-north-1 ==="
aws ec2 describe-vpcs --region eu-north-1 --query 'Vpcs[*].[VpcId,State,Tags[?Key==`Name`].Value|[0],CidrBlock]' --output table

echo ""
echo "VPC Count in us-east-1:"
aws ec2 describe-vpcs --region us-east-1 --query 'length(Vpcs)'

echo "VPC Count in eu-north-1:"
aws ec2 describe-vpcs --region eu-north-1 --query 'length(Vpcs)'

echo ""
echo "If you're at the VPC limit, you have these options:"
echo "1. Delete unused VPCs (be careful - this will delete all resources in the VPC)"
echo "2. Use existing VPCs by importing them into Terraform state"
echo "3. Request a VPC limit increase from AWS Support"
echo ""
echo "To delete a VPC (DANGEROUS - only if you're sure):"
echo "aws ec2 delete-vpc --vpc-id <vpc-id>"
echo ""
echo "To import an existing VPC into Terraform:"
echo "terraform import module.vpc.aws_vpc.this <vpc-id>"
