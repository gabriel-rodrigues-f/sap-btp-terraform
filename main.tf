module "directories" {
  source = "./0-directories"

  providers = {
    btp = btp
  }
}

module "subaccounts" {
  source                = "./1-subaccounts"
  env                   = var.env
  depends_on            = [module.directories]
  app_dev_rpa_directory = module.directories.app_dev_rpa_directory
  subaccount_admin      = var.subaccount_admin

  providers = {
    btp = btp
  }
}