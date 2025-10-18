# S3 Module

This module creates S3 buckets for:
- Static frontend hosting
- ALB logs
- CloudFront logs

## Inputs
- `frontend_bucket_name`: Name for frontend bucket
- `alb_logs_bucket_name`: Name for ALB logs bucket
- `cloudfront_logs_bucket_name`: Name for CloudFront logs bucket
- `tags`: Tags for resources

## Outputs
- `frontend_bucket_arn`: ARN of frontend bucket
- `alb_logs_bucket_arn`: ARN of ALB logs bucket
- `cloudfront_logs_bucket_arn`: ARN of CloudFront logs bucket
