locals {
  argocd_application_directory = "${path.module}/../../kubernetes/argocd/develop"
  argocd_application_files     = fileset(local.argocd_application_directory, "*.yaml")
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "10.11.6"
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  timeout          = 900
}

resource "kubectl_manifest" "argocd_application" {
  for_each = local.argocd_application_files

  yaml_body = file("${local.argocd_application_directory}/${each.value}")

  depends_on = [helm_release.argocd]
}
