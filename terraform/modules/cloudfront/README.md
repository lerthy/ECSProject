# CloudFront Module

This module creates a CloudFront distribution for serving the static frontend from S3, with logging and HTTPS support.

## Inputs
- `comment`: Comment for the distribution
- `aliases`: Alternate domain names (CNAMEs)
- `price_class`: Price class
- `web_acl_id`: Web ACL ID (optional)
- `s3_domain_name`: S3 bucket domain name
- `origin_access_identity`: CloudFront origin access identity
- `acm_certificate_arn`: ACM certificate ARN for HTTPS
- `logs_bucket_domain_name`: S3 bucket domain for logs
- `logs_prefix`: Prefix for logs (default: cloudfront/)
- `tags`: Tags for resources

## Outputs
- `cloudfront_domain_name`: CloudFront domain name
- `cloudfront_distribution_id`: CloudFront distribution ID
