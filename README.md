# n8n on AWS
![Architecture](https://img.shields.io/badge/AWS-Architecture-orange)
![Terraform](https://img.shields.io/badge/Terraform-1.0+-blue)
![Helm](https://img.shields.io/badge/Helm-3.x-green)
![n8n](https://img.shields.io/badge/n8n-1.101+-purple)

n8n is a powerful workflow automation platform that allows you to connect different services and tools to automate tasks. This guide demonstrates how to deploy n8n on AWS using managed services like Aurora, EKS, and ElastiCache to create a scalable, production-ready solution.

## Table of Contents
- [n8n Concepts](#n8n-concepts)
- [Architecture](#architecture)
- [AWS Components](#aws-components)
- [k8s Components](#k8s-components)
- [Deployment](#deployment)
- [Cleanup](#cleanup)

## n8n Concepts
### Core Components
The following components are deployed as part of the solution, they all use the official [n8n image](https://hub.docker.com/r/n8nio/n8n), just with different parameters:
- **Main process**: Handles the web UI, editor, and workflow management
- **Webhook process**: Dedicated service for handling incoming webhooks, forms, etc
- **Worker process**: Executes workflow tasks in the background using queue-based processing

### Deployment Mode
This implementation uses n8n [Queue Mode](https://docs.n8n.io/hosting/scaling/queue-mode/) which provides some benefits:
- Separates UI from execution
- Horizontal scaling of workers and webhooks
- Better resource utilization
- Improved fault tolerance

## Architecture
<img src="architecture.png" alt="n8n on AWS Architecture" width="700">

## AWS Components
All these components are created by [Terraform](https://developer.hashicorp.com/terraform) templates located in the ```infra/``` folder.

**Amazon EKS Auto Mode**: Kubernetes cluster to deploy n8n, provides automatic provision of the ALB and of the nodes using Karpenter.

**Amazon ElastiCache**: Redis-compatible in-memory cache for job queuing. Serverless option is available but not supported by n8n, see [this PR](https://github.com/n8n-io/n8n/pull/16592) for updates.

**Amazon Aurora PostgreSQL**: Primary database for n8n, serverless, auto-scaling and fault tolerant.

**AWS Secrets Manager**: Secure storage for database credentials and n8n encryption key.

**AWS IAM**: A role is created for n8n with the minimum privilege required to access Secrets Manager. Other roles are created for the EKS cluster and nodes.

**Amazon CloudFront**: CloudFront is used in front of the ALB only to get the public DNS name with SSL.

## k8s Components
All these components are created by [Helm Chart](https://helm.sh/) located in the ```n8n/``` folder.

### Deployments
Three separate deployments using the official [n8n Docker image](https://hub.docker.com/r/n8nio/n8n):

**Main**: Handles web UI and workflow editor. Single replica on this implementation, but it can be converted to multi-main with Enterprise License.
  
**Webhook**: Dedicated webhook processing, can scale horizontally.
  
**Worker**: Background job processing, can scale horizontally.

### Services & Ingress
Main and Webhook have a service each, these are only used to identify the pods since the ALB will use target-type IP and add the pods IP to the target groups. 

We have a single Ingress with two rules to forward traffic either to the Webhook deployment or to Main. 

### Security & Secrets
Service Account is used to map the n8n IAM role to the pods and give them access to the secrets. 

We use the Secrets Store CSI driver to mount the secrets locally on each pod.

## Deployment
> [!WARNING]
> **💰 This deployment creates billable AWS resources**  
> **Be sure to review and understand the pricing of each service before creating the resources**

### Prerequisites
- AWS account
- AWS CLI configured with appropriate permissions
- kubectl installed
- Helm installed
- Terraform installed

### Quick Start
This will create all the infrastructure needed, including Aurora database, ElastiCache, EKS cluster, etc, and install n8n on it.
Use the provided installation script:
```bash
chmod +x scripts/install.sh
./scripts/install.sh
```

### Step by step deployment
This is the same procedure followed by ```scripts/install.sh``` and has the same requirements. 

### Step 1: Deploy AWS Infrastructure
Terraform templates contain all the base infrastructure needed:
- Networking components (VPC, subnets, NAT Gateway)
- EKS cluster with Auto Mode
- Aurora PostgreSQL Serverless v2 database
- Valkey cache cluster
- IAM roles and policies
- Secrets Manager entries
```bash
# Deploy base infrastructure
cd infra/
terraform init
terraform apply -auto-approve
```

### Step 2: Extract Terraform Outputs
Capture the outputs from Terraform to be used as parameters for the Helm chart.
```bash
# Extract values from Terraform outputs
CLUSTER_NAME=$(terraform output -raw cluster_name)
VALKEY_ENDPOINT=$(terraform output -raw valkey_endpoint)
DB_SECRET_NAME=$(terraform output -raw db_secret_name)
ENCRYPTION_SECRET_NAME=$(terraform output -raw encryption_secret_name)
CLOUDFRONT_SECRET=$(terraform output -raw cloudfront_secret)
SERVICE_ACCOUNT_ROLE_ARN=$(terraform output -raw service_account_role_arn)
```

### Step 3: Configure kubectl Context
```bash
# Configure kubectl context
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region us-east-1
```

### Step 4: Deploy n8n with Helm
Install the n8n Helm Chart, it creates:
- All the k8s components (deployment, ingress, etc)
- ALB
```bash
# Return to root directory and deploy n8n application
cd ..
helm install n8n ./n8n \
  --namespace n8n \
  --create-namespace \
  --set valkey.clusterNodes="$VALKEY_ENDPOINT" \
  --set database.secretName="$DB_SECRET_NAME" \
  --set encryption.secretName="$ENCRYPTION_SECRET_NAME" \
  --set serviceAccount.roleArn="$SERVICE_ACCOUNT_ROLE_ARN" \
  --wait --timeout=10m
```

### Step 5: Get ALB DNS Name
Wait for a few minutes for the ALB to be deployed and grab the DNS name.
```bash
# Wait for ALB to be ready
sleep 120
ALB_DNS=$(kubectl get ingress n8n -n n8n -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "ALB DNS: $ALB_DNS"
```

### Step 6: Deploy CloudFront Distribution
Create the CloudFront distribution with the ALB as the origin.
```bash
# Return to infra directory and deploy CloudFront with ALB as origin
cd infra/
terraform apply -auto-approve \
  -var="alb_dns_name=$ALB_DNS" \
  -var="create_cloudfront=true"

CLOUDFRONT_DOMAIN=$(terraform output -raw cloudfront_domain_name)

```

### Step 7: Update n8n with CloudFront URLs
Update the Helm Chart with the CloudFront domain name and secret, this tells n8n to use that domain name on URLs like forms instead of localhost.
```bash
# Return to root directory for final configuration with CloudFront domain
cd ..
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
echo "🔗 CloudFront URL: https://$CLOUDFRONT_DOMAIN"
```

## Cleanup 
Follow these steps or run the included ```scripts/uninstall.sh``` to remove all the created components.
```bash
# Uninstall steps if required
helm uninstall n8n --namespace n8n
kubectl delete namespace n8n
cd infra/
terraform destroy -auto-approve
```