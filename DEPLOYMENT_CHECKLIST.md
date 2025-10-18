# Observability Platform Deployment Checklist

This checklist covers all manually required values, ARNs, IDs, emails, tokens, and secrets for deploying the Terraform + AWS CodePipeline Observability Platform.

---

## 🧱 1. Terraform Backend & Remote State

| Resource/Variable         | Where to Get/Create | Where to Put It | Example Value | Shared/Env-Specific |
|-------------------------- |--------------------|-----------------|--------------|---------------------|
| S3 Bucket Name            | Created by `scripts/bootstrap_backend.sh` | `terraform/backend/backend.tf` (`bucket` param) | `observability-terraform-backend` | Shared |
| DynamoDB Table Name       | Created by `scripts/bootstrap_backend.sh` | `terraform/backend/backend.tf` (`dynamodb_table` param) | `terraform-state-lock` | Shared |
| AWS Region                | AWS Console: Regions | `terraform/backend/backend.tf` (`region` param) | `us-east-1` | Shared |

**Automated resource creation:**
Run the following script to create the backend resources:
```sh
scripts/bootstrap_backend.sh
```
This will create the S3 bucket (`observability-terraform-backend`) and DynamoDB table (`terraform-state-lock`) in the specified region.

---

## 🔐 2. Required AWS ARNs & IDs

| Resource/Variable         | Where to Get/Create | Where to Put It | Example Value | Shared/Env-Specific |
|-------------------------- |--------------------|-----------------|--------------|---------------------|
| ACM Certificate ARN       | AWS Console: ACM → Request certificate | `modules/alb/variables.tf`, `modules/cloudfront/variables.tf` | `arn:aws:acm:us-east-1:123456789012:certificate/abc123` | Env-Specific |
| SNS Topic ARN             | AWS Console: SNS → Create topic | `modules/sns/variables.tf` | `arn:aws:sns:us-east-1:123456789012:alerts-topic` | Shared/Env-Specific |
| IAM Role ARNs (CodePipeline, CodeBuild) | AWS Console: IAM → Create role | `CICD/codepipeline.yaml`, `CICD/buildspec-*.yml` | `arn:aws:iam::123456789012:role/CodePipelineRole` | Shared/Env-Specific |
| ECR Repository ARN        | AWS Console: ECR → Create repository | `modules/ecs/variables.tf` | `arn:aws:ecr:us-east-1:123456789012:repository/backend` | Shared/Env-Specific |
| WAF Web ACL ARN           | AWS Console: WAF → Create Web ACL | `modules/waf/variables.tf` | `arn:aws:wafv2:us-east-1:123456789012:regional/webacl/abc123` | Shared/Env-Specific |
| Route53 Hosted Zone ID    | AWS Console: Route53 → Hosted zones | `modules/route53/variables.tf` | `Z1234567890ABC` | Env-Specific |

**How to find/create:**
- ACM: Request public certificate, validate via DNS/email, copy ARN.
- SNS: Create topic, copy ARN.
- IAM: Create role, attach required policies, copy ARN.
- ECR: Create repository, copy ARN.
- WAF: Create Web ACL, copy ARN.
- Route53: Create hosted zone, copy ID.

---

## 🧰 3. GitHub / Pipeline Integrations

| Resource/Variable         | Where to Get/Create | Where to Put It | Example Value | Shared/Env-Specific |
|-------------------------- |--------------------|-----------------|--------------|---------------------|
| GitHub OAuth Token        | GitHub: Settings → Developer settings → Personal access tokens | `CICD/codepipeline.yaml` (`GitHubSource` block) | `ghp_abc123...` | Shared |
| GitHub Repo Owner/Name    | GitHub: Repo URL | `CICD/codepipeline.yaml` | `lerthy/ECSProject` | Shared |
| Pipeline Artifact Bucket  | AWS Console: S3 → Create bucket | `CICD/codepipeline.yaml` | `ecom-observability-artifacts` | Shared |
| CodePipeline IAM Role ARN | AWS Console: IAM → Create role | `CICD/codepipeline.yaml` | `arn:aws:iam::123456789012:role/CodePipelineRole` | Shared |

