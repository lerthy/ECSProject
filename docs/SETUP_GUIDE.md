# E-Commerce Observability Platform: Setup Guide

---

## 🧩 1. Prerequisites

Before you begin, ensure you have the following:

- **AWS Account** with admin access (or permissions to create IAM, S3, DynamoDB, ECS, etc.)
- **AWS CLI** ([Install Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **Terraform** (v1.0+ recommended) ([Install Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))
- **Docker** (for local builds and ECR pushes)
- **Git** (for source control)
- **IAM User/Role** with permissions for:
  - S3, DynamoDB, ECS, ECR, ALB, CloudFront, Route53, WAF, CloudWatch, Athena, X-Ray, SNS, CodePipeline, CodeBuild
- **Configure AWS CLI credentials**:
  ```sh
  aws configure
  ```
  Or set environment variables:
  ```sh
  export AWS_ACCESS_KEY_ID=...
  export AWS_SECRET_ACCESS_KEY=...
  export AWS_DEFAULT_REGION=us-east-1
  ```
- **Terraform Backend Credentials**: Ensure the user/role running Terraform can access the S3 bucket and DynamoDB table for state.
- **CI/CD Credentials**:
  - GitHub OAuth token (for CodePipeline integration)
  - IAM roles for CodePipeline and CodeBuild

---

## ⚙️ 2. Backend Setup (Terraform Remote State)

Terraform uses S3 for remote state and DynamoDB for state locking. Create these resources first:

```sh
aws s3 mb s3://<YOUR_TERRAFORM_BACKEND_BUCKET>

aws dynamodb create-table \
  --table-name <YOUR_DYNAMODB_TABLE> \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

- Replace `<YOUR_TERRAFORM_BACKEND_BUCKET>` and `<YOUR_DYNAMODB_TABLE>` with unique names.
- Update `backend/backend.tf`:
  ```hcl
  bucket         = "<YOUR_TERRAFORM_BACKEND_BUCKET>"
  region         = "<YOUR_REGION>"
  dynamodb_table = "<YOUR_DYNAMODB_TABLE>"
  ```
- Initialize Terraform with the backend:
  ```sh
  cd terraform/environments/dev
  terraform init
  ```

---

## 🚀 3. Terraform Configuration

1. **Navigate to your environment**:
   ```sh
   cd terraform/environments/dev  # or staging/prod
   ```
2. **Initialize Terraform**:
   ```sh
   terraform init
   ```
3. **Format and validate**:
   ```sh
   terraform fmt
   terraform validate
   ```
4. **Review the plan**:
   ```sh
   terraform plan -var-file=terraform.tfvars
   ```
5. **Apply the plan**:
   ```sh
   terraform apply -var-file=terraform.tfvars
   ```

- **Variable files**: Each environment (dev, staging, prod) has its own `terraform.tfvars` for environment-specific values.
- **Key modules**:
  - `vpc`: Networking
  - `ecs`: Fargate cluster/services
  - `alb`: Application Load Balancer
  - `cloudfront`: CDN
  - `waf`: Web Application Firewall
  - `route53_failover`: DNS failover
  - `cloudwatch`, `athena`, `xray`, `sns`, `s3`: Observability and logging

---

## 🧱 4. Filling Missing Values

// No ACM Certificate ARN is required. HTTPS is provided by CloudFront's default certificate. If you need a custom domain, you must add your own ACM certificate and update the CloudFront module accordingly.
- **GitHub OAuth Token & Repo**: In `CICD/codepipeline.yaml`, set:
  ```yaml
  GitHub:
    Owner: <YOUR_GITHUB_USERNAME>
    Repo: <YOUR_REPO_NAME>
    OAuthToken: <YOUR_GITHUB_TOKEN>
  ```
  Store tokens securely (e.g., AWS Secrets Manager).
- **Artifact Bucket & IAM Roles**: Set artifact S3 bucket and IAM roles in `codepipeline.yaml` and `buildspec` files.
- **S3 Log Buckets**: Specify log bucket names and configure lifecycle rules for cost optimization.
- **CodeBuild Environment Variables**: Set ECR repo, image tags, region, etc. in buildspec files or CodeBuild project settings.
- **Secrets**: Never commit secrets. Use AWS Secrets Manager or SSM Parameter Store for sensitive values.

---

## 🛠️ 5. Setting Up the CI/CD Pipeline

1. **Create the pipeline artifact bucket**:
   ```sh
   aws s3 mb s3://<YOUR_PIPELINE_ARTIFACT_BUCKET>
   ```
2. **Deploy CodePipeline via CloudFormation**:
   ```sh
   cd terraform/CICD
   aws cloudformation deploy \
     --template-file codepipeline.yaml \
     --stack-name ecommerce-pipeline \
     --capabilities CAPABILITY_NAMED_IAM
   ```
3. **Verify pipeline stages**:
   - Go to AWS Console → CodePipeline → ecommerce-pipeline
   - Stages: Source → Build → Terraform → Deploy
4. **Buildspec files**:
   - `buildspec-build.yml`: Builds and pushes Docker images, runs tests
   - `buildspec-deploy.yml`: Runs Terraform apply for infrastructure changes
5. **GitHub Integration**:
   - CodePipeline connects to your GitHub repo and triggers on new commits to the main branch

---

## 🌐 6. Deploying the Application

- **Via Pipeline**: Push to your GitHub repo. CodePipeline will build, deploy, and apply infrastructure changes.
- **Manual Terraform**:
  ```sh
  cd terraform/environments/dev
  terraform plan -var-file=terraform.tfvars
  terraform apply -var-file=terraform.tfvars
  ```
- **Outputs**:
  - ALB DNS name
  - CloudFront distribution URL
  - ECS service endpoints
- **Verification**:
  - Access the ALB/CloudFront URLs in your browser
  - Check ECS service health in AWS Console

---

## 🔒 7. Security & WAF Setup

- **WAF Attachment**: WAF is attached to CloudFront and ALB (see `waf.tf`).
- **Managed Rules**: Confirm AWS Managed Rules are enabled in the WAF console.
- **Testing WAF**:
  - Use test patterns (e.g., SQL injection strings) to verify WAF blocks malicious requests.
  - Review WAF logs in CloudWatch or S3.

---

## 🧠 8. Observability

- **CloudWatch**: View metrics and dashboards for ECS, ALB, etc.
- **Logs**:
  - ECS container logs: CloudWatch Logs
  - ALB/CloudFront access logs: S3 buckets
- **Athena**:
  - Query access logs in S3 using Athena (see `docs/ATHENA_QUERIES.md`)
- **X-Ray**: View distributed traces in AWS X-Ray console
- **SNS Alerts**:
  - Subscribe your email or Slack webhook to the SNS topic for alerts
  - Confirm receipt of test notifications

---

## ⚡ 9. Warm Standby and Failover Testing

- **Route53 Failover**: Configured to switch between primary and standby ALBs
- **Simulate Failure**:
  - Stop ECS service or ALB in primary region
  - Route53 should automatically direct traffic to standby
  - Check DNS resolution and application availability

---

## 💰 10. Cost Optimization & Cleanup

- **Lifecycle Policies**: Enable on log buckets to expire old logs
- **Fargate Spot**: Enable in ECS task definitions for cost savings
- **Cleanup**:
  ```sh
  terraform destroy -var-file=terraform.tfvars
  # Or delete CloudFormation stacks and S3 buckets manually
  ```

---

## ✅ Verification Checklist

- [ ] S3 and DynamoDB backend created and configured
- [ ] Terraform initialized and applied for all environments
- [ ] All required variables and secrets filled in (GitHub, IAM, etc.)
- [ ] CodePipeline and CodeBuild deployed and working
- [ ] Application accessible via ALB and CloudFront
- [ ] WAF rules active and tested
- [ ] CloudWatch metrics and logs visible
- [ ] Athena queries return log data
- [ ] X-Ray traces available
- [ ] SNS alerts received
- [ ] Route53 failover tested
- [ ] Lifecycle policies enabled on log buckets
- [ ] Infrastructure can be destroyed cleanly

---

> **Tip:** For AWS Console navigation, use the search bar to quickly find services (e.g., "CloudFormation", "CodePipeline", "WAF").

---

**Congratulations!** Your E-Commerce Observability Platform is now ready for production-grade deployments and monitoring.
