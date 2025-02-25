locals {
  region = "us10"

  default_labels = {
    created_at = [timestamp()]
    owner      = ["sre-team"]
    project    = ["terraform"]
  }

  teams = {
    app_dev_rpa = "app-dev-rpa-team"
  }
}

resource "btp_subaccount" "app_dev_rpa" {
  parent_id = var.app_dev_rpa_directory.id
  name      = "${upper(var.env)}_APP_DEV_RPA"
  subdomain = "app-dev-rpa"
  region    = local.region
  labels    = merge(local.default_labels, { team = [local.teams.app_dev_rpa] })
}

resource "btp_subaccount_role_collection_assignment" "this" {
  subaccount_id        = btp_subaccount.app_dev_rpa.id
  role_collection_name = "Subaccount Administrator"
  user_name            = var.subaccount_admin

  depends_on = [btp_subaccount.app_dev_rpa]
}