**How to create:**
- GitHub token: Generate with repo, workflow scopes.
- Artifact bucket: Create S3 bucket.
- IAM role: Create with CodePipeline trust policy.

---

## 📦 4. Emails and Notifications

| Resource/Variable         | Where to Get/Create | Where to Put It | Example Value | Shared/Env-Specific |
|-------------------------- |--------------------|-----------------|--------------|---------------------|
| Team Email(s)             | Team/Org email | `modules/sns/variables.tf`, `terraform/environments/*/terraform.tfvars` | `alerts@company.com` | Env-Specific |
| Slack Webhook URL         | Slack: App → Incoming Webhooks | `modules/sns/variables.tf` | `https://hooks.slack.com/services/abc123` | Shared/Env-Specific |

**How to confirm/test:**
- Subscribe email to SNS topic, confirm via email link.
- Test: `aws sns publish --topic-arn <ARN> --message "Test Alert"`

---

## 🔧 5. Environment-Specific Variables

| Resource/Variable         | Where to Set | Example Value | Env-Specific |
|-------------------------- |-------------|--------------|--------------|
| Environment Name          | `terraform/environments/dev/terraform.tfvars` | `dev` | Yes |
| ECS CPU/Memory            | `terraform/environments/dev/terraform.tfvars` | `cpu = 512`, `memory = 1024` | Yes |
| ALB/CloudFront Domain     | `terraform/environments/dev/terraform.tfvars` | `alb_domain = "dev.ecom.com"` | Yes |
| Log Bucket Name           | `terraform/environments/dev/terraform.tfvars` | `dev-ecom-logs` | Yes |
| Health Check Path         | `terraform/environments/dev/terraform.tfvars` | `/health` | Yes |
| Route53 Zone ID/Record    | `terraform/environments/dev/terraform.tfvars` | `zone_id = "Z123..."`, `record_name = "dev.ecom.com"` | Yes |

---

## 🌐 6. Services That Need Manual Setup

| Service                   | Can Terraform Create? | How to Create | Required Config |
|-------------------------- |----------------------|--------------|----------------|
| ACM Certificate           | No (for public certs) | AWS Console: ACM | DNS/email validation, domain name |
| S3 Backend Bucket         | No (for state)        | Automated by `scripts/bootstrap_backend.sh` | Versioning enabled |
| DynamoDB Table            | No (for state lock)   | Automated by `scripts/bootstrap_backend.sh` | Partition key: LockID |
| ECS Cluster, Service, Task | Yes (Terraform)      | Automated by Terraform modules | No manual setup |
| ALB, Target Groups, Listeners | Yes (Terraform)      | Automated by Terraform modules | No manual setup |
| S3 Buckets (frontend, logs) | Yes (Terraform)      | Automated by Terraform modules | No manual setup |
| CloudFront Distribution   | Yes (Terraform)      | Automated by Terraform modules | No manual setup |
| CloudWatch Log Groups, Alarms | Yes (Terraform)      | Automated by Terraform modules | No manual setup |
| SNS Topic                 | Yes (Terraform)      | Automated by Terraform modules | No manual setup |
| X-Ray Group, IAM Role     | Yes (Terraform)      | Automated by Terraform modules | No manual setup |
| Athena Database, Workgroup | Yes (Terraform)      | Automated by Terraform modules | No manual setup |
| WAF Web ACLs              | Yes (Terraform)      | Automated by Terraform modules | No manual setup |
| Route53 Health Checks, Records | Yes (Terraform)      | Automated by Terraform modules | No manual setup |
| IAM Roles for ECS, X-Ray, Config | Yes (Terraform)      | Automated by Terraform modules | No manual setup |
| ECR Repository            | Yes/No (if importing) | AWS Console: ECR | Name: backend |
| Artifact Bucket           | Yes/No               | AWS Console: S3 | Name: ecom-observability-artifacts |
| IAM Service Roles         | Yes/No               | AWS Console: IAM | Trust policy, permissions |

---

## 🧩 7. Secrets and Credentials

