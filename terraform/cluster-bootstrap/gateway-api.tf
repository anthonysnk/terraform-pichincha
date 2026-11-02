data "http" "gateway_api_standard_crds" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.3/standard-install.yaml"
}

resource "kubectl_manifest" "gateway_api_standard_crds" {
  yaml_body         = data.http.gateway_api_standard_crds.response_body
  server_side_apply = true
}

data "http" "aws_load_balancer_gateway_crds" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.6.2/config/crd/gateway/gateway-crds.yaml"
}

resource "kubectl_manifest" "aws_load_balancer_gateway_crds" {
  yaml_body         = data.http.aws_load_balancer_gateway_crds.response_body
  server_side_apply = true
}
