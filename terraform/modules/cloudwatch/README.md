# CloudWatch Module

This module creates CloudWatch log groups, dashboards, and alarms for ECS and other AWS resources.

## Inputs
- `name`: Name prefix
- `log_retention_days`: Log retention (default: 30)
- `tags`: Tags for resources
- `dashboard_body`: JSON for dashboard
- `ecs_cpu_threshold`: CPU threshold for ECS alarm (default: 80)
- `ecs_cluster_name`: ECS cluster name for alarm
- `sns_topic_arn`: SNS topic ARN for notifications

## Outputs
- `log_group_name`: Log group name
- `dashboard_name`: Dashboard name
