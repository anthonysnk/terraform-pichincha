resource "random_password" "application_database" {
  length  = 32
  special = true

  keepers = {
    environment = local.fullname
  }
}

resource "aws_ssm_parameter" "application_database_password" {
  name        = "/${var.project_name}/${var.environment}/application/database-password"
  description = "Database password consumed by the application through External Secrets."
  type        = "SecureString"
  value       = random_password.application_database.result
  tier        = "Standard"

  tags = {
    Name = "${local.fullname}-application-database-password"
  }
}
