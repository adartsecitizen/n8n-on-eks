# Step 1. Update Terraform and grab the required parameters
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$ROOT_DIR/infra"
terraform apply -auto-approve

CLUSTER_NAME=$(terraform output -raw cluster_name)
VALKEY_ENDPOINT=$(terraform output -raw valkey_endpoint)
DB_SECRET_NAME=$(terraform output -raw db_secret_name)
ENCRYPTION_SECRET_NAME=$(terraform output -raw encryption_secret_name)
CLOUDFRONT_SECRET=$(terraform output -raw cloudfront_secret)
SERVICE_ACCOUNT_ROLE_ARN=$(terraform output -raw service_account_role_arn)
ALB_DNS=$(kubectl get ingress n8n -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)

# Step 2. Update n8n deployment on EKS
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