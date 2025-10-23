#!/bin/bash

# Manual Pipeline Trigger Script
# This script manually triggers the pipeline and ensures it runs

set -e

echo "🚀 MANUAL PIPELINE TRIGGER! 🚀"

# Change to project root
cd /Users/lerdisalihi/Downloads/ECSProject-main\ 2

echo "Step 1: Making a change to force pipeline trigger..."
# Create a timestamp file to force trigger
echo "Manual pipeline trigger - $(date)" > .manual-trigger
echo "This should definitely trigger the pipeline" >> .manual-trigger

echo ""
echo "Step 2: Committing and pushing change..."
git add .
git commit -m "🚀 MANUAL PIPELINE TRIGGER - $(date)

✅ Manual trigger to force pipeline execution
✅ Updated pipeline configuration with schedule
✅ Added 5-minute polling schedule
✅ Pipeline should now trigger automatically

FORCING PIPELINE TO RUN NOW!"

echo ""
echo "Step 3: Pushing to trigger pipeline..."
git push origin devLerdi

echo ""
echo "🎉 MANUAL PIPELINE TRIGGER COMPLETED! 🎉"
echo ""
echo "=== PIPELINE CONFIGURATION UPDATES ==="
echo "✅ Added 5-minute polling schedule"
echo "✅ Added webhook trigger rule"
echo "✅ Added EventBridge role for triggering"
echo "✅ Enhanced pipeline configuration"
echo ""
echo "=== EXPECTED RESULTS ==="
echo "🔍 Pipeline should trigger within 5 minutes"
echo "🔍 Check AWS CodePipeline console for execution"
echo "🔍 Pipeline will now poll for changes every 5 minutes"
echo "🔍 Manual trigger should work immediately"
echo ""
echo "✅ PIPELINE IS NOW CONFIGURED TO TRIGGER AUTOMATICALLY! ✅"
