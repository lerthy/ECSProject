#!/bin/bash

# Comprehensive script to fix Terraform deployment issues
# This script addresses all the errors encountered in the deployment

set -e

echo "=== Terraform Deployment Fix Script ==="
echo "This script will fix the following issues:"
echo "1. Resource already exists conflicts"
echo "2. VPC limit exceeded"
echo "3. CloudWatch dashboard configuration"
echo "4. DMS IAM role issues"
echo "5. Provider configuration issues"
echo ""

# Change to the Terraform directory
cd /Users/lerdisalihi/Downloads/ECSProject-main\ 2/ops/iac

echo "Step 1: Checking VPC limits..."
../scripts/manage_vpc_limits.sh

echo ""
echo "Step 2: Importing existing resources..."
../scripts/import_existing_resources.sh

echo ""
echo "Step 3: Running terraform plan to check remaining issues..."
terraform plan -out=tfplan

echo ""
echo "Step 4: If plan looks good, applying changes..."
read -p "Do you want to apply the Terraform plan? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Applying Terraform plan..."
    terraform apply tfplan
else
    echo "Skipping apply. You can run 'terraform apply tfplan' later."
fi

echo ""
echo "=== Fix Summary ==="
echo "✅ Fixed CloudWatch dashboard configuration"
echo "✅ Added DMS IAM role configuration"
echo "✅ Added required_providers to modules"
echo "✅ Created import script for existing resources"
echo "✅ Created VPC management script"
echo ""
echo "Next steps:"
echo "1. Review the VPC situation and either delete unused VPCs or import existing ones"
echo "2. Run the import script to import existing resources"
echo "3. Run 'terraform plan' to verify the configuration"
echo "4. Apply the changes with 'terraform apply'"
