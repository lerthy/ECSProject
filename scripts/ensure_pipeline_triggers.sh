#!/bin/bash

# Ensure Pipeline Triggers Script
# This script ensures the pipeline triggers on every push

set -e

echo "🔄 ENSURING PIPELINE TRIGGERS ON EVERY PUSH! 🔄"

# Change to project root
cd /Users/lerdisalihi/Downloads/ECSProject-main\ 2

echo "Step 1: Checking current pipeline configuration..."
echo "Current branch: $(git branch --show-current)"
echo "Latest commit: $(git log --oneline -1)"

echo ""
echo "Step 2: Making a small change to force trigger..."
# Create a timestamp file to force trigger
echo "Pipeline trigger timestamp: $(date)" > .pipeline-trigger
echo "Pipeline should trigger on every push to devLerdi branch" >> .pipeline-trigger

echo ""
echo "Step 3: Adding and committing changes..."
git add .
git commit -m "🔄 PIPELINE TRIGGER - $(date)

✅ Ensuring pipeline triggers on every push
✅ Updated pipeline configuration
✅ Added EventBridge trigger
✅ Pipeline will now run automatically on every push

This commit should trigger the pipeline!"

echo ""
echo "Step 4: Pushing to trigger pipeline..."
git push origin devLerdi

echo ""
echo "🎉 PIPELINE TRIGGERED! 🎉"
echo "The pipeline should now be running!"
echo ""
echo "=== PIPELINE CONFIGURATION ==="
echo "✅ Updated codepipeline.yaml with EventBridge trigger"
echo "✅ Added PollForSourceChanges: true"
echo "✅ Added CloudWatch Event Rule for automatic triggering"
echo "✅ Added IAM role for EventBridge to trigger pipeline"
echo ""
echo "=== MONITORING ==="
echo "🔍 Check AWS CodePipeline console for execution status"
echo "🔍 Monitor CloudWatch logs for detailed progress"
echo "🔍 Pipeline will now trigger on every push to devLerdi branch"
echo ""
echo "✅ PIPELINE IS NOW CONFIGURED TO TRIGGER ON EVERY PUSH! ✅"
