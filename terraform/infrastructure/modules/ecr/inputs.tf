variable "name" {}
variable "image_tag_mutability" { default = "MUTABLE" }
variable "scan_on_push" { default = false }
variable "countNumber_to_expire" { default = 15 }
variable "life_cycle_policy" { default = null }
variable "force_delete" { default = false }
