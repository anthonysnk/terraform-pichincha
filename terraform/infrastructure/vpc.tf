module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "${local.fullname}-vpc"
  cidr = var.vpc_cidr

  azs             = slice(data.aws_availability_zones.available.names, 0, max(length(var.private_subnets), length(var.public_subnets)))
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  enable_nat_gateway      = var.enable_nat_gateway
  one_nat_gateway_per_az  = false
  single_nat_gateway      = true
  enable_vpn_gateway      = false
  map_public_ip_on_launch = true

  tags = merge(local.shared_infra_tags, {
    Terraform   = "true"
    Environment = var.environment
    Type        = "vpc"
  })
}

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "5.21.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags = merge(local.shared_infra_tags, {
        Name = "${local.fullname}-s3-gateway-vpce"
      })
    }
  }

  tags = merge(local.shared_infra_tags, {
    Terraform   = "true"
    Environment = var.environment
    Type        = "vpc-endpoint-s3"
  })
}
