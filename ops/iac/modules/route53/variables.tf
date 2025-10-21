variable "primary_alb_dns_name" {
  description = "DNS name of the primary ALB"
  type        = string
}

variable "standby_alb_dns_name" {
  description = "DNS name of the standby ALB"
  type        = string
}

variable "alb_zone_id" {
  description = "Zone ID for the ALB"
  type        = string
}

variable "route53_zone_id" {
  description = "Route 53 Hosted Zone ID"
  type        = string
}

variable "api_dns_name" {
  description = "DNS name for the API record"
  type        = string
}

variable "health_check_path" {
  description = "Path for the health check"
  type        = string
  default     = "/"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
