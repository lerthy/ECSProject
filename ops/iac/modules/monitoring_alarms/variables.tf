variable "environment" {
  type = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}

variable "alb_name" {
  description = "Name of the ALB"
  type        = string
}

variable "alb_latency_threshold" {
  description = "Threshold for ALB latency alarm (seconds)"
  type        = number
  default     = 1
}

variable "alb_5xx_threshold" {
  description = "Threshold for ALB 5xx error count alarm"
  type        = number
  default     = 5
}

variable "cloudfront_cache_hit_ratio_threshold" {
  description = "Threshold for CloudFront cache hit ratio alarm (%)"
  type        = number
  default     = 80
}
