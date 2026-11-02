output "data" {
  value = aws_ecr_repository.ecr_repository
}

output "lifecycle_policy" {
  value = aws_ecr_lifecycle_policy.count_policy
}
