locals {
  subdomain = "app-dev-rpa"
}

resource "btp_subaccount_environment_instance" "app_dev_rpa" {
  subaccount_id    = var.app_dev_rpa_subaccount.id
  name             = local.subdomain
  environment_type = "cloudfoundry"
  service_name     = "cloudfoundry"
  plan_name        = "trial"

  parameters = jsonencode({
    instance_name = local.subdomain
  })
}

data "btp_subaccount_environment_instance" "cloudfoudry" {
  id            = btp_subaccount_environment_instance.app_dev_rpa.id
  subaccount_id = var.app_dev_rpa_subaccount.id

  depends_on = [btp_subaccount_environment_instance.app_dev_rpa]
}

resource "cloudfoundry_space" "dev" {
  name       = "dev"
  org        = btp_subaccount_environment_instance.app_dev_rpa.platform_id
  allow_ssh  = "false"
  depends_on = [btp_subaccount_environment_instance.app_dev_rpa]
}

resource "cloudfoundry_space_quota" "dev" {
  name                     = "medium"
  allow_paid_service_plans = true
  instance_memory          = 256
  total_memory             = 2560
  total_app_instances      = 5
  total_routes             = 5
  total_services           = 10
  total_service_keys       = 10
  total_app_tasks          = 10
  total_route_ports        = 5
  total_app_log_rate_limit = 1000
  org                      = data.btp_subaccount_environment_instance.cloudfoudry.platform_id
  depends_on               = [cloudfoundry_space.dev]

  spaces = [
    cloudfoundry_space.dev.id
  ]
}

resource "cloudfoundry_space_role" "admin" {
  username = var.subaccount_admin
  type     = "space_developer"
  space    = cloudfoundry_space.dev.id
  origin   = "sap.ids"
}

data "cloudfoundry_space" "dev" {
  name = cloudfoundry_space.dev.name
  org  = btp_subaccount_environment_instance.app_dev_rpa.platform_id
}
