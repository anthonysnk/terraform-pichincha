module "ecr" {
  source = "./modules/ecr"

  name                  = "${local.fullname}-app"
  image_tag_mutability  = "MUTABLE"
  scan_on_push          = true
  countNumber_to_expire = 15
  force_delete          = false
}
