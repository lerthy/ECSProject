# Terraform Modules

This directory contains reusable modules for the E-Commerce AWS infrastructure:
- `vpc`: Networking (VPC, subnets, gateways)
- `ecs`: ECS cluster, task, service, IAM
- `alb`: Application Load Balancer
- `s3`: S3 buckets for frontend and logs
- `cloudfront`: CloudFront distribution for static frontend
- `cloudwatch`: CloudWatch logs, dashboards, alarms
- `sns`: SNS topic and alert subscriptions
- `xray`: AWS X-Ray tracing
- `athena`: Athena database and workgroup for log analysis

See each module's README for usage and variables.
