resource "btp_subaccount_entitlement" "cloud_foundry" {
  subaccount_id = var.app_dev_rpa_subaccount.id
  service_name  = "APPLICATION_RUNTIME"
  plan_name     = "MEMORY"
  amount        = 1
}

resource "btp_subaccount_entitlement" "business_application_studio" {
  subaccount_id = var.app_dev_rpa_subaccount.id
  service_name  = "sapappstudiotrial"
  plan_name     = "trial"
}