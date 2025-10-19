# Athena Module
resource "aws_athena_database" "logs" {
  name   = var.database_name
  bucket = var.s3_bucket
}

resource "aws_athena_workgroup" "logs" {
  name = var.workgroup_name
  configuration {
    result_configuration {
      output_location = var.output_location
    }
  }
  state         = "ENABLED"
  force_destroy = true
  tags          = var.tags
}
