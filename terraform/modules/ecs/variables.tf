variable "name" {
  description = "Name prefix for ECS resources"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "cpu" {
  description = "CPU units for the ECS task"
  type        = string
}

variable "memory" {
  description = "Memory for the ECS task (MB)"
  type        = string
}

variable "container_definitions" {
  description = "Container definitions JSON"
  type        = string
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for ECS tasks"
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "container_name" {
  description = "Name of the container to attach to the ALB"
  type        = string
}

variable "container_port" {
  description = "Port on the container to attach to the ALB"
  type        = number
}
