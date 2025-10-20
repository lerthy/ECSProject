# S3 Module
resource "aws_s3_bucket" "frontend" {
  bucket        = var.frontend_bucket_name
  force_destroy = true
  tags = var.tags
}

resource "aws_s3_bucket_acl" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  acl    = "public-read"
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket" "alb_logs" {
  bucket        = var.alb_logs_bucket_name
  force_destroy = true
  tags          = var.tags
}


resource "aws_s3_bucket" "cloudfront_logs" {
  bucket        = var.cloudfront_logs_bucket_name
  force_destroy = true
  tags          = var.tags
}

