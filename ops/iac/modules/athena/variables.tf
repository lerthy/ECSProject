variable "database_name" {
  description = "Athena database name"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "alb_logs_bucket_name" {
  description = "S3 bucket name for ALB logs"
  type        = string
  default     = "dev-ecom-alb-logs"
}

variable "alb_logs_s3_location" {
  description = "S3 location for ALB access logs"
  type        = string
}

variable "cloudfront_logs_bucket_name" {
  description = "S3 bucket name for CloudFront logs"
  type        = string
  default     = "dev-ecom-cloudfront-logs"
}

variable "cloudfront_logs_s3_location" {
  description = "S3 location for CloudFront access logs"
  type        = string
  default     = ""
}

variable "s3_bucket" {
  description = "S3 bucket for Athena database"
  type        = string
}

variable "workgroup_name" {
  description = "Athena workgroup name"
  type        = string
}

variable "output_location" {
  description = "S3 output location for Athena query results"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
