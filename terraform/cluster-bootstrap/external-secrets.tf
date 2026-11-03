data "aws_kms_alias" "ssm" {
  name = "alias/aws/ssm"
}

data "aws_iam_policy_document" "external_secrets_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole", "sts:TagSession"]
  }
}

data "aws_iam_policy_document" "external_secrets_access" {
  statement {
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
      "ssm:GetParameters",
    ]

    resources = [data.terraform_remote_state.infrastructure.outputs.application_database_password_parameter_arn]
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [data.aws_kms_alias.ssm.target_key_arn]
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${var.cluster_name_prefix}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.external_secrets_assume_role.json
}

resource "aws_iam_role_policy" "external_secrets" {
  name   = "${var.cluster_name_prefix}-external-secrets-ssm"
  role   = aws_iam_role.external_secrets.id
  policy = data.aws_iam_policy_document.external_secrets_access.json
}

resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.12.1"
  namespace        = "external-secrets"
  create_namespace = true
  wait             = true
  timeout          = 600

  depends_on = [aws_eks_pod_identity_association.external_secrets]

  set = [
    {
      name  = "installCRDs"
      value = "true"
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "serviceAccount.name"
      value = "external-secrets"
    }
  ]
}

resource "aws_eks_pod_identity_association" "external_secrets" {
  cluster_name    = data.terraform_remote_state.infrastructure.outputs.eks_cluster_name
  namespace       = "external-secrets"
  service_account = "external-secrets"
  role_arn        = aws_iam_role.external_secrets.arn

  depends_on = [
    aws_iam_role_policy.external_secrets,
  ]
}
