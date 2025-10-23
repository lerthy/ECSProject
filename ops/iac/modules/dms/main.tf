resource "aws_dms_replication_instance" "this" {
  replication_instance_id    = var.replication_instance_id
  allocated_storage          = var.allocated_storage
  replication_instance_class = var.replication_instance_class
  engine_version             = var.engine_version
  publicly_accessible        = var.publicly_accessible
  multi_az                   = var.multi_az
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  tags                       = var.tags
}

resource "aws_dms_endpoint" "source" {
  endpoint_id   = var.source_endpoint_id
  endpoint_type = "source"
  engine_name   = var.source_engine_name
  username      = var.source_username
  password      = var.source_password
  server_name   = var.source_server_name
  port          = var.source_port
  database_name = var.source_database_name
  ssl_mode      = var.source_ssl_mode
}

resource "aws_dms_endpoint" "target" {
  endpoint_id   = var.target_endpoint_id
  endpoint_type = "target"
  engine_name   = var.target_engine_name
  username      = var.target_username
  password      = var.target_password
  server_name   = var.target_server_name
  port          = var.target_port
  database_name = var.target_database_name
  ssl_mode      = var.target_ssl_mode
}

resource "aws_dms_replication_task" "this" {
  replication_task_id       = var.replication_task_id
  migration_type            = var.migration_type
  replication_instance_arn  = aws_dms_replication_instance.this.replication_instance_arn
  source_endpoint_arn       = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn       = aws_dms_endpoint.target.endpoint_arn
  table_mappings            = file("${path.module}/table-mappings.json")
  replication_task_settings = file("${path.module}/task-settings.json")
  tags                      = var.tags
}

# CloudWatch Alarms for DMS monitoring
resource "aws_cloudwatch_metric_alarm" "dms_task_failed" {
  alarm_name          = "${var.replication_task_id}-failed"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TaskFailed"
  namespace           = "AWS/DMS"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "DMS task has failed"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    ReplicationTaskIdentifier = aws_dms_replication_task.this.replication_task_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "dms_task_stopped" {
  alarm_name          = "${var.replication_task_id}-stopped"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "TaskStopped"
  namespace           = "AWS/DMS"
  period              = "60"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "DMS task has stopped"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    ReplicationTaskIdentifier = aws_dms_replication_task.this.replication_task_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "dms_cdc_latency" {
  alarm_name          = "${var.replication_task_id}-cdc-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CDCLatencySource"
  namespace           = "AWS/DMS"
  period              = "300"
  statistic           = "Average"
  threshold           = "300" # 5 minutes
  alarm_description   = "DMS CDC latency is too high"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    ReplicationTaskIdentifier = aws_dms_replication_task.this.replication_task_id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "dms_cpu_utilization" {
  alarm_name          = "${var.replication_task_id}-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/DMS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "DMS CPU utilization is too high"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    ReplicationInstanceIdentifier = aws_dms_replication_instance.this.replication_instance_id
  }

  tags = var.tags
}
