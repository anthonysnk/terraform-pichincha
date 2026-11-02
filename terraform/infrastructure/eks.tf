
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name               = "${local.fullname}-eks"
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = module.vpc.public_subnets
  kubernetes_version = "1.37"

  endpoint_private_access                  = true # FROM VPC
  endpoint_public_access                   = true # FROM INTERNET
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

  access_entries = {
    sso_administrator = {
      principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-reserved/sso.amazonaws.com/AWSReservedSSO_AdministratorAccess_cd2b0a06d85119ec"
      type          = "STANDARD"

      policy_associations = {
        cluster_admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  addons = {
    coredns                = {}
    kube-proxy             = {}
    vpc-cni                = { before_compute = true }
    eks-pod-identity-agent = { before_compute = true }
  }

  eks_managed_node_groups = {
    spot = {
      capacity_type  = "SPOT"
      instance_types = ["t3a.medium", "t3.medium"]
      subnet_ids     = module.vpc.public_subnets

      min_size     = 1
      desired_size = 1
      max_size     = 2

      tags = {
        "k8s.io/cluster-autoscaler/enabled"               = "true"
        "k8s.io/cluster-autoscaler/${local.fullname}-eks" = "owned"
      }
    }
  }

  tags = local.shared_infra_tags
}
