resource "kubectl_manifest" "aws_alb_gateway_class" {
  yaml_body = yamlencode({
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "GatewayClass"
    metadata = {
      name = "alb"
    }
    spec = {
      controllerName = "gateway.k8s.aws/alb"
    }
  })

  depends_on = [helm_release.aws_load_balancer_controller]
}
