resource "helm_release" "metrics_server" {
  name = "metrics-server"

  repository       = "https://charts.bitnami.com/bitnami"
  chart            = "metrics-server"
  namespace        = "metrics-server"
  version          = "6.2.14"
  create_namespace = true

  set {
    name  = "apiService.create"
    value = "true"
  }
  depends_on = [module.eks]
}
