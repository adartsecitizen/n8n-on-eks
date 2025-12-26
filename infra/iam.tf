resource "aws_iam_role" "n8n_role" {
  name = "${var.project_name}_role"
  description = "n8n role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        #Federated = module.eks.oidc_provider_arn
        Federated = data.aws_iam_openid_connect_provider.this.arn # <--- CHANGED
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          #"${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub" = "system:serviceaccount:n8n:n8n-sa"
          "${replace(data.aws_eks_cluster.this.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:n8n:n8n-sa" # <--- CHANGED
        }
      }
    }]
  })
}

resource "aws_iam_policy" "n8n_secrets_policy" {
  name        = "${var.project_name}_db_secrets_access"
  description = "Allows access to n8n secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ],
        Effect   = "Allow",
        Resource = [
          aws_secretsmanager_secret.db_credentials.arn, 
          aws_secretsmanager_secret.n8n_encryption_key.arn
          ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "n8n_secrets_attachment" {
  policy_arn = aws_iam_policy.n8n_secrets_policy.arn
  role       = aws_iam_role.n8n_role.name
}