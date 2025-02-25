resource "btp_subaccount_subscription" "business_application_studio" {
  subaccount_id = var.app_dev_rpa_subaccount.id
  app_name      = "sapappstudiotrial"
  plan_name     = "trial"
}
