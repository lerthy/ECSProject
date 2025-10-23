#!/bin/bash

# Script to manually trigger the CodePipeline
echo "=== Triggering CodePipeline ==="

# Get the pipeline name
PIPELINE_NAME="ecommerce-cicd-pipeline"

echo "Starting pipeline: $PIPELINE_NAME"

# Start the pipeline
aws codepipeline start-pipeline-execution --name "$PIPELINE_NAME"

if [ $? -eq 0 ]; then
    echo "✓ Pipeline started successfully"
    echo "You can monitor the pipeline in the AWS Console:"
    echo "https://console.aws.amazon.com/codesuite/codepipeline/pipelines/$PIPELINE_NAME/view"
else
    echo "✗ Failed to start pipeline"
    echo "Make sure the pipeline exists and you have the correct permissions"
fi
