# Platform folder + EUR cost overview (ADR 0002). App repos must not recreate these.

resource "grafana_folder" "platform" {
  provider = grafana.stack

  title = "Platform"
  uid   = "platform"
}

locals {
  platform_costs_dashboard = merge(
    jsondecode(file("${path.module}/dashboards/platform-costs.json")),
    { id = null },
  )
}

resource "grafana_dashboard" "platform_costs" {
  provider = grafana.stack

  folder      = grafana_folder.platform.uid
  config_json = jsonencode(local.platform_costs_dashboard)
  overwrite   = true
}
