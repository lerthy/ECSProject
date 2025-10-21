# X-Ray Module

This module creates an AWS X-Ray group and IAM role for distributed tracing.

## Inputs
- `name`: Name for X-Ray group and role
- `tags`: Tags for resources

## Outputs
- `xray_group_name`: X-Ray group name
- `xray_role_arn`: IAM role ARN for X-Ray
