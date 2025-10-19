# CloudWatch dashboard and alarm variables
variable "dashboard_body" {
  description = "JSON body for CloudWatch dashboard"
  type        = string
  default     = "{}"
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
  default     = "REPLACE_ME"
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
variable "container_definitions" {
  description = "Container definitions JSON"
  type        = string
}

# CloudFront
variable "origin_access_identity" {
  description = "CloudFront origin access identity"
  type        = string
}

# CloudWatch
variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
}
variable "dashboard_body" {
  description = "CloudWatch dashboard JSON"
  type        = string
}
variable "ecs_cpu_threshold" {
  description = "ECS CPU alarm threshold"
  type        = number
}

# SNS
variable "sns_email" {
  description = "SNS alert email"
  type        = string
}
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
