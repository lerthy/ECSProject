-- Alternative Simple ALB Table Definition
-- If the RegexSerDe doesn't work, try this simpler approach

-- ALTERNATIVE APPROACH: Drop and recreate with LazySimpleSerDe
DROP TABLE IF EXISTS access_logs_dev.alb_logs_simple;

CREATE EXTERNAL TABLE access_logs_dev.alb_logs_simple (
    log_line string
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

-- Test the simple table first
SELECT log_line 
FROM access_logs_dev.alb_logs_simple 
WHERE year = '2025' AND month = '10' AND day = '23'
LIMIT 5;

-- Extract fields manually using string functions
SELECT 
    split_part(log_line, ' ', 1) as type,
    split_part(log_line, ' ', 2) as time,
    split_part(log_line, ' ', 3) as elb,
    split_part(split_part(log_line, ' ', 4), ':', 1) as client_ip,
    split_part(log_line, ' ', 11) as elb_status_code
FROM access_logs_dev.alb_logs_simple 
WHERE year = '2025' AND month = '10' AND day = '23'
LIMIT 10;