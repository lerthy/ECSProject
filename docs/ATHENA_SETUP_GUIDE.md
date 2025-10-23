# Athena Setup and Query Execution Guide

This guide provides step-by-step instructions for setting up Amazon Athena to query ALB access logs.

## Step 1: Create the ALB Logs Table

### Option A: Using AWS Console

1. **Open Athena Console**
   - Navigate to AWS Athena in the console
   - Select region: `us-east-1`
   - Choose workgroup: `logs_workgroup_dev`

2. **Create Database (if not exists)**
   ```sql
   CREATE DATABASE IF NOT EXISTS access_logs_dev;
   ```

3. **Create ALB Logs Table**
   - Copy the table creation SQL from `create_alb_table.sql`
   - Paste into Athena query editor
   - Execute the query

### Option B: Using AWS CLI

1. **Create the table using CLI**
   ```bash
   aws athena start-query-execution \
     --query-string "$(cat create_alb_table.sql)" \
     --result-configuration OutputLocation=s3://bardhi-athena-results-dev/ \
     --work-group logs_workgroup_dev \
     --region us-east-1
   ```

## Step 2: Verify Table Creation

1. **List tables in database**
   ```sql
   SHOW TABLES IN access_logs_dev;
   ```

2. **Check table schema**
   ```sql
   DESCRIBE access_logs_dev.alb_logs;
   ```

3. **Test partition projection**
   ```sql
   SHOW PARTITIONS access_logs_dev.alb_logs;
   ```

## Step 3: Run Sample Queries

### Quick Data Check
```sql
SELECT COUNT(*) as total_records
FROM access_logs_dev.alb_logs
WHERE year = '2025' AND month = '10' AND day = '23';
```

### Sample Data Preview
```sql
SELECT *
FROM access_logs_dev.alb_logs
WHERE year = '2025' AND month = '10' AND day = '23'
LIMIT 5;
```

## Step 4: Execute Analysis Queries

Use the queries from `sample_alb_queries.sql` or `ATHENA_QUERIES.md` for detailed analysis:

1. **Traffic Analysis**
2. **Error Investigation**
3. **Performance Monitoring**
4. **Security Analysis**

## Troubleshooting

### Common Issues:

1. **"Table not found" error**
   - Verify database and table names
   - Check workgroup settings
   - Ensure proper permissions

2. **"No data found" error**
   - Verify S3 bucket and path
   - Check partition values (year, month, day)
   - Confirm ALB logs are being generated

3. **"Access denied" error**
   - Check IAM permissions for Athena
   - Verify S3 bucket access permissions
   - Ensure workgroup has proper configuration

4. **"Syntax error" in queries**
   - Verify table and column names
   - Check partition syntax
   - Validate date formats

### Validation Commands:

```bash
# Check if ALB logs exist in S3
aws s3 ls s3://bardhi-ecommerce-alb-logs-dev/alb-logs/AWSLogs/967746377724/elasticloadbalancing/us-east-1/2025/10/23/ --region us-east-1

# List Athena databases
aws athena list-databases --catalog-name AwsDataCatalog --region us-east-1

# Check query execution status
aws athena get-query-execution --query-execution-id <execution-id> --region us-east-1
```

## Performance Optimization

1. **Always use partition filters**
   - Include year, month, day in WHERE clauses
   - Use specific time ranges

2. **Limit data scanned**
   - Use LIMIT for exploratory queries
   - Select only required columns

3. **Use proper data types**
   - Cast timestamps when needed
   - Use appropriate aggregation functions

4. **Save frequently used queries**
   - Create saved queries in Athena
   - Use parameterized queries for different time periods

## Cost Management

1. **Monitor data scanned**
   - Check query execution details
   - Use CloudWatch metrics for Athena

2. **Optimize query patterns**
   - Avoid full table scans
   - Use partition elimination

3. **Use query result caching**
   - Enable result caching in workgroup
   - Reuse results for repeated queries

## Next Steps

1. **Set up automated reports**
   - Schedule queries using Lambda
   - Export results to S3

2. **Create dashboards**
   - Use QuickSight for visualization
   - Connect to Athena as data source

3. **Set up alerts**
   - Create CloudWatch alarms
   - Monitor key metrics automatically