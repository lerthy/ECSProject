variable "name" {
  description = "Name prefix for ALB resources"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs for ALB"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection for ALB"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID for target group"
  type        = string
}

variable "target_port" {
  description = "Port for target group"
  type        = number
}

variable "health_check_path" {
  description = "Health check path for target group"
  type        = string
  default     = "/health"
}


variable "access_logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
}
