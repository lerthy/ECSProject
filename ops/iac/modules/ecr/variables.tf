variable "environment" {
  description = "Environment name (e.g., dev, prod, staging)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "create_repository" {
  description = "Whether to create the ECR repository or use existing one"
  type        = bool
  default     = true
}
