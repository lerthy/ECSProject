#!/bin/bash

# Script to handle VPC limits and existing VPCs
# This script helps manage VPC limits and import existing VPCs

set -e

echo "=== VPC Limit Management Script ==="

# Function to check VPC limits
check_vpc_limits() {
    echo "Checking current VPC limits and usage..."
    
    # Get current VPC count
    local vpc_count=$(aws ec2 describe-vpcs --query 'Vpcs | length(@)' --output text)
    echo "Current VPC count: $vpc_count"
    
    # Get VPC limit
    local vpc_limit=$(aws service-quotas get-service-quota --service-code ec2 --quota-code L-F678F1CE --query 'Quota.Value' --output text 2>/dev/null || echo "5")
    echo "VPC limit: $vpc_limit"
    
    if [ "$vpc_count" -ge "$vpc_limit" ]; then
        echo "⚠ WARNING: VPC limit reached or exceeded!"
        echo "Current VPCs:"
        aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,State,Tags[?Key==`Name`].Value|[0]]' --output table
        return 1
    else
        echo "✓ VPC limit not exceeded"
        return 0
    fi
}

# Function to list existing VPCs
list_existing_vpcs() {
    echo "=== Existing VPCs ==="
    aws ec2 describe-vpcs --query 'Vpcs[*].[VpcId,State,CidrBlock,Tags[?Key==`Name`].Value|[0]]' --output table
}

# Function to find VPCs that might be used for this project
find_project_vpcs() {
    echo "=== Looking for project-related VPCs ==="
    
    # Look for VPCs with ecommerce-related names
    aws ec2 describe-vpcs --query 'Vpcs[?contains(Tags[?Key==`Name`].Value, `ecommerce`) || contains(Tags[?Key==`Name`].Value, `dev`) || contains(Tags[?Key==`Name`].Value, `main`)].{VpcId:VpcId,Name:Tags[?Key==`Name`].Value|[0],CidrBlock:CidrBlock,State:State}' --output table
}

# Function to import existing VPC
import_vpc() {
    local vpc_id="$1"
    local vpc_name="$2"
    
    echo "Attempting to import VPC: $vpc_id ($vpc_name)"
    
    # Try to import the VPC
    if terraform import "module.vpc.aws_vpc.this" "$vpc_id" 2>/dev/null; then
        echo "✓ Successfully imported VPC: $vpc_id"
        return 0
    else
        echo "⚠ Failed to import VPC: $vpc_id"
        return 1
    fi
}

# Function to delete unused VPCs (with confirmation)
delete_unused_vpcs() {
    echo "=== VPC Cleanup ==="
    echo "WARNING: This will delete VPCs that are not in use!"
    echo "Make sure you have backups and that these VPCs are not needed."
    
    read -p "Do you want to proceed with VPC cleanup? (yes/no): " confirm
    
    if [ "$confirm" = "yes" ]; then
        echo "Listing VPCs that might be safe to delete..."
        
        # List VPCs that are not the default VPC and have no resources
        aws ec2 describe-vpcs --query 'Vpcs[?IsDefault==`false`].[VpcId,Tags[?Key==`Name`].Value|[0]]' --output table
        
        echo "Please manually delete unused VPCs using the AWS Console or CLI"
        echo "Example: aws ec2 delete-vpc --vpc-id vpc-xxxxxxxxx"
    else
        echo "VPC cleanup cancelled"
    fi
}

# Function to request VPC limit increase
request_limit_increase() {
    echo "=== Requesting VPC Limit Increase ==="
    echo "To request a VPC limit increase:"
    echo "1. Go to AWS Service Quotas console"
    echo "2. Search for 'VPCs per Region'"
    echo "3. Request a quota increase"
    echo "4. Or use AWS CLI:"
    echo "   aws service-quotas request-service-quota-increase --service-code ec2 --quota-code L-F678F1CE --desired-value 10"
}

# Main execution
echo "Starting VPC limit management..."

# Check current limits
if ! check_vpc_limits; then
    echo ""
    echo "VPC limit exceeded. Options:"
    echo "1. Import existing VPCs"
    echo "2. Delete unused VPCs"
    echo "3. Request limit increase"
    echo "4. Use existing VPCs"
    
    read -p "Choose an option (1-4): " option
    
    case $option in
        1)
            echo "Listing existing VPCs for potential import..."
            list_existing_vpcs
            find_project_vpcs
            ;;
        2)
            delete_unused_vpcs
            ;;
        3)
            request_limit_increase
            ;;
        4)
            echo "You can modify the terraform configuration to use existing VPCs"
            echo "Update the VPC module calls to reference existing VPC IDs"
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
else
    echo "VPC limits are within acceptable range"
    list_existing_vpcs
fi

echo "=== VPC Management Complete ==="
