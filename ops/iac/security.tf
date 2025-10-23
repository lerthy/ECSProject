# Security Enhancements: IAM, Encryption, CloudTrail, Config, Secrets

# S3 Encryption at rest
data "aws_kms_key" "s3" {
  key_id = "alias/aws/s3"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "frontend" {
  bucket = module.s3.frontend_bucket_name
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
  s3_bucket_name                = module.s3.alb_logs_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  enable_logging                = true
  tags                          = var.tags
}

# AWS Config
resource "aws_config_configuration_recorder" "main" {
  name     = "main-recorder"
  role_arn = data.aws_iam_role.config.arn
}

# Use data source for existing IAM role
data "aws_iam_role" "config" {
  name = "config-recorder-role"
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
  role       = data.aws_iam_role.config.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

resource "aws_config_delivery_channel" "main" {
  name           = "main-channel"
  s3_bucket_name = module.s3.alb_logs_bucket_name
  depends_on     = [aws_config_configuration_recorder.main]
}

# Use data source for existing Secrets Manager secret
data "aws_secretsmanager_secret" "app" {
  name = "app/secret"
}

# Only create secret version if app_secret_string is provided
# This prevents "You must provide either SecretString or SecretBinary" error
resource "aws_secretsmanager_secret_version" "app" {
  count         = var.app_secret_string != "" ? 1 : 0
  secret_id     = data.aws_secretsmanager_secret.app.id
  secret_string = var.app_secret_string

  lifecycle {
    # Ignore changes to prevent overwriting secrets during subsequent applies
    ignore_changes = [secret_string]
  }
}
