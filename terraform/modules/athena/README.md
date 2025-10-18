# Athena Module

This module creates an Athena database and workgroup for log analysis.

## Inputs
- `database_name`: Athena database name
- `s3_bucket`: S3 bucket for Athena database
- `workgroup_name`: Athena workgroup name
- `output_location`: S3 output location for query results
- `tags`: Tags for resources

## Outputs
- `athena_database_name`: Athena database name
- `athena_workgroup_name`: Athena workgroup name
