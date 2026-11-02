locals {
  policy = var.life_cycle_policy != null ? var.life_cycle_policy : <<EOF
    {
        "rules": [
            {
                "rulePriority": 1,
                "description": "Keep last ${var.countNumber_to_expire} images",
                "selection": {
                    "tagStatus": "any",
                    "countType": "imageCountMoreThan",
                    "countNumber": ${var.countNumber_to_expire}
                },
                "action": {
                    "type": "expire"
                }
            }
        ]
    }
    EOF
}
