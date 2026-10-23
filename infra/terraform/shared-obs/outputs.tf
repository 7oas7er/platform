output "grafana_stack_url" {
  description = "Grafana Cloud stack URL."
  value       = data.grafana_cloud_stack.platform.url
}

output "stack_service_account_token" {
  description = "platform-terraform stack SA token — copy into terraform.tfvars as stack_service_account_token after first create."
  value       = grafana_cloud_stack_service_account_token.terraform.key
  sensitive   = true
}

output "cloudflare_edge_datasource_uid" {
  description = "Shared Infinity Cloudflare GraphQL data source UID."
  value       = grafana_data_source.cloudflare_infinity.uid
}

output "platform_costs_datasource_uid" {
  description = "Infinity UID for platform cost dashboard (inline / future URL)."
  value       = grafana_data_source.platform_infinity.uid
}

output "platform_folder_uid" {
  description = "Grafana folder UID for platform-owned dashboards."
  value       = grafana_folder.platform.uid
}

output "platform_costs_dashboard_url" {
  description = "URL path for the EUR cost overview dashboard."
  value       = grafana_dashboard.platform_costs.url
}

output "cloudwatch_billing_datasource_uid" {
  description = "CloudWatch DS UID for AWS EstimatedCharges (null if enable_aws_billing_costs=false)."
  value       = try(grafana_data_source.cloudwatch_billing[0].uid, null)
}

output "grafana_billing_role_arn" {
  description = "IAM role Grafana Assume Role uses for billing metrics."
  value       = try(aws_iam_role.grafana_billing[0].arn, null)
}

output "grafana_aws_external_id" {
  description = "External ID embedded in the billing role trust policy."
  value       = var.enable_aws_billing_costs ? local.grafana_aws_external_id : null
}

output "github_plugin_slug" {
  description = "Installed GitHub datasource plugin slug."
  value       = grafana_cloud_plugin_installation.github.slug
}
