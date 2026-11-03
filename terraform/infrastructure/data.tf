data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_subnet" "node_group" {
  vpc_id            = module.vpc.vpc_id
  availability_zone = var.node_group_availability_zone

  filter {
    name   = "tag:kubernetes.io/role/elb"
    values = ["1"]
  }
}
