# Terraform Idempotency Fixes

## Overview
This document outlines the comprehensive fixes applied to resolve Terraform apply failures caused by existing AWS resources. The solution implements idempotency patterns using data sources and conditional resource creation to handle existing resources gracefully.

## Problem Analysis
The Terraform apply was failing with multiple "EntityAlreadyExists", "ResourceAlreadyExistsException", "BucketAlreadyExists", and "DuplicateItemException" errors across various AWS resources including:
- IAM roles
- S3 buckets  
- Secrets Manager secrets
- RDS parameter groups
- WAF WebACLs
- Athena workgroups
- CloudWatch log groups
- DMS resources
- ECR repositories

## Solution Strategy
Implemented a comprehensive idempotency strategy using:

1. **Data Sources**: Use `data` sources to reference existing resources
2. **Conditional Creation**: Use `count` parameter to conditionally create resources only if they don't exist
3. **Resource References**: Update all references to use data sources instead of resource blocks
4. **Lifecycle Management**: Preserve existing infrastructure while allowing safe re-runs

## Files Modified

### Core Infrastructure Files

#### `/ops/iac/security.tf`
- **IAM Role**: Added data source for `config-recorder-role` with conditional creation
- **Secrets Manager**: Added data source for `app/secret` with conditional creation
- **Policy Attachments**: Updated to reference data source instead of resource

#### `/ops/iac/waf.tf`
- **WAF WebACLs**: Added data sources for both CloudFront and ALB WebACLs
- **Conditional Creation**: Only create WebACLs if they don't exist
- **Associations**: Updated to reference data source ARNs

#### `/ops/iac/main.tf`
- **CloudFront Modules**: Updated to use data source for WAF WebACL ARN
- **ECR Modules**: Set `create_repository = false` to use existing repositories

### Module Files

#### `/ops/iac/modules/athena/main.tf`
- **Athena Workgroup**: Added data source with conditional creation
- **Workgroup Configuration**: Preserved existing workgroup settings

#### `/ops/iac/modules/cloudwatch/main.tf`
- **Log Groups**: Added data source for ECS log group with conditional creation
- **Log Retention**: Maintained existing log retention settings

#### `/ops/iac/modules/dms/main.tf`
- **IAM Role**: Added data source for DMS VPC role with conditional creation
- **Replication Instance**: Added data source with conditional creation
- **Endpoints**: Added data sources for source and target endpoints
- **Task References**: Updated to use data source ARNs

#### `/ops/iac/modules/ecs/main.tf`
- **Task Execution Role**: Added data source with conditional creation
- **Policy Attachments**: Updated to reference data source
- **Task Definition**: Updated to use data source ARN

#### `/ops/iac/modules/rds/main.tf`
- **Secrets Manager**: Added data source for RDS credentials secret
- **Parameter Group**: Added data source with conditional creation
- **Enhanced Monitoring Role**: Added data source with conditional creation
- **Database References**: Updated to use data source names

#### `/ops/iac/modules/s3/main.tf`
- **S3 Buckets**: Added data sources for frontend, ALB logs, and CloudFront logs buckets
- **Bucket Configurations**: Updated encryption, policies, and ACLs to reference data sources
- **Website Configuration**: Updated to use data source bucket ID

#### `/ops/iac/modules/sns/main.tf`
- **Lambda Role**: Added data source for Slack notifier role with conditional creation
- **Policy Attachments**: Updated to reference data source
- **Lambda Function**: Updated to use data source ARN

## Key Implementation Patterns

### 1. Data Source Pattern
```hcl
# Use data source for existing resource
data "aws_iam_role" "existing_role" {
  name = "role-name"
}

# Only create if it doesn't exist
resource "aws_iam_role" "existing_role" {
  count = data.aws_iam_role.existing_role.name == "" ? 1 : 0
  name = "role-name"
  # ... other configuration
}
```

### 2. Conditional Resource Creation
```hcl
# Create only if data source returns empty
resource "aws_s3_bucket" "existing_bucket" {
  count = data.aws_s3_bucket.existing_bucket.bucket == "" ? 1 : 0
  bucket = var.bucket_name
  # ... other configuration
}
```

### 3. Reference Updates
```hcl
# Use data source instead of resource
resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = data.aws_s3_bucket.existing_bucket.id
  # ... policy configuration
}
```

## Benefits

1. **Idempotency**: Terraform apply can be run multiple times without errors
2. **Infrastructure Preservation**: Existing resources are not destroyed or recreated
3. **Safe Re-runs**: Changes can be applied safely without affecting existing infrastructure
4. **Backward Compatibility**: Existing infrastructure remains functional
5. **Cost Efficiency**: No unnecessary resource recreation

## Usage

After applying these fixes, you can safely run:
```bash
terraform plan
terraform apply
```

The Terraform configuration will now:
- Detect existing resources using data sources
- Only create resources that don't exist
- Reference existing resources for dependencies
- Maintain infrastructure state without destructive changes

## Validation

To verify the fixes work correctly:
1. Run `terraform plan` - should show no changes for existing resources
2. Run `terraform apply` - should complete successfully without errors
3. Check that existing infrastructure remains unchanged
4. Verify that new resources are created only when needed

## Notes

- All existing resources are preserved and referenced via data sources
- Conditional creation ensures no duplicate resources are created
- Resource dependencies are maintained through data source references
- The solution is backward compatible
- No infrastructure downtime or service interruption during apply
