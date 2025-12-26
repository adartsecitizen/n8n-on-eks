#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 N8N Demo Installation Script"

# Step 1: Deploy infrastructure
echo "📦 Deploying AWS infrastructure..."

cd "$ROOT_DIR/infra"
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo add secrets-provider-aws https://aws.github.io/secrets-store-csi-driver-provider-aws
helm repo update
terraform init -upgrade
terraform apply -auto-approve

# Extract values from Terraform outputs
echo "📋 Extracting Terraform outputs..."
CLUSTER_NAME=$(terraform output -raw cluster_name)
VALKEY_ENDPOINT=$(terraform output -raw valkey_endpoint)
DB_SECRET_NAME=$(terraform output -raw db_secret_name)
ENCRYPTION_SECRET_NAME=$(terraform output -raw encryption_secret_name)
CLOUDFRONT_SECRET=$(terraform output -raw cloudfront_secret)
SERVICE_ACCOUNT_ROLE_ARN=$(terraform output -raw service_account_role_arn)

# Configure kubectl context
echo "🔧 Configuring kubectl context..."
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region us-east-1

# Step 2: Deploy n8n with Helm
echo "⚡ Deploying n8n with Helm..."
cd "$ROOT_DIR"
helm upgrade --install n8n ./n8n \
  --namespace n8n \
  --create-namespace \
  --set valkey.clusterNodes="$VALKEY_ENDPOINT" \
  --set database.secretName="$DB_SECRET_NAME" \
  --set encryption.secretName="$ENCRYPTION_SECRET_NAME" \
  --set serviceAccount.roleArn="$SERVICE_ACCOUNT_ROLE_ARN" \
  --wait --timeout=10m

# Step 3: Get ALB DNS
echo "🌐 Waiting for ALB to be ready..."
sleep 120
ALB_DNS=$(kubectl get ingress n8n -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "ALB DNS: $ALB_DNS"

# Step 4: Deploy CloudFront
echo "☁️  Ready to deploy CloudFront!"
cd "$ROOT_DIR/infra"
terraform apply -auto-approve \
  -var="alb_dns_name=$ALB_DNS" \
  -var="create_cloudfront=true"

CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)

# Step 5: Update n8n with Cloudfront URLs and secret
cd "$ROOT_DIR"
helm upgrade n8n ./n8n \
  --namespace n8n \
  --set valkey.clusterNodes="$VALKEY_ENDPOINT" \
  --set database.secretName="$DB_SECRET_NAME" \
  --set encryption.secretName="$ENCRYPTION_SECRET_NAME" \
  --set cloudfront.customHeaderValue="$CLOUDFRONT_SECRET" \
  --set cloudfront.domainName="$CLOUDFRONT_DOMAIN" \
  --set serviceAccount.roleArn="$SERVICE_ACCOUNT_ROLE_ARN" \
  --wait --timeout=10m

echo "✅ Installation complete!"
echo "🔗 Cloudfront URL: https://$CLOUDFRONT_DOMAIN"