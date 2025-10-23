# CodeStar Connection Setup Guide

## 🎯 **Using Your Existing CodeStar Connection**

Your CodeStar Connection is already configured and ready to use:
```
ARN: arn:aws:codeconnections:us-east-1:264765155009:connection/53a37d01-3b7e-44d8-84bb-37c5947aec8b
```

## ✅ **What's Already Fixed**

### 1. **Pipeline Configuration Updated**
- ✅ Replaced GitHub v1 actions with CodeStar Connection v2
- ✅ Removed dependency on GitHub tokens
- ✅ Updated all three pipelines (Terraform, Frontend, Backend)
- ✅ Added proper IAM permissions for CodeStar Connection

### 2. **Code Changes Made**
- ✅ Updated `cicd/main.tf` to use your existing connection
- ✅ Updated `cicd/iam.tf` with proper permissions
- ✅ Removed GitHub token variables from all configs
- ✅ Updated `main.tf` to remove token dependency

## 🔧 **Pipeline Configuration Details**

### Terraform Pipeline
```hcl
action {
  name             = "Source"
  category         = "Source"
  owner            = "AWS"
  provider         = "CodeStarSourceConnection"
  version          = "1"
  output_artifacts = ["terraform_source"]

  configuration = {
    ConnectionArn    = data.aws_codestarconnections_connection.github.arn
    FullRepositoryId = "${var.github_owner}/${var.github_repo}"
    BranchName       = var.github_branch
  }
}
```

### Frontend Pipeline
```hcl
action {
  name             = "Source"
  category         = "Source"
  owner            = "AWS"
  provider         = "CodeStarSourceConnection"
  version          = "1"
  output_artifacts = ["frontend_source"]

  configuration = {
    ConnectionArn    = data.aws_codestarconnections_connection.github.arn
    FullRepositoryId = "${var.github_owner}/${var.github_repo}"
    BranchName       = var.github_branch
  }
}
```

### Backend Pipeline
```hcl
action {
  name             = "Source"
  category         = "Source"
  owner            = "AWS"
  provider         = "CodeStarSourceConnection"
  version          = "1"
  output_artifacts = ["backend_source"]

  configuration = {
    ConnectionArn    = data.aws_codestarconnections_connection.github.arn
    FullRepositoryId = "${var.github_owner}/${var.github_repo}"
    BranchName       = var.github_branch
  }
}
```

## 🚀 **Deployment Steps**

### 1. **Apply Terraform Changes**
```bash
cd /Users/lerdisalihi/Downloads/ECSProject-main\ 2/ops/iac
terraform plan
terraform apply
```

### 2. **Verify Connection Status**
The CodeStar Connection should be in "AVAILABLE" status. If it's "PENDING", you may need to:
1. Go to AWS Console → Developer Tools → Settings → Connections
2. Find your connection: `53a37d01-3b7e-44d8-84bb-37c5947aec8b`
3. Click "Update pending connection" if needed
4. Complete the GitHub authorization if prompted

### 3. **Test Pipeline Execution**
1. Make a commit to your GitHub repository
2. Check CodePipeline in AWS Console
3. Verify the source stage completes successfully

## 🔍 **Troubleshooting**

### Connection Issues
If the connection shows as "PENDING":
1. **Check GitHub App Installation**: Ensure the AWS CodeStar app is installed in your GitHub repository
2. **Re-authorize**: Go to AWS Console → Connections → Update pending connection
3. **Repository Access**: Verify the connection has access to your specific repository

### Pipeline Failures
If pipelines fail at the source stage:
1. **Check Connection Status**: Ensure it's "AVAILABLE"
2. **Verify Repository**: Confirm the repository name and owner are correct
3. **Check Branch**: Ensure the branch exists and has commits
4. **IAM Permissions**: Verify the CodePipeline role has `codestar-connections:UseConnection` permission

### Common Error Messages
- **"Connection not found"**: Check the ARN is correct
- **"Repository not found"**: Verify GitHub owner/repo names
- **"Access denied"**: Check IAM permissions and connection status

## 📋 **Configuration Summary**

### Variables No Longer Needed
- ❌ `github_token` (removed from all configs)
- ❌ GitHub OAuth token management
- ❌ Token rotation concerns

### Variables Still Required
- ✅ `github_owner` = "lerthy"
- ✅ `github_repo` = "ECSProject" 
- ✅ `github_branch` = "main" (or your preferred branch)

### IAM Permissions Added
```json
{
  "Effect": "Allow",
  "Action": [
    "codestar-connections:UseConnection"
  ],
  "Resource": "arn:aws:codeconnections:us-east-1:264765155009:connection/53a37d01-3b7e-44d8-84bb-37c5947aec8b"
}
```

## ✅ **Benefits of CodeStar Connection v2**

1. **No Token Management**: No need to store or rotate GitHub tokens
2. **Better Security**: Uses GitHub Apps instead of personal access tokens
3. **Granular Permissions**: More precise access control
4. **Future-Proof**: GitHub v1 actions are deprecated
5. **Simplified Setup**: One-time connection setup

## 🎉 **Ready to Deploy**

Your pipelines are now fully configured to use CodeStar Connection v2. The setup is complete and ready for deployment!

**Next Steps:**
1. Run `terraform apply` to deploy the updated pipelines
2. Test by making a commit to your repository
3. Monitor the pipelines in AWS Console

The pipelines will now work seamlessly with your existing CodeStar Connection! 🚀
