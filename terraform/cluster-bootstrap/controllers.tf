resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "3.6.2"
  namespace        = "kube-system"
  create_namespace = false
  wait             = true
  timeout          = 900

  set = [
    {
      name  = "clusterName"
      value = data.terraform_remote_state.infrastructure.outputs.eks_cluster_name
    },
    {
      name  = "region"
      value = var.aws_region
    },
    {
      name  = "vpcId"
      value = data.aws_eks_cluster.target.vpc_config[0].vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = "aws-load-balancer-controller"
    }
  ]

  depends_on = [
    aws_eks_pod_identity_association.aws_load_balancer_controller,
    kubectl_manifest.gateway_api_standard_crds,
    kubectl_manifest.aws_load_balancer_gateway_crds,
  ]
}

resource "helm_release" "metrics_server" {
  name             = "metrics-server"
  repository       = "https://kubernetes-sigs.github.io/metrics-server/"
  chart            = "metrics-server"
  version          = "3.14.0"
  namespace        = "kube-system"
  create_namespace = false
  wait             = true
  timeout          = 600
}
