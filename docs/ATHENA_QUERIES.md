# Athena Sample Queries

Below are example queries for analyzing CloudFront logs in Athena.

---

## 1. Top 10 IPs by request count
```sql
SELECT client_ip, COUNT(*) AS request_count
FROM cloudfront_logs
GROUP BY client_ip
ORDER BY request_count DESC
LIMIT 10;
```

## 2. 5xx Error Rate
```sql
SELECT (SUM(CASE WHEN status LIKE '5%' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS error_rate
FROM cloudfront_logs;
```

## 3. Cache Hit Ratio
```sql
SELECT SUM(CASE WHEN cache_hit_result = 'Hit' THEN 1 ELSE 0 END) / COUNT(*) AS cache_hit_ratio
FROM cloudfront_logs;
```

---

## How to Run These Queries in Athena

1. Open the AWS Athena console.
2. Ensure your CloudFront logs table is named `cloudfront_logs` (or adjust the query accordingly).
3. Paste any of the above queries into the query editor.
4. Click **Run Query**.
5. View results in the output pane.

> Tip: You can save queries and export results for reporting.
