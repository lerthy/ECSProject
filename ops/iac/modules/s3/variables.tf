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
