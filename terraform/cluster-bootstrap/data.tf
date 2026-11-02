data "terraform_remote_state" "infrastructure" {
  backend = "remote"

  config = {
    organization = var.infrastructure_organization

    workspaces = {
      name = var.infrastructure_workspace
    }
  }
}
