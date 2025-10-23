# For cross-region replica/standby
variable "create_cross_region_replica" {
  description = "Whether to create a cross-region RDS replica (for DR region)"
  type        = bool
  default     = false
}
variable "replicate_source_db" {
  description = "ARN or identifier of the source DB for cross-region replica"
  type        = string
  default     = ""
}
# RDS Module Variables

variable "name" {
  description = "Name prefix for RDS resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  description = "VPC ID where RDS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for RDS subnet group"
  type        = list(string)
}

variable "app_security_group_id" {
  description = "Security group ID of the application (ECS) that needs database access"
  type        = string
}

# Database Configuration
variable "engine_version" {
  description = "PostgreSQL engine version"
  type        = string
  default     = "15.7"
}

variable "instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "Initial allocated storage in GB"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage for autoscaling in GB"
  type        = number
  default     = 100
}

variable "database_name" {
  description = "Name of the initial database"
  type        = string
  default     = "ecommerce"
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}

# High Availability and Reliability
variable "multi_az" {
  description = "Enable Multi-AZ deployment for high availability"
  type        = bool
  default     = true
}

variable "availability_zone" {
  description = "Availability zone for single-AZ deployment (ignored if multi_az is true)"
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "Number of days to retain backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "Preferred backup window (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "maintenance_window" {
  description = "Preferred maintenance window (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "auto_minor_version_upgrade" {
  description = "Enable automatic minor version upgrades"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when deleting the DB"
  type        = bool
  default     = false
}

# Encryption
variable "kms_key_id" {
  description = "KMS key ID for encryption (leave empty for default)"
  type        = string
  default     = null
}

# Monitoring and Performance
variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60
}

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 14
}

# Read Replica
variable "create_read_replica" {
  description = "Create a read replica for scaling read operations"
  type        = bool
  default     = false
}

variable "read_replica_instance_class" {
  description = "Instance class for read replica"
  type        = string
  default     = "db.t3.micro"
}

# CloudWatch Alarms
variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger"
  type        = list(string)
  default     = []
}

variable "cpu_alarm_threshold" {
  description = "CPU utilization threshold for alarm"
  type        = number
  default     = 80
}

variable "connection_alarm_threshold" {
  description = "Database connection count threshold for alarm"
  type        = number
  default     = 80
}

variable "free_storage_alarm_threshold" {
  description = "Free storage space threshold for alarm (in bytes)"
  type        = number
  default     = 1073741824 # 1GB in bytes
}
