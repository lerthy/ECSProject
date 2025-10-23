variable "replication_instance_id" { type = string }

variable "allocated_storage" {
  type    = number
  default = 50
}
variable "replication_instance_class" {
  type    = string
  default = "dms.t3.medium"
}
variable "engine_version" {
  type    = string
  default = "3.4.7"
}
variable "publicly_accessible" {
  type    = bool
  default = false
}
variable "multi_az" {
  type    = bool
  default = true
}
variable "auto_minor_version_upgrade" {
  type    = bool
  default = true
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "source_endpoint_id" {
  type = string
}
variable "source_engine_name" {
  type    = string
  default = "postgres"
}
variable "source_username" {
  type = string
}
variable "source_password" {
  type      = string
  sensitive = true
}
variable "source_server_name" {
  type = string
}
variable "source_port" {
  type    = number
  default = 5432
}
variable "source_database_name" {
  type = string
}
variable "source_ssl_mode" {
  type    = string
  default = "require"
}

variable "target_endpoint_id" {
  type = string
}
variable "target_engine_name" {
  type    = string
  default = "postgres"
}
variable "target_username" {
  type = string
}
variable "target_password" {
  type      = string
  sensitive = true
}
variable "target_server_name" {
  type = string
}
variable "target_port" {
  type    = number
  default = 5432
}
variable "target_database_name" {
  type = string
}
variable "target_ssl_mode" {
  type    = string
  default = "require"
}

variable "replication_task_id" {
  type = string
}
variable "migration_type" {
  type    = string
  default = "full-load-and-cdc"
}
variable "table_mappings" {
  type = string
}
variable "replication_task_settings" {
  type = string
}

variable "alarm_actions" {
  type        = list(string)
  description = "List of SNS topic ARNs for alarm actions"
  default     = []
}
