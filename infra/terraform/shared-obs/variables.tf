variable "stack_slug" {
  description = "Grafana Cloud stack slug (shared Free stack for all 7oas7er apps)."
  type        = string
}

variable "cloud_access_policy_token" {
  description = "Grafana Cloud access policy token (stacks:read, stack-service-accounts:write, stack-plugins:read|write)."
  type        = string
  sensitive   = true
}

variable "stack_service_account_token" {
  description = <<-EOT
    Grafana stack service account token (Admin) for the stack provider.
    After creating grafana_cloud_stack_service_account_token.terraform, set this to
    that token (terraform output -raw stack_service_account_token). For bootstrap
    you may temporarily use another Admin stack SA token (e.g. block-drop-terraform).
  EOT
  type        = string
  sensitive   = true
}

variable "cloudflare_analytics_token" {
  description = "Cloudflare API token with Zone Analytics Read for Infinity GraphQL."
  type        = string
  sensitive   = true
}

variable "github_plugin_version" {
  description = "Pinned grafana-github-datasource Cloud plugin version (avoid latest → replace)."
  type        = string
  default     = "2.9.3"
}
