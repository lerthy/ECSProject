#!/bin/bash

# Quick VPC Fix Script
# This script temporarily disables VPC creation to avoid limits

set -e

echo "🔧 Applying quick VPC fix to avoid limits..."

# Backup the original main.tf
cp main.tf main.tf.backup

# Comment out VPC modules to avoid creation
echo "📝 Commenting out VPC modules..."

# Comment out primary VPC module
sed -i.bak 's/^module "vpc" {/#module "vpc" {/' main.tf
sed -i.bak 's/^}/#}/' main.tf

# Comment out DR VPC module  
sed -i.bak 's/^module "vpc_dr" {/#module "vpc_dr" {/' main.tf

echo "✅ VPC modules commented out"
echo "📋 Next steps:"
echo "1. Run 'terraform plan' to see what resources can be created"
echo "2. Import existing resources as needed"
echo "3. Apply changes incrementally"
echo ""
echo "💡 To restore VPC modules later:"
echo "1. Run: mv main.tf.backup main.tf"
echo "2. Or manually uncomment the VPC module blocks"
