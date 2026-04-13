module "naming" {
  source      = "../../modules/naming"
  project     = var.project
  group       = var.group
  environment = var.environment
  prefix      = var.prefix
}