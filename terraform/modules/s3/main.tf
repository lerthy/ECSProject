# S3 Module
resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_bucket_name
  acl    = "public-read"
  force_destroy = true
  website {
    index_document = "index.html"
    error_document = "error.html"
  }
  tags = var.tags
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = var.alb_logs_bucket_name
  force_destroy = true
  tags = var.tags
}


resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = var.cloudfront_logs_bucket_name
  force_destroy = true
  tags = var.tags
}

