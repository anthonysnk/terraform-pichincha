data "http" "gateway_api_standard_crds" {
  url = "https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.3/standard-install.yaml"
}

data "kubectl_file_documents" "gateway_api_standard_crds" {
  content = data.http.gateway_api_standard_crds.response_body
}

resource "kubectl_manifest" "gateway_api_standard_crds" {
  for_each = data.kubectl_file_documents.gateway_api_standard_crds.manifests

  yaml_body         = each.value
  server_side_apply = true
}

moved {
  from = kubectl_manifest.gateway_api_standard_crds
  to   = kubectl_manifest.gateway_api_standard_crds["/apis/apiextensions.k8s.io/v1/customresourcedefinitions/backendtlspolicies.gateway.networking.k8s.io"]
}

data "http" "aws_load_balancer_gateway_crds" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v3.6.2/config/crd/gateway/gateway-crds.yaml"
}

resource "kubectl_manifest" "aws_load_balancer_gateway_crds" {
  yaml_body         = data.http.aws_load_balancer_gateway_crds.response_body
  server_side_apply = true
}
