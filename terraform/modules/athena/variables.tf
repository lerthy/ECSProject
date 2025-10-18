variable "database_name" {
  description = "Athena database name"
  type        = string
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
