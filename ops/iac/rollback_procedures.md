# Rollback Procedures

## Infrastructure Rollback Procedures

### 1. Terraform State Rollback
```bash
# Rollback to previous state
terraform state list
terraform state show <resource_name>
terraform apply -target=<resource_name> -var-file=previous.tfvars
```

### 2. ECS Service Rollback
```bash
# Rollback ECS service to previous task definition
aws ecs update-service \
  --cluster <cluster-name> \
  --service <service-name> \
  --task-definition <previous-task-definition-arn>
```

### 3. Database Rollback
```bash
# Restore from RDS snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier <new-instance-name> \
  --db-snapshot-identifier <snapshot-identifier>
```

### 4. CloudFront Rollback
```bash
# Disable CloudFront distribution
aws cloudfront get-distribution --id <distribution-id>
# Update distribution configuration to disable
```

### 5. ALB Rollback
```bash
# Revert ALB target group configuration
aws elbv2 modify-target-group \
  --target-group-arn <target-group-arn> \
  --health-check-path <previous-path>
```

## Emergency Contacts
- DevOps Team: devops@company.com
- On-call Engineer: +1-xxx-xxx-xxxx
- AWS Support: Enterprise Support Case

## Rollback Checklist
- [ ] Identify the issue and scope
- [ ] Notify stakeholders
- [ ] Document the rollback steps
- [ ] Execute rollback procedures
- [ ] Verify system functionality
- [ ] Update incident documentation
- [ ] Conduct post-mortem
