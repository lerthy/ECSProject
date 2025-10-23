-- Working Athena Queries for ALB Logs Analysis
-- Execute these queries in the AWS Athena Console
-- Database: access_logs_dev
-- Workgroup: logs_workgroup_dev

-- 1. Check if table exists and show sample data
SELECT * FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23'
LIMIT 10;

-- 2. Count total requests today (Oct 23, 2025)
SELECT 
    COUNT(*) as total_requests,
    COUNT(DISTINCT client_ip) as unique_clients
FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23';

-- 3. Top Client IPs by Request Count (Oct 23, 2025)
SELECT 
    client_ip,
    COUNT(*) as request_count,
    COUNT(DISTINCT request_url) as unique_urls,
    AVG(CAST(response_processing_time AS DOUBLE)) as avg_response_time_seconds
FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23'
GROUP BY client_ip 
ORDER BY request_count DESC 
LIMIT 20;

-- 4. Error Analysis (4xx and 5xx errors) for Oct 23, 2025
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
  AND (CAST(elb_status_code AS INTEGER) >= 400 
       OR target_status_code LIKE '4%' 
       OR target_status_code LIKE '5%')
ORDER BY time DESC 
LIMIT 50;

-- 5. Response Time Analysis for Oct 23, 2025
SELECT 
    request_url,
    COUNT(*) as request_count,
    AVG(CAST(response_processing_time AS DOUBLE)) as avg_response_time,
    MAX(CAST(response_processing_time AS DOUBLE)) as max_response_time,
    MIN(CAST(response_processing_time AS DOUBLE)) as min_response_time
FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23'
  AND response_processing_time != '-1'
GROUP BY request_url 
HAVING COUNT(*) > 5
ORDER BY avg_response_time DESC 
LIMIT 20;

-- 6. Traffic by Hour for Oct 23, 2025
SELECT 
    SUBSTRING(time, 12, 2) as hour_of_day,
    COUNT(*) as request_count,
    COUNT(DISTINCT client_ip) as unique_clients,
    AVG(CAST(response_processing_time AS DOUBLE)) as avg_response_time
FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23'
GROUP BY SUBSTRING(time, 12, 2) 
ORDER BY hour_of_day;

-- 7. Most Requested URLs for Oct 23, 2025
SELECT 
    request_url,
    COUNT(*) as request_count,
    COUNT(DISTINCT client_ip) as unique_clients,
    AVG(CAST(response_processing_time AS DOUBLE)) as avg_response_time
FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23'
GROUP BY request_url 
ORDER BY request_count DESC 
LIMIT 20;

-- 8. Status Code Distribution for Oct 23, 2025
SELECT 
    elb_status_code,
    COUNT(*) as count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) as percentage
FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23'
GROUP BY elb_status_code 
ORDER BY count DESC;

-- 9. User Agent Analysis for Oct 23, 2025
SELECT 
    CASE 
        WHEN user_agent LIKE '%Chrome%' THEN 'Chrome'
        WHEN user_agent LIKE '%Firefox%' THEN 'Firefox'
        WHEN user_agent LIKE '%Safari%' THEN 'Safari'
        WHEN user_agent LIKE '%curl%' THEN 'curl'
        WHEN user_agent LIKE '%bot%' OR user_agent LIKE '%Bot%' THEN 'Bot'
        ELSE 'Other'
    END as browser_type,
    COUNT(*) as request_count
FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23'
GROUP BY 
    CASE 
        WHEN user_agent LIKE '%Chrome%' THEN 'Chrome'
        WHEN user_agent LIKE '%Firefox%' THEN 'Firefox'
        WHEN user_agent LIKE '%Safari%' THEN 'Safari'
        WHEN user_agent LIKE '%curl%' THEN 'curl'
        WHEN user_agent LIKE '%bot%' OR user_agent LIKE '%Bot%' THEN 'Bot'
        ELSE 'Other'
    END
ORDER BY request_count DESC;

-- 10. Recent Activity (Last 2 hours of data available)
SELECT 
    time,
    client_ip,
    request_verb,
    request_url,
    elb_status_code,
    response_processing_time
FROM access_logs_dev.alb_logs 
WHERE year = '2025' AND month = '10' AND day = '23'
ORDER BY time DESC 
LIMIT 50;