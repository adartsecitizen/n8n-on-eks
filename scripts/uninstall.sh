#!/bin/bash
set -e

echo "🗑️  N8N Demo Uninstall Script"

# Get script directory and root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Step 1: Uninstall n8n from EKS
echo "⚡ Uninstalling n8n from EKS..."
helm uninstall n8n --namespace n8n

# Step 2: Delete namespace
echo "🧹 Cleaning up namespace..."
kubectl delete namespace n8n

# Step 3: Destroy AWS infrastructure
echo "💥 Destroying AWS infrastructure..."
cd "$ROOT_DIR/infra"
terraform destroy -auto-approve

echo "✅ Uninstall complete!"