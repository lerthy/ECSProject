# CloudFront Module

This module creates a CloudFront distribution for serving the static frontend from S3, with logging and HTTPS using the default CloudFront certificate (no ACM required).

## Inputs
- `comment`: Comment for the distribution
- `aliases`: Alternate domain names (CNAMEs)
- `price_class`: Price class
- `web_acl_id`: Web ACL ID (optional)
- `s3_domain_name`: S3 bucket domain name
- `origin_access_identity`: CloudFront origin access identity
- `logs_bucket_domain_name`: S3 bucket domain for logs
- `logs_prefix`: Prefix for logs (default: cloudfront/)
- `tags`: Tags for resources

**Note:** HTTPS is enabled using the default CloudFront certificate. You do not need to provide an ACM certificate ARN. Custom domains are not supported unless you add your own ACM certificate and update the module accordingly.

## Outputs
- `cloudfront_domain_name`: CloudFront domain name
- `cloudfront_distribution_id`: CloudFront distribution ID
