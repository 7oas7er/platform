data "grafana_cloud_stack" "platform" {
  provider = grafana.cloud
  slug     = var.stack_slug
}
