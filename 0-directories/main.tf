locals {
  default_labels = {
    created_at = [timestamp()]
    owner      = ["sre-team"]
    project    = ["terraform"]
  }
}

resource "btp_directory" "app_dev_rpa" {
  name        = "APP_DEV_RPA"
  description = "Application, Development and Automation directory"
  labels      = merge(local.default_labels, { team = ["app_dev_rpa_team"] })
}
