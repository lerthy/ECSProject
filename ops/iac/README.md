# E-Commerce Platform AWS Infrastructure (Terraform)

This repository contains production-grade, modular Terraform code to deploy an E-Commerce platform on AWS with full observability and CI/CD pipeline integration.

## Directory Structure

### Core Infrastructure Files
- `main.tf` — Main Terraform configuration file
- `variables.tf` — Variable definitions
- `outputs.tf` — Output definitions
- `backend.tf` — Remote state backend configuration

### AWS Well-Architected Framework Implementation
- `cost_optimization.tf` — Cost optimization pillar implementation
- `operational_excellence.tf` — Operational excellence pillar implementation
- `performance_efficiency.tf` — Performance efficiency pillar implementation
- `security.tf` — Security pillar implementation
- `route53_failover.tf` — Route53 health checks and failover configuration
- `waf.tf` — Web Application Firewall configuration

### Reusable Modules
- `modules/` — Reusable Terraform modules
  - `alb/` — Application Load Balancer module
  - `athena/` — Amazon Athena module for analytics
  - `cicd/` — CI/CD pipeline module (AWS CodePipeline, CodeBuild)
  - `cloudfront/` — CloudFront CDN module
  - `cloudwatch/` — CloudWatch monitoring module
  - `ecr/` — Elastic Container Registry module
  - `ecs/` — Elastic Container Service module
  - `monitoring_alarms/` — CloudWatch alarms module
  - `route53/` — Route53 DNS module
  - `s3/` — S3 storage module
  - `sns/` — Simple Notification Service module
  - `vpc/` — Virtual Private Cloud module
  - `xray/` — AWS X-Ray tracing module

### Configuration
- `../config/dev/` — Development environment configuration
  - `terraform.tfvars` — Development environment variables
  - `README.md` — Development environment setup guide

### Build Configuration
- Build specifications are located in `../cicd/` directory

## Deployment Steps

1. **Configure Remote Backend**
   - Edit `backend.tf` with your S3 bucket, DynamoDB table, and region.

2. **Set Environment Variables**
   - Edit `../config/dev/terraform.tfvars` for development environment configuration.
   - Add additional environment folders under `../config/` as needed (staging, prod).

3. **Initialize Terraform**
   - `terraform init`

4. **Plan and Apply**
   - `terraform plan -var-file="../config/dev/terraform.tfvars" -out=dev.tfplan`
   - `terraform apply`

5. **CI/CD Pipeline**
   - The `modules/cicd/` contains CI/CD pipeline infrastructure
   - The CI/CD buildspec files are located in `../cicd/`
   - See `../cicd/buildspec-terraform.yml`, `../cicd/buildspec-frontend.yml` and `../cicd/buildspec-backend.yml` for build specifications

## Outputs
- ALB DNS name and ARN
- CloudFront distribution domain name and ARN
- S3 bucket names and ARNs
- ECS cluster, service, and task definition ARNs
- VPC and subnet IDs
- ECR repository URLs
- SNS topic ARNs for notifications
- Athena database and workgroup names
- Route53 hosted zone ID
- CloudWatch log group names
- X-Ray service map and trace analytics

## Best Practices

### AWS Well-Architected Framework
This infrastructure implements all five pillars of the AWS Well-Architected Framework:
- **Operational Excellence**: Automated deployments, monitoring, and operational procedures
- **Security**: IAM roles with least-privilege, WAF protection, VPC security groups
- **Reliability**: Multi-AZ deployments, health checks, auto-scaling, failover mechanisms
- **Performance Efficiency**: Auto-scaling, CloudFront CDN, optimized instance types
- **Cost Optimization**: Resource tagging, right-sizing, Reserved Instances recommendations

### Infrastructure Design
- All modules are parameterized and reusable across environments
- IAM roles follow least-privilege principle
- Comprehensive observability with CloudWatch, X-Ray, and centralized logging
- All logs are stored in S3 and queryable via Athena
- SNS notifications for critical alarms and events
- WAF protection for web applications
- Route53 health checks and DNS failover

## Replace Placeholders
- Replace all `<REPLACE_WITH_...>` values in `../config/dev/terraform.tfvars`
- Update AWS account-specific values (region, account ID, etc.)
- Configure notification endpoints (email addresses, Slack webhooks)
- Set appropriate environment-specific values for resource sizing and scaling

## Related Documentation
- See `../config/dev/README.md` for environment-specific setup
- See each module's individual README.md for detailed configuration options
- See `../packages/README.md` for application deployment information
- See project docs/ folder for architecture and deployment guides

**Note:** HTTPS is provided by CloudFront using the default AWS certificate. No ACM certificate is required for this deployment. ALB is HTTP-only by default.
