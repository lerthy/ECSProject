# RDS Standby Configuration and Failover Guide

## Overview
The infrastructure now includes a standby RDS instance for enhanced disaster recovery and high availability. This provides database-level redundancy in addition to the existing Multi-AZ deployment.

## Architecture

### Primary RDS Configuration
- **Instance**: `${var.ecs_name}-db`
- **Multi-AZ**: Enabled (for automatic failover within region)
- **Backup Retention**: 7 days
- **Performance Insights**: Enabled
- **Enhanced Monitoring**: 60-second intervals

### Standby RDS Configuration
- **Instance**: `${var.ecs_name}-db-standby`
- **Multi-AZ**: Disabled (Single AZ for cost optimization)
- **Backup Retention**: 3 days (shorter for standby)
- **Performance Insights**: Disabled (cost optimization)
- **Enhanced Monitoring**: Disabled

## Failover Scenarios

### 1. Automatic Regional Failover (Multi-AZ)
**Primary RDS → Multi-AZ Secondary**
- **Trigger**: Primary database failure within same region
- **Action**: Automatic (AWS managed)
- **RTO**: ~1-3 minutes
- **RPO**: Near zero (synchronous replication)
- **DNS**: Endpoint remains same

### 2. Manual Disaster Recovery (Cross-Database)
**Primary RDS → Standby RDS**
- **Trigger**: Regional failure or maintenance
- **Action**: Manual intervention required
- **RTO**: ~5-15 minutes (manual process)
- **RPO**: Depends on backup restore point

## Failover Procedures

### Scenario 1: Switch to Standby Database

#### Step 1: Prepare Standby Database
```bash
# 1. Ensure standby database is running
aws rds describe-db-instances --db-instance-identifier ${var.ecs_name}-db-standby

# 2. Restore latest backup if needed (if standby is behind)
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier ${var.ecs_name}-db-standby-restored \
  --db-snapshot-identifier latest-primary-snapshot
```

#### Step 2: Update ECS Services
```bash
# 1. Scale down primary ECS service
aws ecs update-service \
  --cluster ${var.ecs_name} \
  --service ${var.ecs_name}-api \
  --desired-count 0

# 2. Scale up standby ECS service (already pointing to standby DB)
aws ecs update-service \
  --cluster ${var.ecs_name} \
  --service ${var.ecs_name}-standby-api \
  --desired-count 2
```

#### Step 3: Update Route53 (if configured)
```bash
# Switch DNS to point to standby ALB
aws route53 change-resource-record-sets \
  --hosted-zone-id ${var.route53_zone_id} \
  --change-batch file://failover-changeset.json
```

### Scenario 2: Return to Primary Database

#### Step 1: Verify Primary Database Health
```bash
# Check primary database status
aws rds describe-db-instances --db-instance-identifier ${var.ecs_name}-db

# Test connectivity
psql -h ${primary_endpoint} -U postgres -d ecommerce -c "SELECT 1;"
```

#### Step 2: Sync Data (if needed)
```bash
# If data was written to standby, sync back to primary
pg_dump -h ${standby_endpoint} -U postgres ecommerce > standby_data.sql
psql -h ${primary_endpoint} -U postgres ecommerce < standby_data.sql
```

#### Step 3: Switch Back to Primary
```bash
# 1. Scale down standby ECS service
aws ecs update-service \
  --cluster ${var.ecs_name} \
  --service ${var.ecs_name}-standby-api \
  --desired-count 0

# 2. Scale up primary ECS service
aws ecs update-service \
  --cluster ${var.ecs_name} \
  --service ${var.ecs_name}-api \
  --desired-count 2
```

## Monitoring and Alerts

### Health Check Endpoints
- **Primary**: `https://${primary_alb}/health/detailed`
- **Standby**: `https://${standby_alb}/health/detailed`

### Key Metrics to Monitor
1. **Database Connectivity**
   - Primary RDS connection status
   - Standby RDS connection status

2. **Replication Lag** (if using read replicas)
   - Monitor lag between primary and read replicas

3. **Application Health**
   - ECS task health on both primary and standby
   - Application response times

### CloudWatch Alarms
- RDS CPU utilization
- Database connection count
- Disk space utilization
- Failed connection attempts

## Data Consistency Considerations

### Write Operations
- **Primary Only**: All writes should go to primary database
- **Standby Risk**: If writes occur on standby during failover, manual sync required

### Read Operations
- **Primary**: All reads during normal operation
- **Standby**: Only during failover scenarios

### Backup Strategy
- **Primary**: Full backups every 7 days, transaction logs continuously
- **Standby**: Backup every 3 days for disaster recovery
- **Cross-Region**: Consider cross-region backup for ultimate protection

## Cost Optimization

### Standby Instance Sizing
- Use smaller instance class for standby (can be scaled up during failover)
- Disable enhanced monitoring and performance insights
- Single AZ deployment for standby

### Automation Opportunities
1. **Automated Health Checks**: Script to periodically test standby database
2. **Automated Failover**: Use Lambda functions for faster failover
3. **Automated Sync**: Schedule jobs to keep standby updated

## Testing Procedures

### Monthly Disaster Recovery Test
1. **Scale down primary ECS service**
2. **Scale up standby ECS service**
3. **Verify application functionality**
4. **Test database read/write operations**
5. **Restore to primary configuration**

### Quarterly Full Failover Test
1. **Simulate primary database failure**
2. **Execute complete failover procedure**
3. **Validate data consistency**
4. **Measure RTO and RPO**
5. **Document lessons learned**

## Emergency Contacts

### On-Call Procedures
1. **Primary Database Failure**: Auto-escalate to database team
2. **Standby Database Issues**: Standard alerting
3. **Regional Outage**: Escalate to infrastructure team

### Rollback Plan
- Always maintain ability to rollback to previous state
- Keep backups of configuration changes
- Document all manual interventions

---

## Quick Reference Commands

### Check Database Status
```bash
# Primary
aws rds describe-db-instances --db-instance-identifier ${var.ecs_name}-db

# Standby
aws rds describe-db-instances --db-instance-identifier ${var.ecs_name}-db-standby
```

### Check ECS Service Status
```bash
# Primary
aws ecs describe-services --cluster ${var.ecs_name} --services ${var.ecs_name}-api

# Standby
aws ecs describe-services --cluster ${var.ecs_name} --services ${var.ecs_name}-standby-api
```

### Force Failover Test
```bash
# This is for testing only - DO NOT run in production without planning
aws rds reboot-db-instance --db-instance-identifier ${var.ecs_name}-db --force-failover
```

This standby configuration provides robust disaster recovery capabilities while maintaining cost efficiency through optimized standby resource allocation.