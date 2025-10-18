variable "name" {
  description = "Name for SNS topic"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "email" {
  description = "Email address for SNS subscription (optional)"
  type        = string
  default     = ""
}

variable "slack_webhook" {
  description = "Slack webhook URL for SNS subscription (optional)"
  type        = string
  default     = ""
}
