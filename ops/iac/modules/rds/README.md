# RDS Module

This module creates a highly reliable PostgreSQL RDS instance with the following features:

## Features

### High Availability & Reliability
- **Multi-AZ deployment** for automatic failover
- **Automated backups** with configurable retention
- **Encryption at rest** using AWS KMS
- **Deletion protection** to prevent accidental deletion
- **Read replica support** for read scaling
- **Enhanced monitoring** with Performance Insights

### Security
- **Secrets Manager integration** for credential management
- **Security groups** with least-privilege access
- **Private subnet deployment** (no public access)
- **Encryption in transit** and at rest

### Monitoring & Observability
- **CloudWatch alarms** for CPU, connections, and storage
- **Enhanced monitoring** with detailed metrics
- **Performance Insights** for query analysis
- **CloudWatch logs** integration

### Performance & Optimization
- **GP3 storage** with auto-scaling
- **Custom parameter group** with performance tuning
- **Connection pooling ready** configuration

## Usage

```hcl
module "rds" {
  source = "./modules/rds"
  
  name                    = "ecommerce"
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  app_security_group_id   = module.vpc.ecs_security_group_id
  
  # Database configuration
  database_name   = "ecommerce"
  instance_class  = "db.t3.micro"
  
  # Reliability settings
  multi_az                = true
  backup_retention_period = 7
  deletion_protection     = true
  
  # Monitoring
  monitoring_interval             = 60
  performance_insights_enabled    = true
  alarm_actions                  = [module.sns.sns_topic_arn]
  
  tags = var.tags
}
```

## Database Schema

The module creates a PostgreSQL database optimized for an e-commerce application. You can connect to it using the credentials stored in AWS Secrets Manager.

### Environment Variables for Application

Set these environment variables in your ECS task definition:

- `DB_HOST`: `module.rds.rds_endpoint`
- `DB_PORT`: `module.rds.rds_port`
- `DB_NAME`: `module.rds.database_name`
- `DB_SECRETS_ARN`: `module.rds.secrets_manager_secret_arn`

## Cost Optimization

- Uses `db.t3.micro` for development (can be scaled up for production)
- GP3 storage with auto-scaling to prevent over-provisioning
- Configurable backup retention to balance cost and compliance

## Security Best Practices

1. Database is deployed in private subnets only
2. Security groups restrict access to application layer only
3. Credentials stored in AWS Secrets Manager
4. Encryption enabled for data at rest and in transit
5. Enhanced monitoring for security insights

## Monitoring

The module creates CloudWatch alarms for:

- **High CPU utilization** (>80%)
- **High connection count** (>80 connections)
- **Low storage space** (<1GB free)

## Backup & Recovery

- **Automated backups** with 7-day retention (configurable)
- **Point-in-time recovery** available
- **Final snapshot** created before deletion (unless disabled)
- **Multi-AZ** provides automatic failover in case of AZ failure

## Scaling

- **Read replicas** can be enabled for read scaling
- **Storage auto-scaling** prevents storage full issues
- **Instance class** can be modified for vertical scaling

## Parameters

See `variables.tf` for all configurable parameters including:

- Instance sizing and storage
- High availability settings
- Backup and maintenance windows
- Monitoring configuration
- Security settings