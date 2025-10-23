# Athena Log Analysis Queries

This document provides SQL queries for analyzing ALB access logs and other infrastructure logs using Amazon Athena.

## Prerequisites

1. **Create ALB Logs Table**: First, create the ALB logs table in Athena:

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS access_logs_dev.alb_logs (
    type string,
    time string,
    elb string,
    client_ip string,
    client_port int,
    target_ip string,
    target_port int,
    request_processing_time double,
    target_processing_time double,
    response_processing_time double,
    elb_status_code int,
    target_status_code string,
    received_bytes bigint,
    sent_bytes bigint,
    request_verb string,
    request_url string,
    request_proto string,
    user_agent string,
    ssl_cipher string,
    ssl_protocol string,
    target_group_arn string,
    trace_id string,
    domain_name string,
    chosen_cert_arn string,
    matched_rule_priority string,
    request_creation_time string,
    actions_executed string,
    redirect_url string,
    lambda_error_reason string,
    target_port_list string,
    target_status_code_list string,
    classification string,
    classification_reason string
)
PARTITIONED BY (
   year string,
   month string,
   day string
)
STORED AS INPUTFORMAT 
  'org.apache.hadoop.mapred.TextInputFormat' 
OUTPUTFORMAT 
  'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
LOCATION 's3://bardhi-ecommerce-alb-logs-dev/alb-logs/AWSLogs/967746377724/elasticloadbalancing/us-east-1/'
TBLPROPERTIES (
  'projection.enabled'='true',
  'projection.year.type'='integer',
  'projection.year.range'='2020,2030',
  'projection.year.digits'='4',
  'projection.month.type'='integer',
  'projection.month.range'='1,12',
  'projection.month.digits'='2',
  'projection.day.type'='integer',
  'projection.day.range'='1,31',
  'projection.day.digits'='2',
  'storage.location.template'='s3://bardhi-ecommerce-alb-logs-dev/alb-logs/AWSLogs/967746377724/elasticloadbalancing/us-east-1/${year}/${month}/${day}/'
);
```

## ALB Access Log Queries

### 1. Recent Requests Overview
```sql
SELECT 
    time,
    client_ip,
    request_verb,
    request_url,
    elb_status_code,
    target_status_code,
    response_processing_time
FROM access_logs_dev.alb_logs
WHERE year = '2025' AND month = '10' AND day = '23'
ORDER BY time DESC
LIMIT 20;
```

### 2. Top Client IPs by Request Count
```sql
SELECT 
    client_ip,
    COUNT(*) as request_count
FROM access_logs_dev.alb_logs
WHERE year = '2025' AND month = '10' AND day = '23'
GROUP BY client_ip
ORDER BY request_count DESC
LIMIT 10;
```

### 3. HTTP Response Codes Distribution
```sql
SELECT 
    elb_status_code,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM access_logs_dev.alb_logs
WHERE year = '2025' AND month = '10' AND day = '23'
GROUP BY elb_status_code
ORDER BY count DESC;
```

### 4. Error Analysis (4xx and 5xx)
```sql
SELECT 
    time,
    client_ip,
    request_verb,
    request_url,
    elb_status_code,
    target_status_code,
    user_agent
FROM access_logs_dev.alb_logs
WHERE year = '2025' AND month = '10' AND day = '23'
  AND (elb_status_code >= 400 OR target_status_code LIKE '4%' OR target_status_code LIKE '5%')
ORDER BY time DESC;
```

### 5. Performance Analysis - Slowest Requests
```sql
SELECT 
    time,
    client_ip,
    request_url,
    response_processing_time,
    target_processing_time,
    request_processing_time,
    elb_status_code
FROM access_logs_dev.alb_logs
WHERE year = '2025' AND month = '10' AND day = '23'
  AND response_processing_time > 1.0
ORDER BY response_processing_time DESC
LIMIT 20;
```

### 6. Traffic Pattern by Hour
```sql
SELECT 
    DATE_TRUNC('hour', CAST(time AS timestamp)) as hour,
    COUNT(*) as requests,
    AVG(response_processing_time) as avg_response_time,
    SUM(CASE WHEN elb_status_code >= 400 THEN 1 ELSE 0 END) as error_count
FROM access_logs_dev.alb_logs
WHERE year = '2025' AND month = '10' AND day = '23'
GROUP BY DATE_TRUNC('hour', CAST(time AS timestamp))
ORDER BY hour;
```

### 7. User Agent Analysis
```sql
SELECT 
    user_agent,
    COUNT(*) as request_count,
    COUNT(DISTINCT client_ip) as unique_ips
FROM access_logs_dev.alb_logs
WHERE year = '2025' AND month = '10' AND day = '23'
GROUP BY user_agent
ORDER BY request_count DESC
LIMIT 10;
```

### 8. Request Size Distribution
```sql
SELECT 
    CASE 
        WHEN received_bytes < 1024 THEN '< 1KB'
        WHEN received_bytes < 1048576 THEN '1KB - 1MB'
        WHEN received_bytes < 10485760 THEN '1MB - 10MB'
        ELSE '> 10MB'
    END as request_size_range,
    COUNT(*) as request_count,
    AVG(response_processing_time) as avg_response_time
FROM access_logs_dev.alb_logs
WHERE year = '2025' AND month = '10' AND day = '23'
GROUP BY 
    CASE 
        WHEN received_bytes < 1024 THEN '< 1KB'
        WHEN received_bytes < 1048576 THEN '1KB - 1MB'
        WHEN received_bytes < 10485760 THEN '1MB - 10MB'
        ELSE '> 10MB'
    END
ORDER BY request_count DESC;
```

## How to Run These Queries

### Using AWS Console:
1. Open the **AWS Athena console**
2. Select the **logs_workgroup_dev** workgroup
3. Ensure the **access_logs_dev** database is selected
4. Paste any query into the query editor
5. Update date partitions (year, month, day) as needed
6. Click **Run Query**
7. View results in the output pane

### Using AWS CLI:
```bash
aws athena start-query-execution \
  --query-string "SELECT COUNT(*) FROM access_logs_dev.alb_logs WHERE year = '2025' AND month = '10' AND day = '23'" \
  --result-configuration OutputLocation=s3://bardhi-athena-results-dev/ \
  --work-group logs_workgroup_dev \
  --region us-east-1
```

## Query Optimization Tips

1. **Always use partition filters** (year, month, day) to limit data scanned
2. **Limit results** with `LIMIT` clause for exploratory queries
3. **Use specific time ranges** instead of scanning entire days when possible
4. **Save frequently used queries** in Athena for reuse
5. **Export results** to S3 for reporting and visualization

## Common Use Cases

- **Security Analysis**: Identify suspicious traffic patterns and attack attempts
- **Performance Monitoring**: Track response times and identify bottlenecks
- **Capacity Planning**: Analyze traffic patterns and peak usage times
- **Error Investigation**: Investigate 4xx/5xx errors and their root causes
- **Cost Optimization**: Identify high-traffic endpoints for optimization