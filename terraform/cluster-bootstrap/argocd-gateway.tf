resource "kubectl_manifest" "argocd_gateway" {
  count = var.enable_argocd_gateway ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "argocd"
      namespace = "argocd"
    }
    spec = {
      gatewayClassName = "alb"
      listeners = [{
        name     = "http"
        protocol = "HTTP"
        port     = 80
        hostname = var.argocd_hostname
        allowedRoutes = {
          namespaces = { from = "Same" }
        }
      }]
    }
  })

  depends_on = [kubectl_manifest.aws_alb_gateway_class]
}

resource "kubectl_manifest" "argocd_http_route" {
  count = var.enable_argocd_gateway ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "argocd"
      namespace = "argocd"
    }
    spec = {
      parentRefs = [{ name = "argocd" }]
      rules = [{
        backendRefs = [{
          name = "argocd-server"
          port = 80
        }]
      }]
    }
  })

  depends_on = [kubectl_manifest.argocd_gateway]
}
