variable "name" {
  description = "Name for X-Ray group and IAM role"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
