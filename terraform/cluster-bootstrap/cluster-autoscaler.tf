data "aws_iam_policy_document" "cluster_autoscaler_assume_role" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

data "aws_iam_policy_document" "cluster_autoscaler_permissions" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name               = "${var.cluster_name_prefix}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.cluster_autoscaler_assume_role[0].json
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name   = "autoscaling-management"
  role   = aws_iam_role.cluster_autoscaler[0].id
  policy = data.aws_iam_policy_document.cluster_autoscaler_permissions[0].json
}

resource "aws_eks_pod_identity_association" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  cluster_name    = data.terraform_remote_state.infrastructure.outputs.eks_cluster_name
  namespace       = "kube-system"
  service_account = "cluster-autoscaler"
  role_arn        = aws_iam_role.cluster_autoscaler[0].arn
}

resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  name             = "cluster-autoscaler"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = var.cluster_autoscaler_chart_version
  namespace        = "kube-system"
  create_namespace = false
  wait             = true
  timeout          = 600

  values = [yamlencode({
    autoDiscovery = {
      clusterName = data.terraform_remote_state.infrastructure.outputs.eks_cluster_name
    }
    awsRegion = var.aws_region
    rbac = {
      serviceAccount = {
        create = true
        name   = "cluster-autoscaler"
      }
    }
  })]

  depends_on = [aws_eks_pod_identity_association.cluster_autoscaler]
}
