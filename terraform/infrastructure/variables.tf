variable "project_name" {
  description = "Name used to identify the project."
  type        = string
  default     = "dev-pichincha"
}

variable "aws_region" {
  description = "AWS region for the infrastructure."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC."
  type        = string
  default     = "172.20.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks, one per availability zone."
  type        = list(string)
  default     = ["172.20.0.0/24", "172.20.1.0/24", "172.20.2.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks, one per availability zone."
  type        = list(string)
  default     = ["172.20.10.0/24", "172.20.11.0/24", "172.20.12.0/24"]
}

variable "node_group_availability_zone" {
  description = "Availability zone for the worker node group. EBS volumes are bound to a single zone, so the nodes must stay in the zone that holds the persistent volume."
  type        = string
  default     = "us-east-1b"
}

variable "enable_nat_gateway" {
  description = "Whether to create a NAT gateway for private subnet egress."
  type        = bool
  default     = false
}

variable "alb_az_count" {
  description = "Reserved for selecting load balancer availability zones."
  type        = number
  default     = null
}
