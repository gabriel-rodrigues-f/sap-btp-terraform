data "cloudfoundry_service" "application_logs" {
  name = "application-logs"
}

resource "cloudfoundry_service_instance" "dev-autoscaler" {
  name         = "application-logs"
  type         = "managed"
  tags         = ["application", "logs"]
  space        = var.app_dev_rpa_dev_space.id
  service_plan = data.cloudfoundry_service.application_logs.service_plans["lite"]
  timeouts = {
    create = "10m"
  }
}