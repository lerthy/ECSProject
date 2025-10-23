# Manual Approval Gates Implementation

## Overview

This document describes the implementation of manual approval gates in the E-commerce CI/CD pipeline to provide better control over deployments and ensure proper review processes.

## Changes Made

### 1. Pipeline Structure Updates

#### Infrastructure Pipeline (Terraform)
- **Source** → **Plan** → **Approval** → **Apply**
- Added manual approval gate after Terraform plan
- Approval message: "Please review the Terraform plan and approve the infrastructure changes"

#### Backend Pipeline (ECS)
- **Source** → **Build** → **Approval** → **Deploy**
- Added manual approval gate after Docker image build
- Approval message: "Please review the application build and approve the deployment to ECS"

#### Frontend Pipeline (S3/CloudFront)
- **Source** → **Build** → **Approval** → **Deploy**
- Added manual approval gate after frontend build
- Approval message: "Please review the frontend build and approve the deployment to S3/CloudFront"

### 2. Buildspec Updates

#### Backend Buildspec (`buildspec-backend.yml`)
- Added conditional deployment logic based on `DEPLOYMENT_ACTION` environment variable
- Build phase: Only builds and pushes images to ECR
- Deploy phase: Updates ECS service (only when `DEPLOYMENT_ACTION=deploy`)

#### Frontend Buildspec (`buildspec-frontend.yml`)
- Created new buildspec for frontend deployment
- Added conditional deployment logic for S3 sync and CloudFront invalidation
- Build phase: Only builds static assets
- Deploy phase: Syncs to S3 and creates CloudFront invalidation

### 3. IAM Permissions

#### CodePipeline Role
- Added `codepipeline:PutApprovalResult` permission
- Added pipeline state management permissions
- Maintains existing S3, CodeBuild, and SNS permissions

### 4. Notification System

#### Lambda Function (`approval_notifier.py`)
- Sends notifications when pipelines reach approval stages
- Integrates with existing SNS topic
- Provides direct links to AWS Console for approval

#### CloudWatch Events
- Triggers on pipeline state changes
- Routes approval notifications to Lambda function

## How It Works

### 1. Pipeline Execution Flow

```
1. Developer pushes code to GitHub
2. CodePipeline triggers automatically
3. Build/Plan stage executes
4. Pipeline pauses at Approval stage
5. Manual approval required in AWS Console
6. Upon approval, deployment stage executes
7. Notification sent upon completion
```

### 2. Approval Process

1. **Pipeline Pauses**: When pipeline reaches approval stage, it pauses and waits
2. **Notification Sent**: Lambda function sends notification to SNS topic
3. **Manual Review**: Team member reviews build artifacts and plan output
4. **Approval Action**: Team member approves or rejects in AWS Console
5. **Deployment Continues**: Upon approval, pipeline continues to deployment stage

### 3. Approval Locations

- **AWS Console**: CodePipeline → Select Pipeline → Review/Approve
- **Email/Slack**: Notifications sent via SNS topic
- **Direct Links**: Lambda function provides direct console links

## Benefits

### 1. Risk Mitigation
- Prevents automatic deployment of potentially broken code
- Allows review of infrastructure changes before application
- Provides opportunity to verify security scans and tests

### 2. Compliance
- Meets audit requirements for manual approval gates
- Provides audit trail of who approved deployments
- Enables compliance with change management policies

### 3. Quality Control
- Ensures proper review of Terraform plans
- Validates Docker image security scans
- Confirms frontend assets are production-ready

## Configuration

### Environment Variables
- `DEPLOYMENT_ACTION`: Controls whether deployment occurs
- `SNS_TOPIC_ARN`: SNS topic for approval notifications
- `ECR_REPO`: ECR repository URL for image references

### Approval Messages
Each pipeline stage includes descriptive approval messages:
- **Infrastructure**: Focus on Terraform plan review
- **Backend**: Focus on Docker image and security scan results
- **Frontend**: Focus on static asset build verification

## Monitoring

### CloudWatch Logs
- Lambda function logs approval notifications
- Pipeline execution logs show approval/rejection decisions
- Build logs include approval gate status

### SNS Notifications
- Approval required notifications
- Deployment success/failure notifications
- Pipeline state change notifications

## Best Practices

### 1. Approval Guidelines
- Review Terraform plan for unexpected changes
- Verify security scan results before approval
- Check build artifacts for completeness
- Ensure tests have passed

### 2. Team Responsibilities
- Designate approval authority for each pipeline
- Set up notification channels (email/Slack)
- Establish approval timeframes
- Document approval procedures

### 3. Emergency Procedures
- Document emergency deployment procedures
- Establish escalation paths
- Consider automated approvals for hotfixes
- Maintain rollback procedures

## Troubleshooting

### Common Issues
1. **Pipeline Stuck**: Check approval status in AWS Console
2. **No Notifications**: Verify SNS topic configuration
3. **Permission Errors**: Check IAM role permissions
4. **Build Failures**: Review build logs before approval

### Resolution Steps
1. Check CloudWatch logs for errors
2. Verify IAM permissions are correct
3. Ensure SNS topic is properly configured
4. Review pipeline execution history

## Future Enhancements

### Potential Improvements
1. **Automated Approvals**: For low-risk changes
2. **Approval Timeouts**: Automatic rejection after timeout
3. **Multi-Stage Approvals**: Different approvers for different stages
4. **Integration Tests**: Automated approval based on test results
5. **Slack Integration**: Direct approval from Slack channels

### Monitoring Enhancements
1. **Approval Metrics**: Track approval times and patterns
2. **Dashboard**: Real-time pipeline status dashboard
3. **Alerts**: Proactive alerts for stuck pipelines
4. **Reporting**: Approval and deployment reports
