resource "helm_release" "secrets_csi_driver" {
  name       = "secrets-store-csi-driver"
  repository = "https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts"
  chart      = "secrets-store-csi-driver"
  namespace  = "kube-system"
  version    = var.secrets_csi_version

  set = [{
    name  = "syncSecret.enabled"
    value = "false"
  }]
}

resource "helm_release" "secrets_csi_provider_aws" {
  name       = "secrets-provider-aws"
  repository = "https://aws.github.io/secrets-store-csi-driver-provider-aws"
  chart      = "secrets-store-csi-driver-provider-aws"
  namespace  = "kube-system"
  version    = "1.0.1"

  depends_on = [helm_release.secrets_csi_driver]
}