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

module "entitlements" {
  source     = "./2-entitlements"
  depends_on = [module.subaccounts]

  app_dev_rpa_subaccount = module.subaccounts.app_dev_rpa_subaccount
}

module "environments" {
  source                 = "./3-environments"
  depends_on             = [module.entitlements]
  app_dev_rpa_subaccount = module.subaccounts.app_dev_rpa_subaccount
  subaccount_admin       = var.subaccount_admin

  providers = {
    btp          = btp
    cloudfoundry = cloudfoundry
  }
}

module "subscriptions" {
  source                 = "./4-subscriptions"
  depends_on             = [module.environments]
  app_dev_rpa_subaccount = module.subaccounts.app_dev_rpa_subaccount

  providers = {
    btp = btp
  }
}
