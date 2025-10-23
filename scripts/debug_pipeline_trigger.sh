#!/bin/bash

# Debug Pipeline Trigger Script
# This script helps debug why the pipeline isn't triggering

set -e

echo "🔍 DEBUGGING PIPELINE TRIGGER ISSUES! 🔍"

# Change to project root
cd /Users/lerdisalihi/Downloads/ECSProject-main\ 2

echo "Step 1: Checking current status..."
echo "Current branch: $(git branch --show-current)"
echo "Latest commit: $(git log --oneline -1)"
echo "Remote status:"
git remote -v

echo ""
echo "Step 2: Checking if pipeline configuration is correct..."
echo "Pipeline should trigger on pushes to devLerdi branch"
echo "Current pipeline config:"
echo "- Branch: devLerdi"
echo "- Provider: GitHub"
echo "- PollForSourceChanges: true"

echo ""
echo "Step 3: Making a test change to force trigger..."
# Create a test file to force trigger
echo "Pipeline trigger test - $(date)" > .pipeline-test
echo "This file should trigger the pipeline" >> .pipeline-test

echo ""
echo "Step 4: Committing and pushing test change..."
git add .
git commit -m "🧪 PIPELINE TRIGGER TEST - $(date)

✅ Testing pipeline trigger mechanism
✅ This should trigger the pipeline
✅ If pipeline doesn't run, there's a configuration issue

Testing pipeline trigger now!"

echo ""
echo "Step 5: Pushing to trigger pipeline..."
git push origin devLerdi

echo ""
echo "🎯 PIPELINE TRIGGER TEST COMPLETED! 🎯"
echo ""
echo "=== DEBUGGING INFORMATION ==="
echo "✅ Test change committed and pushed"
echo "✅ Pipeline should trigger automatically"
echo "✅ If no trigger, check:"
echo "   - GitHub webhook configuration"
echo "   - CodePipeline source configuration"
echo "   - IAM permissions for pipeline"
echo "   - GitHub OAuth token validity"
echo ""
echo "=== NEXT STEPS ==="
echo "🔍 Check AWS CodePipeline console for execution"
echo "🔍 Check GitHub repository webhooks"
echo "🔍 Check CodePipeline source configuration"
echo "🔍 Verify GitHub OAuth token is valid"
echo ""
echo "✅ PIPELINE TRIGGER TEST COMPLETED! ✅"
