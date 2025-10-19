# CloudFront Module
resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = var.comment
  default_root_object = "index.html"
  aliases             = var.aliases
  price_class         = var.price_class
  web_acl_id          = var.web_acl_id
  http_version        = "http2"
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }
  origin {
    domain_name = var.s3_domain_name
    origin_id   = "s3-frontend"
    s3_origin_config {
      origin_access_identity = var.origin_access_identity
    }
  }
  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version       = "TLSv1.2_2021"
  }
  logging_config {
    bucket          = var.logs_bucket_domain_name
    include_cookies = false
    prefix          = var.logs_prefix
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  tags = var.tags
}
