provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

provider "aws" {
  region = var.region
}

# --- 1. Get the existing EKS Cluster ---
data "aws_eks_cluster" "this" {
  name = var.existing_cluster_name
}

# (Optional: Only needed if you stick to token-based auth, but exec is better)
data "aws_eks_cluster_auth" "this" {
  name = var.existing_cluster_name
}

# --- 2. Get the existing VPC ---
data "aws_vpc" "this" {
  id = var.existing_vpc_id
}

# --- 3. Get Private Subnets ---
# CRITICAL: Ensure your existing subnets actually have "private" in their Name tag.
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.existing_vpc_id]
  }

  filter {
    name   = "tag:Name"
    values = ["*private*"] # Adjust this if your subnets are named differently
  }
}

# --- 4. Get the OIDC Provider (Required for IAM Roles) ---
data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# --- UPDATED PROVIDERS ---

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

  # Use exec to ensure the token doesn't expire during long applys
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", var.existing_cluster_name]
  }
}

provider "helm" {
  # FIX: Used '=' here because your error indicated blocks weren't allowed
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", var.existing_cluster_name]
    }
  }
}

# Used by locals.tf to define region availability
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
