/*output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}*/

# Update this to just return the variable or data source
output "cluster_name" {
  value = var.existing_cluster_name
}

output "valkey_endpoint" {
  description = "Valkey cluster endpoint with port"
  value       = "${aws_elasticache_replication_group.valkey.configuration_endpoint_address}:${aws_elasticache_replication_group.valkey.port}"
}

output "db_secret_name" {
  description = "Database credentials secret name"
  value       = aws_secretsmanager_secret.db_credentials.name
}

output "encryption_secret_name" {
  description = "N8N encryption key secret name"
  value       = aws_secretsmanager_secret.n8n_encryption_key.name
}

output "cloudfront_secret" {
  description = "CloudFront custom header secret"
  value       = random_password.cloudfront_secret.result
  sensitive   = true
}

output "service_account_role_arn" {
  description = "Service account IAM role ARN"
  value       = aws_iam_role.n8n_role.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name"
  value       = var.create_cloudfront ? aws_cloudfront_distribution.n8n[0].domain_name : ""
}