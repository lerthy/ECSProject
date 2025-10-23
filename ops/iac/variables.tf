# S3 replication variables (root)
variable "enable_s3_replication" {
  description = "Enable S3 cross-region replication from us-east-1 to eu-north-1"
  type        = bool
  default     = false
}
variable "replication_destination_bucket_arn" {
  description = "Destination S3 bucket ARN in eu-north-1 for replication"
  type        = string
  default     = ""
}
# Cross-region RDS replica/standby variables
variable "create_cross_region_replica" {
  description = "Whether to create a cross-region RDS replica (for DR region)"
  type        = bool
  default     = false
}
variable "replicate_source_db" {
  description = "ARN or identifier of the source DB for cross-region replica"
  type        = string
  default     = ""
}
# DMS variables for cross-region replication
variable "rds_source_username" {
  description = "Username for source RDS DB (us-east-1)"
  type        = string
}
variable "rds_source_password" {
  description = "Password for source RDS DB (us-east-1)"
  type        = string
  sensitive   = true
}
variable "rds_source_endpoint" {
  description = "Endpoint for source RDS DB (us-east-1)"
  type        = string
}
variable "rds_source_db_name" {
  description = "Database name for source RDS DB (us-east-1)"
  type        = string
}
variable "rds_target_username" {
  description = "Username for target RDS DB (eu-north-1)"
  type        = string
}
variable "rds_target_password" {
  description = "Password for target RDS DB (eu-north-1)"
  type        = string
  sensitive   = true
}
variable "rds_target_endpoint" {
  description = "Endpoint for target RDS DB (eu-north-1)"
  type        = string
}
variable "rds_target_db_name" {
  description = "Database name for target RDS DB (eu-north-1)"
  type        = string
}
# Optional: CloudFront aliases
variable "aliases" {
  description = "CloudFront distribution aliases"
  type        = list(string)
  default     = []
}

# Required: CloudFront distribution ID for CloudWatch
variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for metrics"
  type        = string
  default     = "dev-cloudfront-dist-id"
}

# Required: Environment name for CloudWatch

# Required: ALB name for CloudWatch
# Optional: CloudFront comment
variable "comment" {
  description = "Comment for CloudFront distribution"
  type        = string
  default     = "Development CloudFront distribution"
}

# Optional: CloudFront price class
variable "price_class" {
  description = "Price class for CloudFront distribution"
  type        = string
  default     = "PriceClass_100"
}
# Optional: Enable warm standby (default false)
variable "warm_standby" {
  description = "Enable warm standby ALB/ECS"
  type        = bool
  default     = false
}

# Optional: Enable WAF (default false)
variable "waf_enabled" {
  description = "Enable WAF protection"
  type        = bool
  default     = false
}

# Required: SNS alert email
variable "sns_alert_email" {
  description = "Email address for SNS alerts"
  type        = string
  default     = "dev-alerts@example.com"

  # Added variable validation per best practices
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.sns_alert_email))
    error_message = "Email address must be a valid email format."
  }
}
# CloudWatch dashboard and alarm variables
variable "dashboard_body" {
  description = "JSON body for CloudWatch dashboard"
  type        = string
  default     = "{}"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod, staging)"
  type        = string
  default     = "dev"

  # Added variable validation per best practices
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "ecs_cpu_threshold" {
  description = "CPU threshold for ECS CloudWatch alarm"
  type        = number
  default     = 80
}
# App secret for Secrets Manager
variable "app_secret_string" {
  description = "Secret string for application (example)"
  type        = string
  sensitive   = true
  default     = ""
}
variable "region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# VPC
variable "vpc_name" {
  description = "Name prefix for VPC"
  type        = string
}
variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string

  # Added variable validation per best practices
  validation {
    condition     = can(cidrhost(var.vpc_cidr_block, 0))
    error_message = "VPC CIDR block must be a valid IPv4 CIDR block."
  }
}
variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}
variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}
variable "db_subnets" {
  description = "List of database subnet CIDRs"
  type        = list(string)
}
variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

# DR (eu-north-1) variables
variable "vpc_name_dr" {
  description = "Name prefix for VPC in eu-north-1 (DR region)"
  type        = string
}
variable "vpc_cidr_block_dr" {
  description = "VPC CIDR block for eu-north-1 (DR region)"
  type        = string
}
variable "public_subnets_dr" {
  description = "List of public subnet CIDRs for eu-north-1 (DR region)"
  type        = list(string)
}
variable "private_subnets_dr" {
  description = "List of private subnet CIDRs for eu-north-1 (DR region)"
  type        = list(string)
}
variable "db_subnets_dr" {
  description = "List of database subnet CIDRs for eu-north-1 (DR region)"
  type        = list(string)
}
variable "azs_dr" {
  description = "List of availability zones for eu-north-1 (DR region)"
  type        = list(string)
}

variable "frontend_bucket_name_dr" {
  description = "Name for frontend S3 bucket in eu-north-1 (DR region)"
  type        = string
}
variable "alb_logs_bucket_name_dr" {
  description = "Name for ALB logs S3 bucket in eu-north-1 (DR region)"
  type        = string
}
variable "cloudfront_logs_bucket_name_dr" {
  description = "Name for CloudFront logs S3 bucket in eu-north-1 (DR region)"
  type        = string
}

# S3
variable "frontend_bucket_name" {
  description = "Name for frontend S3 bucket"
  type        = string
}
variable "alb_logs_bucket_name" {
  description = "Name for ALB logs S3 bucket"
  type        = string
}
variable "cloudfront_logs_bucket_name" {
  description = "Name for CloudFront logs S3 bucket"
  type        = string
}

# ALB
variable "alb_name" {
  description = "Name prefix for ALB"
  type        = string
}
variable "target_port" {
  description = "Target group port"
  type        = number
}
variable "health_check_path" {
  description = "Health check path"
  type        = string
}

# Route 53 and ALB DNS variables for failover
variable "route53_zone_id" {
  description = "Route 53 Hosted Zone ID for API DNS name"
  type        = string
}

variable "api_dns_name" {
  description = "DNS name for the API (e.g., api.example.com)"
  type        = string
}

variable "alb_zone_id" {
  description = "ALB DNS zone ID (from AWS documentation for your region)"
  type        = string
}

# ECS
variable "ecs_name" {
  description = "Name prefix for ECS"
  type        = string
}
variable "container_name" {
  description = "Container name"
  type        = string
}
variable "container_port" {
  description = "Container port"
  type        = number
}
variable "cpu" {
  description = "CPU units"
  type        = string
}
variable "memory" {
  description = "Memory (MB)"
  type        = string
}
variable "desired_count" {
  description = "Number of ECS tasks"
  type        = number
}

# CloudFront

# CloudWatch
variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
}

# SNS
variable "sns_slack_webhook" {
  description = "SNS Slack webhook URL"
  type        = string
}

# Athena
variable "athena_database_name" {
  description = "Athena database name"
  type        = string
}
variable "athena_workgroup_name" {
  description = "Athena workgroup name"
  type        = string
}
variable "athena_output_location" {
  description = "Athena query output S3 location"
  type        = string
}

# CI/CD Variables
variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "github_branch" {
  description = "GitHub branch to build from"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub OAuth token"
  type        = string
  sensitive   = true
}

# =====================
# RDS Database Variables
# =====================

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.7"
}

variable "rds_allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling in GB"
  type        = number
  default     = 100
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = true
}

variable "rds_backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "rds_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}