| Secret/Credential         | Where to Store | How to Create | Example Command |
|-------------------------- |---------------|--------------|----------------|
| GitHub Token              | AWS Secrets Manager / SSM / CodeBuild env var | AWS Console: Secrets Manager | `aws secretsmanager put-secret-value --secret-id github-token --secret-string "ghp_abc123..."` |
| AWS Access Keys           | AWS Secrets Manager / SSM / CodeBuild env var | AWS Console: IAM | `aws secretsmanager put-secret-value --secret-id aws-access-key --secret-string "AKIA..."` |
| DB Credentials (if any)   | AWS Secrets Manager / SSM | AWS Console: Secrets Manager | `aws secretsmanager put-secret-value --secret-id db-creds --secret-string '{"username":"user","password":"pass"}'` |

---

## 📘 8. Validation and Testing

**Verify ARNs/IDs before apply:**
```sh
aws sts get-caller-identity
aws s3 ls s3://ecom-observability-tfstate
aws dynamodb describe-table --table-name ecom-observability-lock
aws acm list-certificates
aws sns list-topics
aws iam list-roles
aws ecr describe-repositories
aws route53 list-hosted-zones
```

---

## ✅ Final Checklist Table

| Resource / Variable Name  | Where to Get It | Where to Put It | Example Value | Shared/Env-Specific |
|-------------------------- |----------------|-----------------|--------------|---------------------|
| S3 Backend Bucket Name    | Automated by `scripts/bootstrap_backend.sh` | backend/backend.tf | observability-terraform-backend | Shared |
| DynamoDB Table Name       | Automated by `scripts/bootstrap_backend.sh` | backend/backend.tf | terraform-state-lock | Shared |
| AWS Region                | AWS Console    | backend/backend.tf | us-east-1 | Shared |
| ACM Certificate ARN       | Requested by `scripts/request_acm_certificate.sh` (manual DNS validation required) | alb/cloudfront variables.tf | arn:aws:acm:us-east-1:... | Env-Specific |
| SNS Topic ARN             | SNS Console    | sns variables.tf | arn:aws:sns:us-east-1:... | Shared/Env-Specific |
| IAM Role ARNs             | IAM Console    | codepipeline.yaml | arn:aws:iam::... | Shared/Env-Specific |
| ECR Repository ARN        | ECR Console    | ecs variables.tf | arn:aws:ecr:us-east-1:... | Shared/Env-Specific |
| WAF Web ACL ARN           | WAF Console    | waf variables.tf | arn:aws:wafv2:us-east-1:... | Shared/Env-Specific |
| Route53 Hosted Zone ID    | Route53 Console | route53 variables.tf | Z1234567890ABC | Env-Specific |
| GitHub OAuth Token        | GitHub Settings | codepipeline.yaml | ghp_abc123... | Shared |
| GitHub Repo Owner/Name    | GitHub         | codepipeline.yaml | lerthy/ECSProject | Shared |
| Pipeline Artifact Bucket  | Automated by `scripts/bootstrap_artifact_bucket.sh` | codepipeline.yaml | ecom-observability-artifacts | Shared |
| Team Email(s)             | Team/Org Email | sns variables.tf | alerts@company.com | Env-Specific |
| Slack Webhook URL         | Slack          | sns variables.tf | https://hooks.slack.com/... | Shared/Env-Specific |
| Environment Name          | N/A            | terraform.tfvars | dev | Env-Specific |
| ECS CPU/Memory            | N/A            | terraform.tfvars | 512/1024 | Env-Specific |
| ALB/CloudFront Domain     | N/A            | terraform.tfvars | dev.ecom.com | Env-Specific |
| Log Bucket Name           | S3 Console     | terraform.tfvars | dev-ecom-logs | Env-Specific |
| Health Check Path         | N/A            | terraform.tfvars | /health | Env-Specific |
| Route53 Zone ID/Record    | Route53 Console | terraform.tfvars | Z123..., dev.ecom.com | Env-Specific |
| Secrets (GitHub, AWS, DB) | Secrets Manager/SSM | N/A | ghp_abc..., AKIA..., {"username":"user"} | Shared/Env-Specific |

---

**Action Steps:**
- Fill in all required values in the specified files.
- Create resources in AWS as needed.
- Store secrets securely.
- Validate with AWS CLI before running `terraform apply`.

---

Anyone can use this checklist to fill in every missing piece and deploy the project successfully from scratch.
