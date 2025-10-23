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
  default     = "dev-placeholder"
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
  default     = "dev-placeholder"
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
  default     = ""
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
