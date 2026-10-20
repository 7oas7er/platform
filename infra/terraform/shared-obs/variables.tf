variable "stack_slug" {
  description = "Grafana Cloud stack slug (shared Free stack for all 7oas7er apps)."
  type        = string
}

variable "cloud_access_policy_token" {
  description = "Grafana Cloud access policy token (stacks:read, stack-service-accounts:write, stack-plugins:read|write)."
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
