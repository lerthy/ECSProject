#!/bin/bash

# Manual deployment script for when pipeline fails
set -e

echo "=== Manual Terraform Deployment ==="

cd ops/iac

# Initialize terraform
echo "Initializing Terraform..."
terraform init

# Create plan
echo "Creating Terraform plan..."
terraform plan -out=tfplan

# Apply changes
echo "Applying Terraform changes..."
terraform apply -auto-approve tfplan

echo "=== Manual deployment complete ==="
