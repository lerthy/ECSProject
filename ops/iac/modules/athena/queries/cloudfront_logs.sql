-- CloudFront Access Logs Analysis Queries

-- 1. Top 10 most requested files
SELECT 
    uri,
    COUNT(*) as request_count,
    SUM(bytes) as total_bytes
FROM cloudfront_logs 
WHERE date = current_date
GROUP BY uri
ORDER BY request_count DESC
LIMIT 10;

-- 2. Cache hit ratio by hour
SELECT 
    DATE_TRUNC('hour', timestamp) as hour,
    COUNT(*) as total_requests,
    SUM(CASE WHEN x_edge_result_type = 'Hit' THEN 1 ELSE 0 END) as cache_hits,
    ROUND(
        (SUM(CASE WHEN x_edge_result_type = 'Hit' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2
    ) as cache_hit_ratio
FROM cloudfront_logs 
WHERE date = current_date
GROUP BY DATE_TRUNC('hour', timestamp)
ORDER BY hour;

-- 3. Top error responses (4xx, 5xx)
SELECT 
    sc_status,
    COUNT(*) as error_count,
    uri
FROM cloudfront_logs 
WHERE date = current_date
    AND (sc_status LIKE '4%' OR sc_status LIKE '5%')
GROUP BY sc_status, uri
ORDER BY error_count DESC
LIMIT 20;

-- 4. Geographic distribution of requests
SELECT 
    c_ip,
    COUNT(*) as request_count,
    SUM(bytes) as total_bytes
FROM cloudfront_logs 
WHERE date = current_date
GROUP BY c_ip
ORDER BY request_count DESC
LIMIT 20;

-- 5. User agents analysis
SELECT 
    cs_user_agent,
    COUNT(*) as request_count
FROM cloudfront_logs 
WHERE date = current_date
    AND cs_user_agent IS NOT NULL
GROUP BY cs_user_agent
ORDER BY request_count DESC
LIMIT 10;

-- 6. Request methods distribution
SELECT 
    cs_method,
    COUNT(*) as request_count
FROM cloudfront_logs 
WHERE date = current_date
GROUP BY cs_method
ORDER BY request_count DESC;

-- 7. Peak traffic hours
SELECT 
    EXTRACT(hour FROM timestamp) as hour,
    COUNT(*) as request_count,
    AVG(time_taken) as avg_response_time
FROM cloudfront_logs 
WHERE date = current_date
GROUP BY EXTRACT(hour FROM timestamp)
ORDER BY request_count DESC;

-- 8. Bandwidth usage by file type
SELECT 
    CASE 
        WHEN uri LIKE '%.css' THEN 'CSS'
        WHEN uri LIKE '%.js' THEN 'JavaScript'
        WHEN uri LIKE '%.png' OR uri LIKE '%.jpg' OR uri LIKE '%.jpeg' OR uri LIKE '%.gif' THEN 'Images'
        WHEN uri LIKE '%.html' OR uri LIKE '%.htm' THEN 'HTML'
        ELSE 'Other'
    END as file_type,
    COUNT(*) as request_count,
    SUM(bytes) as total_bytes,
    AVG(bytes) as avg_file_size
FROM cloudfront_logs 
WHERE date = current_date
GROUP BY 
    CASE 
        WHEN uri LIKE '%.css' THEN 'CSS'
        WHEN uri LIKE '%.js' THEN 'JavaScript'
        WHEN uri LIKE '%.png' OR uri LIKE '%.jpg' OR uri LIKE '%.jpeg' OR uri LIKE '%.gif' THEN 'Images'
        WHEN uri LIKE '%.html' OR uri LIKE '%.htm' THEN 'HTML'
        ELSE 'Other'
    END
ORDER BY total_bytes DESC;

-- 9. Performance metrics by edge location
SELECT 
    x_edge_location,
    COUNT(*) as request_count,
    AVG(time_taken) as avg_response_time,
    SUM(CASE WHEN x_edge_result_type = 'Hit' THEN 1 ELSE 0 END) as cache_hits,
    ROUND(
        (SUM(CASE WHEN x_edge_result_type = 'Hit' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)), 2
    ) as cache_hit_ratio
FROM cloudfront_logs 
WHERE date = current_date
GROUP BY x_edge_location
ORDER BY request_count DESC;

-- 10. Security analysis - suspicious requests
SELECT 
    c_ip,
    uri,
    sc_status,
    COUNT(*) as request_count
FROM cloudfront_logs 
WHERE date = current_date
    AND (
        uri LIKE '%admin%' 
        OR uri LIKE '%login%' 
        OR uri LIKE '%wp-%' 
        OR uri LIKE '%.php'
        OR uri LIKE '%config%'
    )
GROUP BY c_ip, uri, sc_status
ORDER BY request_count DESC
LIMIT 20;
