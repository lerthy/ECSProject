terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

# Data source for existing VPC (used when use_existing_vpc = true)
# This prevents "VpcLimitExceeded" errors
data "aws_vpc" "existing" {
  count = var.use_existing_vpc ? 1 : 0
  id    = var.existing_vpc_id != "" ? var.existing_vpc_id : null
  
  # If no VPC ID provided, find by name tag
  dynamic "filter" {
    for_each = var.existing_vpc_id == "" ? [1] : []
    content {
      name   = "tag:Name"
      values = ["${var.name}-vpc"]
    }
  }
}

# VPC with lifecycle to prevent destruction
# Only create if use_existing_vpc is false
resource "aws_vpc" "this" {
  count                = var.use_existing_vpc ? 0 : 1
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge(var.tags, { Name = "${var.name}-vpc" })

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      cidr_block,
      tags
    ]
  }
}

# Local variable to reference the VPC ID (either existing or newly created)
locals {
  vpc_id = var.use_existing_vpc ? data.aws_vpc.existing[0].id : aws_vpc.this[0].id
}

resource "aws_internet_gateway" "this" {
  vpc_id = local.vpc_id
  tags   = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  tags          = merge(var.tags, { Name = "${var.name}-nat" })
}

resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.this]
}

resource "aws_subnet" "public" {
  count                   = length(var.public_subnets)
  vpc_id                  = local.vpc_id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone       = element(var.azs, count.index)
  tags                    = merge(var.tags, { Name = "${var.name}-public-${count.index}" })
}

resource "aws_subnet" "private" {
  count             = length(var.private_subnets)
  vpc_id            = local.vpc_id
  cidr_block        = var.private_subnets[count.index]
  availability_zone = element(var.azs, count.index)
  tags              = merge(var.tags, { Name = "${var.name}-private-${count.index}" })
}

resource "aws_subnet" "db_subnet" {
  count             = length(var.db_subnets)
  vpc_id            = local.vpc_id
  cidr_block        = var.db_subnets[count.index]
  availability_zone = element(var.azs, count.index)
  tags = merge(var.tags, {
    Name = "${var.name}-db-${count.index}",
    Type = "Database"
  })
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.name}-public-rt" })
}

resource "aws_route_table" "private" {
  vpc_id = local.vpc_id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = merge(var.tags, { Name = "${var.name}-private-rt" })
}

resource "aws_route_table" "database" {
  vpc_id = local.vpc_id
  tags   = merge(var.tags, { Name = "${var.name}-database-rt" })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  for_each       = { for idx, subnet in aws_subnet.public : idx => subnet }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each       = { for idx, subnet in aws_subnet.private : idx => subnet }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "database" {
  for_each       = { for idx, subnet in aws_subnet.db_subnet : idx => subnet }
  subnet_id      = each.value.id
  route_table_id = aws_route_table.database.id
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  vpc_id      = local.vpc_id
  description = "Security group for ALB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP inbound"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS inbound"
  }

  # Restricted egress rules per best practices
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound"
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound"
  }

  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS outbound"
  }

  tags = merge(var.tags, { Name = "${var.name}-alb-sg" })
}

resource "aws_security_group" "ecs" {
  name_prefix = "${var.name}-ecs-"
  vpc_id      = local.vpc_id
  description = "Security group for ECS tasks"

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-ecs-sg" })
}

output "vpc_id" {
  value = local.vpc_id
}
output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}
output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}
output "db_subnet_ids" {
  value = aws_subnet.db_subnet[*].id
}
output "igw_id" {
  value = aws_internet_gateway.this.id
}
output "nat_gateway_id" {
  value = aws_nat_gateway.this.id
}
output "alb_security_group_id" {
  value = aws_security_group.alb.id
}
output "ecs_security_group_id" {
  value = aws_security_group.ecs.id
}
