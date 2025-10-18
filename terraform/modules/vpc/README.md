# VPC Module

This module creates a VPC, public/private subnets, Internet Gateway, and NAT Gateway for AWS.

## Inputs
- `name`: Name prefix for resources
- `cidr_block`: VPC CIDR block
- `public_subnets`: List of public subnet CIDRs
- `private_subnets`: List of private subnet CIDRs
- `azs`: List of availability zones
- `tags`: Map of tags

## Outputs
- `vpc_id`: The VPC ID
- `public_subnet_ids`: Public subnet IDs
- `private_subnet_ids`: Private subnet IDs
- `igw_id`: Internet Gateway ID
- `nat_gateway_id`: NAT Gateway ID
