# ECS (Fargate) Module

This module creates an ECS cluster, task definition, service, and required IAM roles for Fargate workloads.

## Inputs
- `name`: Name prefix
- `tags`: Tags for resources
- `cpu`: CPU units
- `memory`: Memory (MB)
- `container_definitions`: Container definitions JSON
- `desired_count`: Number of tasks
- `private_subnet_ids`: Private subnet IDs
- `security_group_ids`: Security group IDs
- `target_group_arn`: ALB target group ARN
- `container_name`: Container name for ALB
- `container_port`: Container port for ALB

## Outputs
- `cluster_id`: ECS Cluster ID
- `service_name`: ECS Service Name
- `task_definition_arn`: Task Definition ARN
