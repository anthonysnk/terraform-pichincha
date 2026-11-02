data "aws_iam_policy_document" "karpenter_controller_assume_role" {
  count = var.enable_karpenter_controller ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

data "aws_iam_policy_document" "karpenter_controller_permissions" {
  count = var.enable_karpenter_controller ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:DeleteLaunchTemplate",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "iam:PassRole",
      "pricing:GetProducts",
      "ssm:GetParameter",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "karpenter_controller" {
  count = var.enable_karpenter_controller ? 1 : 0

  name               = "${var.cluster_name_prefix}-karpenter-controller"
  assume_role_policy = data.aws_iam_policy_document.karpenter_controller_assume_role[0].json
}

resource "aws_iam_role_policy" "karpenter_controller" {
  count = var.enable_karpenter_controller ? 1 : 0

  name   = "karpenter-controller"
  role   = aws_iam_role.karpenter_controller[0].id
  policy = data.aws_iam_policy_document.karpenter_controller_permissions[0].json
}

resource "aws_sqs_queue" "karpenter_interruption" {
  count = var.enable_karpenter_controller ? 1 : 0

  name                      = "${var.cluster_name_prefix}-karpenter-interruption"
  message_retention_seconds = 300
}

resource "aws_eks_pod_identity_association" "karpenter_controller" {
  count = var.enable_karpenter_controller ? 1 : 0

  cluster_name    = data.terraform_remote_state.infrastructure.outputs.eks_cluster_name
  namespace       = "kube-system"
  service_account = "karpenter"
  role_arn        = aws_iam_role.karpenter_controller[0].arn

  depends_on = [aws_iam_role_policy.karpenter_controller]
}

resource "helm_release" "karpenter" {
  count = var.enable_karpenter_controller ? 1 : 0

  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_chart_version
  namespace        = "kube-system"
  create_namespace = false
  wait             = true
  timeout          = 900

  values = [yamlencode({
    settings = {
      clusterName       = data.terraform_remote_state.infrastructure.outputs.eks_cluster_name
      interruptionQueue = aws_sqs_queue.karpenter_interruption[0].name
    }
    serviceAccount = {
      create = true
      name   = "karpenter"
    }
  })]

  depends_on = [aws_eks_pod_identity_association.karpenter_controller]
}

data "aws_iam_policy_document" "karpenter_node_assume_role" {
  count = var.enable_karpenter_provisioning ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "karpenter_node" {
  count = var.enable_karpenter_provisioning ? 1 : 0

  name               = "${var.cluster_name_prefix}-karpenter-node"
  assume_role_policy = data.aws_iam_policy_document.karpenter_node_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "karpenter_node_worker" {
  count = var.enable_karpenter_provisioning ? 1 : 0

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_cni" {
  count = var.enable_karpenter_provisioning ? 1 : 0

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_node_ecr" {
  count = var.enable_karpenter_provisioning ? 1 : 0

  role       = aws_iam_role.karpenter_node[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

resource "aws_iam_instance_profile" "karpenter_node" {
  count = var.enable_karpenter_provisioning ? 1 : 0

  name = "${var.cluster_name_prefix}-karpenter-node"
  role = aws_iam_role.karpenter_node[0].name
}

resource "kubectl_manifest" "karpenter_node_class" {
  count = var.enable_karpenter_provisioning ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "karpenter.k8s.aws/v1"
    kind       = "EC2NodeClass"
    metadata   = { name = "spot" }
    spec = {
      amiSelectorTerms = [{ alias = "al2023@latest" }]
      role             = aws_iam_role.karpenter_node[0].name
      subnetSelectorTerms = [{
        tags = { "kubernetes.io/role/elb" = "1" }
      }]
      securityGroupSelectorTerms = [{
        tags = { "kubernetes.io/cluster/${data.terraform_remote_state.infrastructure.outputs.eks_cluster_name}" = "owned" }
      }]
    }
  })

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  count = var.enable_karpenter_provisioning ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "karpenter.sh/v1"
    kind       = "NodePool"
    metadata   = { name = "spot" }
    spec = {
      template = {
        spec = {
          nodeClassRef = {
            group = "karpenter.k8s.aws"
            kind  = "EC2NodeClass"
            name  = "spot"
          }
          requirements = [
            { key = "karpenter.sh/capacity-type", operator = "In", values = ["spot"] },
            { key = "kubernetes.io/arch", operator = "In", values = ["amd64"] },
            { key = "karpenter.k8s.aws/instance-family", operator = "In", values = ["t3", "t3a"] },
            { key = "karpenter.k8s.aws/instance-size", operator = "In", values = ["medium"] },
          ]
        }
      }
      limits = { cpu = "4" }
      disruption = {
        consolidationPolicy = "WhenEmptyOrUnderutilized"
        consolidateAfter    = "1m"
      }
    }
  })

  depends_on = [kubectl_manifest.karpenter_node_class]
}
