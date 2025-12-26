resource "random_id" "suffix" {
  byte_length = 4
}

resource "random_password" "n8n_encryption_key" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret" "n8n_encryption_key" {
  name        = "${var.project_name}-n8n-encryption-key-${random_id.suffix.hex}"
  description = "N8N encryption key for workflows"

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "n8n_encryption_key" {
  secret_id     = aws_secretsmanager_secret.n8n_encryption_key.id
  secret_string = random_password.n8n_encryption_key.result
}

# Generate random secret for Cloudfront custom header
resource "random_password" "cloudfront_secret" {
  length  = 32
  special = false
}