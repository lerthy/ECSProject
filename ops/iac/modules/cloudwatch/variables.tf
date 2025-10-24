# Required: ALB name for CloudWatch
variable "alb_name" {
  description = "ALB name for CloudWatch"
  type        = string
}

# Required: Environment name for CloudWatch
variable "environment" {
  description = "Environment name for CloudWatch"
  type        = string
}

# Required: CloudFront distribution ID for CloudWatch
variable "cloudfront_distribution_id" {
  description = "CloudFront distribution ID for metrics"
  type        = string
}
variable "name" {
  description = "Name prefix for CloudWatch resources"
  type        = string
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "dashboard_body" {
  description = "JSON body for CloudWatch dashboard"
  type        = string
}

variable "ecs_cpu_threshold" {
  description = "CPU threshold for ECS alarm"
  type        = number
  default     = 80
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for alarm dimension"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS service name for alarm dimension"
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix for CloudWatch metrics"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  type        = string
}
