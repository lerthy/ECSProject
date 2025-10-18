# E-Commerce Platform AWS Infrastructure (Terraform)

This repository contains production-grade, modular Terraform code to deploy an E-Commerce platform on AWS with full observability and CI/CD pipeline integration.

## Directory Structure
- `modules/` — Reusable Terraform modules (vpc, ecs, alb, s3, cloudfront, cloudwatch, sns, xray, athena)
- `environments/` — Environment-specific configurations (dev, staging, prod)
- `backend/` — Remote backend configuration (S3 + DynamoDB)
- `.github/workflows/` — CI/CD pipeline (GitHub Actions)

## Deployment Steps
1. **Configure Remote Backend**
   - Edit `backend/backend.tf` with your S3 bucket, DynamoDB table, and region.
2. **Set Environment Variables**
   - Edit the appropriate `environments/<env>/terraform.tfvars` for your environment.
3. **Initialize Terraform**
   - `cd terraform`
   - `terraform init -backend-config=backend/backend.tf`
4. **Plan and Apply**
   - `terraform plan -var-file=environments/prod/terraform.tfvars`
   - `terraform apply -var-file=environments/prod/terraform.tfvars`
5. **CI/CD Pipeline**
   - The `.github/workflows/ci-cd.yml` workflow will validate, plan, apply, build/push Docker images, update ECS, and deploy frontend to S3 with CloudFront invalidation.

## Outputs
- ALB DNS name
- CloudFront domain name
- S3 bucket ARNs
- ECS cluster/service/task ARNs
- SNS topic ARN
- Athena database/workgroup names

## Best Practices
- All modules are parameterized and reusable.
- IAM roles use least-privilege.
- Observability is enabled for ECS, ALB, CloudFront, and logs are stored in S3/Athena.
- Alarms notify via SNS (email/Slack).

## Replace Placeholders
- Replace all `<REPLACE_WITH_...>` values in tfvars and workflow secrets.

---

For details, see each module's README.
