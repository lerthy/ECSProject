# ALB Module

This module creates an Application Load Balancer, target group, and listeners for ECS services.

## Inputs
- `name`: Name prefix
- `security_group_ids`: Security group IDs
- `public_subnet_ids`: Public subnet IDs
- `enable_deletion_protection`: Enable deletion protection (default: true)
- `tags`: Tags for resources
- `vpc_id`: VPC ID
- `target_port`: Target group port
- `health_check_path`: Health check path (default: /health)
- `certificate_arn`: ACM certificate ARN for HTTPS (optional) (removed)

## Outputs
- `alb_arn`: ALB ARN
- `alb_dns_name`: ALB DNS name
- `target_group_arn`: Target group ARN
This module creates an Application Load Balancer, target group, and HTTP listener for ECS services. HTTPS is not enabled by default.
