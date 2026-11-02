output "vpc_id" {
  description = "VPC identifier."
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet identifiers."
  value       = module.vpc.private_subnets
}

output "public_subnet_ids" {
  description = "Public subnet identifiers."
  value       = module.vpc.public_subnets
}

output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = try(module.eks.cluster_name, "NONE")
}

output "eks_cluster_endpoint" {
  description = "Private EKS API endpoint."
  value       = try(module.eks.cluster_endpoint, "NONE")
}
