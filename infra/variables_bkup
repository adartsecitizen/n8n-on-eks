variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "n8n-demo"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.221.160.0/20"
}

variable "eks_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.32"
}

variable "db_engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "16.6"
}

variable "db_min_capacity" {
  description = "Aurora Serverless v2 minimum capacity"
  type        = number
  default     = 0.5
}

variable "db_max_capacity" {
  description = "Aurora Serverless v2 maximum capacity"
  type        = number
  default     = 2.0
}

variable "valkey_version" {
  description = "Valkey engine version"
  type        = string
  default     = "7.2"
}

variable "valkey_node_type" {
  description = "Instance type for Valkey"
  type        = string
  default     = "cache.t4g.small"
}

variable "secrets_csi_version" {
  description = "Version of secrets-store-csi-driver Helm chart"
  type        = string
  default     = "1.3.4"
}

variable "create_cloudfront" {
  description = "Create CloudFront distribution flag"
  type        = bool
  default     = false
}

variable "alb_dns_name" {
  description = "DNS name of ALB"
  type        = string
  default     = ""
}