# Terraform Issues Fixed - Comprehensive Summary

## 🔧 **Issues Addressed**

### 1. **Invalid Count Argument Errors** ✅ FIXED
**Problem**: `count = length(aws_subnet.public)` depends on resources not yet created.

**Solution**: Replaced `count` with `for_each` in VPC module route table associations:
```hcl
# Before (problematic)
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# After (fixed)
resource "aws_route_table_association" "public" {
  for_each       = { for idx, subnet in aws_subnet.public : idx => subnet }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
```

### 2. **Deprecated Attribute Usage** ✅ FIXED
**Problem**: `data.aws_region.current.name` is deprecated.

**Solution**: Replaced all `.name` with `.id`:
```hcl
# Before
region = data.aws_region.current.name

# After
region = data.aws_region.current.id
```

**Files Updated**:
- `ops/iac/operational_excellence.tf`
- `ops/iac/templates.tf`

### 3. **Provider Version Updates** ✅ FIXED
**Problem**: Outdated AWS provider version.

**Solution**: Updated to AWS provider v5.0+:
```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}
```

### 4. **GitHub v1 CodePipeline Actions** ✅ FIXED
**Problem**: Deprecated GitHub v1 actions in CodePipeline.

**Solution**: Replaced with CodeStar Connection v2:
```hcl
# Added CodeStar Connection
resource "aws_codestarconnections_connection" "github" {
  name          = "github-connection"
  provider_type = "GitHub"
  tags          = var.tags
}

# Updated pipeline actions
action {
  name             = "Source"
  category         = "Source"
  owner            = "AWS"
  provider         = "CodeStarSourceConnection"
  version          = "1"
  output_artifacts = ["terraform_source"]

  configuration = {
    ConnectionArn    = aws_codestarconnections_connection.github.arn
    FullRepositoryId = "${var.github_owner}/${var.github_repo}"
    BranchName       = var.github_branch
  }
}
```

### 5. **Resource Conflicts (EntityAlreadyExists)** ✅ FIXED
**Problem**: Resources already exist causing conflicts.

**Solution**: Added conditional creation and data sources:

#### ECR Repository
```hcl
# Conditional creation
resource "aws_ecr_repository" "backend" {
  count                = var.create_repository ? 1 : 0
  name                 = "ecommerce-backend-${var.environment}"
  tags                 = var.tags
  image_tag_mutability = "MUTABLE"
}

# Data source for existing
data "aws_ecr_repository" "backend" {
  count = var.create_repository ? 0 : 1
  name  = "ecommerce-backend-${var.environment}"
}
```

#### SNS Topic
```hcl
# Conditional creation
resource "aws_sns_topic" "alerts" {
  count = var.create_topic ? 1 : 0
  name  = var.name
  tags  = var.tags
}

# Data source for existing
data "aws_sns_topic" "alerts" {
  count = var.create_topic ? 0 : 1
  name  = var.name
}
```

#### Athena Workgroup
```hcl
# Conditional creation
resource "aws_athena_workgroup" "logs" {
  count = var.create_workgroup ? 1 : 0
  name  = var.workgroup_name
  # ... configuration
}

# Data source for existing
data "aws_athena_workgroup" "logs" {
  count = var.create_workgroup ? 0 : 1
  name  = var.workgroup_name
}
```

### 6. **Lifecycle Rules for Production Safety** ✅ ADDED
**Solution**: Added lifecycle rules to prevent accidental destruction:
```hcl
resource "aws_db_instance" "primary" {
  # ... configuration
  
  lifecycle {
    prevent_destroy = var.environment == "prod" ? true : false
    ignore_changes  = [password, final_snapshot_identifier]
  }
}
```

## 📋 **Import Commands for Existing Resources**

If you have existing resources, use these import commands:

```bash
# ECR Repository
terraform import 'aws_ecr_repository.backend' ecommerce-backend-dev

# SNS Topic
terraform import 'aws_sns_topic.alerts' alerts

# Athena Workgroup
terraform import 'aws_athena_workgroup.logs' ecommerce_workgroup

# CloudWatch Log Group
terraform import 'aws_cloudwatch_log_group.postgresql' /aws/rds/instance/ecommerce-db-dev-primary/postgresql

# WAF Web ACL (replace with actual ARN)
terraform import 'aws_wafv2_web_acl.cloudfront' arn:aws:wafv2:us-east-1:ACCOUNT_ID:global/webacl/CLOUDFRONT_WAF_ID

# Secrets Manager Secret
terraform import 'aws_secretsmanager_secret.rds_credentials' ecommerce-db-dev-rds-credentials
```

## 🔄 **Module Variables Added**

### ECR Module
```hcl
variable "create_repository" {
  description = "Whether to create the ECR repository or use existing one"
  type        = bool
  default     = true
}
```

### SNS Module
```hcl
variable "create_topic" {
  description = "Whether to create the SNS topic or use existing one"
  type        = bool
  default     = true
}
```

### Athena Module
```hcl
variable "create_workgroup" {
  description = "Whether to create the Athena workgroup or use existing one"
  type        = bool
  default     = true
}
```

### RDS Module
```hcl
variable "environment" {
  description = "Environment name (e.g., dev, prod, staging)"
  type        = string
  default     = "dev"
}
```

## 🚀 **Next Steps**

1. **Review the import blocks** in `imports.tf` and uncomment/modify as needed
2. **Set module variables** to `false` for existing resources:
   ```hcl
   module "ecr" {
     source            = "./modules/ecr"
     create_repository = false  # Set to false if ECR already exists
     # ... other variables
   }
   ```
3. **Run terraform plan** to verify no destructive changes
4. **Run terraform apply** to apply the fixes

## ✅ **Validation Checklist**

- [ ] All count arguments replaced with for_each
- [ ] All deprecated `.name` attributes replaced with `.id`
- [ ] AWS provider updated to v5.0+
- [ ] GitHub v1 actions replaced with CodeStar Connection v2
- [ ] Conditional creation added for existing resources
- [ ] Lifecycle rules added for production safety
- [ ] Import blocks prepared for existing resources
- [ ] Terraform plan runs without errors
- [ ] No destructive changes detected

## 📝 **Notes**

- The CodeStar Connection requires manual approval in the AWS Console
- All modules now support conditional creation to handle existing resources
- Production environments have additional safety measures with lifecycle rules
- Import blocks are provided as examples - update with actual resource IDs
