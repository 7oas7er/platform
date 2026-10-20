# Catalog plugin shared by all apps on this stack. Pin version — "latest" forces replace.
resource "grafana_cloud_plugin_installation" "github" {
  provider = grafana.cloud

  stack_slug = var.stack_slug
  slug       = "grafana-github-datasource"
  version    = var.github_plugin_version

  lifecycle {
    ignore_changes = [version]
  }
}
