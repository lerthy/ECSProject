# Athena Module
resource "aws_athena_database" "logs" {
  name   = var.database_name
  bucket = var.s3_bucket
}

# CloudFront logs table
resource "aws_glue_catalog_table" "cloudfront_logs" {
  name          = "cloudfront_logs"
  database_name = aws_athena_database.logs.name

  storage_descriptor {
    location      = "s3://${var.cloudfront_logs_bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "cloudfront-logs-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = "\t"
        "serialization.format" = "\t"
      }
    }

    columns {
      name = "date"
      type = "string"
    }
    columns {
      name = "time"
      type = "string"
    }
    columns {
      name = "x_edge_location"
      type = "string"
    }
    columns {
      name = "sc_bytes"
      type = "bigint"
    }
    columns {
      name = "c_ip"
      type = "string"
    }
    columns {
      name = "cs_method"
      type = "string"
    }
    columns {
      name = "cs_host"
      type = "string"
    }
    columns {
      name = "cs_uri_stem"
      type = "string"
    }
    columns {
      name = "sc_status"
      type = "string"
    }
    columns {
      name = "cs_referer"
      type = "string"
    }
    columns {
      name = "cs_user_agent"
      type = "string"
    }
    columns {
      name = "cs_uri_query"
      type = "string"
    }
    columns {
      name = "cs_cookie"
      type = "string"
    }
    columns {
      name = "x_edge_result_type"
      type = "string"
    }
    columns {
      name = "x_edge_request_id"
      type = "string"
    }
    columns {
      name = "x_host_header"
      type = "string"
    }
    columns {
      name = "time_taken"
      type = "float"
    }
    columns {
      name = "cs_forwarded_for"
      type = "string"
    }
    columns {
      name = "ssl_protocol"
      type = "string"
    }
    columns {
      name = "ssl_cipher"
      type = "string"
    }
    columns {
      name = "x_edge_response_result_type"
      type = "string"
    }
    columns {
      name = "cs_protocol_version"
      type = "string"
    }
    columns {
      name = "fle_status"
      type = "string"
    }
    columns {
      name = "fle_encrypted_fields"
      type = "string"
    }
    columns {
      name = "c_port"
      type = "int"
    }
    columns {
      name = "time_to_first_byte"
      type = "float"
    }
    columns {
      name = "x_edge_detailed_result_type"
      type = "string"
    }
    columns {
      name = "sc_content_type"
      type = "string"
    }
    columns {
      name = "sc_content_len"
      type = "bigint"
    }
    columns {
      name = "sc_range_start"
      type = "bigint"
    }
    columns {
      name = "sc_range_end"
      type = "bigint"
    }
  }

  partition_keys {
    name = "date"
    type = "string"
  }

  parameters = {
    "projection.enabled"            = "true"
    "projection.date.type"          = "date"
    "projection.date.range"         = "2023/01/01,NOW"
    "projection.date.format"        = "yyyy/MM/dd"
    "projection.date.interval"      = "1"
    "projection.date.interval.unit" = "DAYS"
    "storage.location.template"     = "s3://${var.cloudfront_logs_bucket}/$${date}/"
  }
}

# ALB logs table
resource "aws_glue_catalog_table" "alb_logs" {
  name          = "alb_logs"
  database_name = aws_athena_database.logs.name

  storage_descriptor {
    location      = "s3://${var.s3_bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "alb-logs-serde"
      serialization_library = "org.apache.hadoop.hive.serde2.lazy.LazySimpleSerDe"
      parameters = {
        "field.delim"          = " "
        "serialization.format" = " "
      }
    }

    columns {
      name = "type"
      type = "string"
    }
    columns {
      name = "timestamp"
      type = "string"
    }
    columns {
      name = "elb"
      type = "string"
    }
    columns {
      name = "client_ip"
      type = "string"
    }
    columns {
      name = "client_port"
      type = "int"
    }
    columns {
      name = "target_ip"
      type = "string"
    }
    columns {
      name = "target_port"
      type = "int"
    }
    columns {
      name = "request_processing_time"
      type = "float"
    }
    columns {
      name = "target_processing_time"
      type = "float"
    }
    columns {
      name = "response_processing_time"
      type = "float"
    }
    columns {
      name = "elb_status_code"
      type = "string"
    }
    columns {
      name = "target_status_code"
      type = "string"
    }
    columns {
      name = "received_bytes"
      type = "bigint"
    }
    columns {
      name = "sent_bytes"
      type = "bigint"
    }
    columns {
      name = "request_verb"
      type = "string"
    }
    columns {
      name = "request_url"
      type = "string"
    }
    columns {
      name = "request_protocol"
      type = "string"
    }
    columns {
      name = "user_agent"
      type = "string"
    }
    columns {
      name = "ssl_cipher"
      type = "string"
    }
    columns {
      name = "ssl_protocol"
      type = "string"
    }
    columns {
      name = "target_group_arn"
      type = "string"
    }
    columns {
      name = "trace_id"
      type = "string"
    }
    columns {
      name = "domain_name"
      type = "string"
    }
    columns {
      name = "chosen_cert_arn"
      type = "string"
    }
    columns {
      name = "matched_rule_priority"
      type = "string"
    }
    columns {
      name = "request_creation_time"
      type = "string"
    }
    columns {
      name = "actions_executed"
      type = "string"
    }
    columns {
      name = "redirect_url"
      type = "string"
    }
    columns {
      name = "error_reason"
      type = "string"
    }
    columns {
      name = "target_port_list"
      type = "string"
    }
    columns {
      name = "target_status_code_list"
      type = "string"
    }
    columns {
      name = "classification"
      type = "string"
    }
    columns {
      name = "classification_reason"
      type = "string"
    }
  }

  partition_keys {
    name = "year"
    type = "string"
  }
  partition_keys {
    name = "month"
    type = "string"
  }
  partition_keys {
    name = "day"
    type = "string"
  }

  parameters = {
    "projection.enabled"        = "true"
    "projection.year.type"      = "integer"
    "projection.year.range"     = "2023,2030"
    "projection.year.interval"  = "1"
    "projection.month.type"     = "integer"
    "projection.month.range"    = "1,12"
    "projection.month.interval" = "1"
    "projection.day.type"       = "integer"
    "projection.day.range"      = "1,31"
    "projection.day.interval"   = "1"
    "storage.location.template" = "s3://${var.s3_bucket}/$${year}/$${month}/$${day}/"
  }
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
