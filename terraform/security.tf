# Security Enhancements: IAM, Encryption, CloudTrail, Config, Secrets

# S3 Encryption at rest
data "aws_kms_key" "s3" {
  key_id = "alias/aws/s3"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = module.s3.frontend_bucket_arn
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = data.aws_kms_key.s3.arn
    }
  }
}

# EBS Encryption (for Fargate, handled by AWS by default)

# ALB HTTPS enforced (already in place via ACM)

# CloudTrail
resource "aws_cloudtrail" "main" {
  name                          = "main-trail"
  s3_bucket_name                = module.s3.alb_logs_bucket_arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  tags                          = var.tags
}

# AWS Config
resource "aws_config_configuration_recorder" "main" {
  name     = "main-recorder"
  role_arn = aws_iam_role.config.arn
}

resource "aws_iam_role" "config" {
  name = "config-recorder-role"
  assume_role_policy = data.aws_iam_policy_document.config_assume_role_policy.json
  tags = var.tags
}

data "aws_iam_policy_document" "config_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
}

resource "aws_config_delivery_channel" "main" {
  name           = "main-channel"
  s3_bucket_name = module.s3.alb_logs_bucket_arn
  depends_on     = [aws_config_configuration_recorder.main]
}

# Secrets Manager Example
resource "aws_secretsmanager_secret" "app" {
  name = "app/secret"
  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id     = aws_secretsmanager_secret.app.id
  secret_string = var.app_secret_string
}
