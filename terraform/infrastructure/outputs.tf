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
  description = "Public EKS API endpoint."
  value       = try(module.eks.cluster_endpoint, "NONE")
}

output "ecr_repository_url" {
  description = "ECR repository URL for the application image."
  value       = module.ecr.data.repository_url
}
