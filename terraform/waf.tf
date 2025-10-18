# AWS WAF for CloudFront and ALB

resource "aws_wafv2_web_acl" "cloudfront" {
  name        = "cloudfront-waf"
  description = "WAF for CloudFront distribution"
  scope       = "CLOUDFRONT"
  default_action {
    allow {}
  }
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "cloudfront-waf"
      sampled_requests_enabled   = true
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfront-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl" "alb" {
  name        = "alb-waf"
  description = "WAF for ALB"
  scope       = "REGIONAL"
  default_action {
    allow {}
  }
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "alb-waf"
      sampled_requests_enabled   = true
    }
  }
  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "alb-waf"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "cloudfront" {
  resource_arn = module.cloudfront.cloudfront_distribution_id
  web_acl_arn  = aws_wafv2_web_acl.cloudfront.arn
}

resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = module.alb.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.alb.arn
}

resource "aws_wafv2_web_acl_association" "alb_standby" {
  resource_arn = module.alb_standby.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.alb.arn
}
