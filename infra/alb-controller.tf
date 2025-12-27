# alb-controller.tf

# 1. Get the Policy you created via CLI
data "aws_iam_policy" "alb_controller" {
  name = "AWSLoadBalancerControllerIAMPolicy"
}

# 2. Create the IAM Role for the Service Account
resource "aws_iam_role" "alb_controller" {
  name = "${var.project_name}-alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.this.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
          "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

# 3. Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "alb_controller" {
  role       = aws_iam_role.alb_controller.name
  policy_arn = data.aws_iam_policy.alb_controller.arn
}

# 4. Install the Controller using Helm
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.5.5" 

  # FIXED: Use 'set = [...]' list syntax instead of multiple 'set {}' blocks
  set = [
    {
      name  = "clusterName"
      value = var.existing_cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    },
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.alb_controller.arn
    }
  ]
}
