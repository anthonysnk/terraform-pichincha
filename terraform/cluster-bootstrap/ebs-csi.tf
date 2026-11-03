data "aws_iam_policy_document" "ebs_csi_assume_role" {
  count = var.enable_ebs_csi ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

resource "aws_iam_role" "ebs_csi" {
  count = var.enable_ebs_csi ? 1 : 0

  name               = "${var.cluster_name_prefix}-ebs-csi"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role[0].json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  count = var.enable_ebs_csi ? 1 : 0

  role       = aws_iam_role.ebs_csi[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  count = var.enable_ebs_csi ? 1 : 0

  cluster_name                = data.terraform_remote_state.infrastructure.outputs.eks_cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  resolve_conflicts_on_create = "OVERWRITE"

  depends_on = [aws_eks_pod_identity_association.ebs_csi]
}

resource "aws_eks_pod_identity_association" "ebs_csi" {
  count = var.enable_ebs_csi ? 1 : 0

  cluster_name    = data.terraform_remote_state.infrastructure.outputs.eks_cluster_name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi[0].arn

  depends_on = [aws_iam_role_policy_attachment.ebs_csi]
}

resource "kubectl_manifest" "gp3_storage_class" {
  count = var.enable_ebs_csi ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "storage.k8s.io/v1"
    kind       = "StorageClass"
    metadata = {
      name = "gp3"
    }
    provisioner          = "ebs.csi.aws.com"
    volumeBindingMode    = "WaitForFirstConsumer"
    allowVolumeExpansion = true
    reclaimPolicy        = "Delete"
    parameters = {
      type      = "gp3"
      fsType    = "ext4"
      encrypted = "true"
    }
  })

  depends_on = [
    aws_eks_addon.ebs_csi,
    aws_eks_pod_identity_association.ebs_csi,
  ]
}
