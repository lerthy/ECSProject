-- Step-by-Step Solution for ALB Logs Table Fix
-- Execute these queries one by one in AWS Athena Console

-- STEP 1: Drop existing broken table
DROP TABLE IF EXISTS access_logs_dev.alb_logs;

-- STEP 2: Create working ALB logs table (AWS standard pattern)
CREATE EXTERNAL TABLE access_logs_dev.alb_logs (
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
    request string,
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
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.RegexSerDe'
WITH SERDEPROPERTIES (
'input.regex' = 
'([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*):([0-9]*) ([^ ]*)[:-]([0-9]*) ([-.0-9]*) ([-.0-9]*) ([-.0-9]*) (|[-0-9]*) (-|[-0-9]*) ([-0-9]*) ([-0-9]*) \"([^\"]*)\" \"([^\"]*)\" ([A-Z0-9-_]*) ([A-Za-z0-9.-]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" ([-.0-9]*) ([^ ]*) \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\" \"([^\"]*)\"'
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

-- STEP 3: Test the table works
SELECT 
    type,
    time,
    client_ip,
    elb_status_code,
    request,
    user_agent
FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23'
LIMIT 5;

-- STEP 4: Test count to verify data
SELECT COUNT(*) as total_requests 
FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23';

-- STEP 5: If working, run analysis queries
SELECT 
    client_ip,
    COUNT(*) as request_count,
    elb_status_code
FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23'
GROUP BY client_ip, elb_status_code
ORDER BY request_count DESC 
LIMIT 10;