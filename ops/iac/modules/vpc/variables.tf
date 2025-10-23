variable "name" {
  description = "Name prefix for resources"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "db_subnets" {
  description = "List of database subnet CIDRs"
  type        = list(string)
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "use_existing_vpc" {
  description = "Whether to use existing VPC instead of creating a new one (prevents VPC limit errors)"
  type        = bool
  default     = true
}

variable "existing_vpc_id" {
  description = "Existing VPC ID to use when use_existing_vpc is true"
  type        = string
  default     = ""
}
