#!/bin/bash

# Import only the most critical resources that are likely to exist
set -e

echo "=== Importing Critical Resources ==="

cd ops/iac

# Function to safely import
safe_import() {
    local resource="$1"
    local id="$2"
    local description="$3"
    
    echo "Attempting to import $description..."
    if terraform import "$resource" "$id" 2>/dev/null; then
        echo "✓ Successfully imported $description"
        return 0
    else
        echo "⚠ $description not found or already imported"
        return 1
    fi
}

# Only import resources that are very likely to exist
safe_import "aws_iam_role.config" "config-recorder-role" "Config Role"
safe_import "aws_secretsmanager_secret.app" "app/secret" "App Secret"

echo "=== Critical resource import complete ==="
