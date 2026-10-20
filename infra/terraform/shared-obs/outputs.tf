output "grafana_stack_url" {
  description = "Grafana Cloud stack URL."
  value       = data.grafana_cloud_stack.platform.url
}

output "cloudflare_edge_datasource_uid" {
  description = "Shared Infinity Cloudflare GraphQL data source UID."
  value       = grafana_data_source.cloudflare_infinity.uid
}

output "github_plugin_slug" {
  description = "Installed GitHub datasource plugin slug."
  value       = grafana_cloud_plugin_installation.github.slug
}
