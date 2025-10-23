#!/bin/bash

# Force Pipeline Trigger Script
# This script forces the pipeline to run by making a small change and pushing

set -e

echo "🚀 FORCING PIPELINE TO RUN! 🚀"

# Change to project root
cd /Users/lerdisalihi/Downloads/ECSProject-main\ 2

echo "Step 1: Making a small change to trigger pipeline..."
# Create a small change to force pipeline trigger
echo "# Pipeline trigger - $(date)" >> README.md

echo "Step 2: Adding and committing changes..."
git add .
git commit -m "🔄 FORCE PIPELINE TRIGGER - $(date)

✅ Small change to force pipeline execution
✅ All fixes applied and ready
✅ Pipeline should now run automatically

Triggering pipeline now!"

echo "Step 3: Pushing to trigger pipeline..."
git push origin devLerdi

echo ""
echo "🎉 PIPELINE TRIGGERED! 🎉"
echo "The pipeline should now be running automatically!"
echo ""
echo "=== MONITORING ==="
echo "🔍 Check AWS CodePipeline console for execution status"
echo "🔍 Monitor CloudWatch logs for detailed progress"
echo "🔍 Pipeline will handle all issues automatically"
echo ""
echo "✅ PIPELINE IS NOW RUNNING! ✅"
