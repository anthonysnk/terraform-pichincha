
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "21.29.0"

  name       = "${local.fullname}-eks"
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.public_subnets

  endpoint_private_access                  = true # FROM VPC
  endpoint_public_access                   = true # FROM INTERNET
  authentication_mode                      = "API"
  enable_cluster_creator_admin_permissions = true

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
    }
  }

  tags = local.shared_infra_tags
}
