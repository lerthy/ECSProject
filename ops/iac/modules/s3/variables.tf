# S3 replication variables
variable "enable_replication" {
  description = "Enable S3 cross-region replication"
  type        = bool
  default     = false
}
variable "replication_role_arn" {
  description = "IAM Role ARN for S3 replication"
  type        = string
  default     = ""
}
variable "replication_destination_bucket" {
  description = "Destination bucket ARN for replication"
  type        = string
  default     = ""
}
variable "frontend_bucket_name" {
  description = "Name for the S3 bucket hosting the frontend"
  type        = string
}

variable "alb_logs_bucket_name" {
  description = "Name for the S3 bucket storing ALB logs"
  type        = string
}

variable "cloudfront_logs_bucket_name" {
  description = "Name for the S3 bucket storing CloudFront logs"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
