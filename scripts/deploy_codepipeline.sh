#!/bin/bash
# Deploy the CodePipeline CloudFormation stack for the e-commerce platform

set -e

STACK_NAME="my-ecommerce-cicd-pipeline"
TEMPLATE_FILE="$(dirname "$0")/../ops/iac/cicd/codepipeline.yaml"

# Required parameters (edit these or export as env vars before running)
: "${PIPELINE_ROLE_ARN:?Set PIPELINE_ROLE_ARN}"
: "${ARTIFACT_BUCKET:?Set ARTIFACT_BUCKET}"
: "${SNS_TOPIC_ARN:?Set SNS_TOPIC_ARN}"
: "${GITHUB_OWNER:?Set GITHUB_OWNER}"
: "${GITHUB_REPO:?Set GITHUB_REPO}"
: "${GITHUB_TOKEN:?Set GITHUB_TOKEN}"

aws cloudformation deploy \
  --template-file "$TEMPLATE_FILE" \
  --stack-name "$STACK_NAME" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
    PipelineRoleArn="$PIPELINE_ROLE_ARN" \
    ArtifactBucket="$ARTIFACT_BUCKET" \
    SnsTopicArn="$SNS_TOPIC_ARN" \
    GitHubOwner="$GITHUB_OWNER" \
    GitHubRepo="$GITHUB_REPO" \
    GitHubToken="$GITHUB_TOKEN"

echo "CodePipeline stack deployment initiated."
