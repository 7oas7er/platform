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

variable "aws_region" {
  description = "AWS region for IAM (billing metrics themselves are always queried in us-east-1)."
  type        = string
  default     = "eu-north-1"
}

variable "aws_profile" {
  description = "Optional AWS shared-credentials profile for local terraform (null = default chain)."
  type        = string
  default     = null
}

variable "enable_aws_billing_costs" {
  description = <<-EOT
    Create IAM role + CloudWatch DS for live AWS EstimatedCharges on the cost dashboard.
    Requires one-time Billing preference: Receive CloudWatch Billing Alerts.
    Org RCP must allow Grafana Labs account 008923505280 to sts:AssumeRole.
  EOT
  type        = bool
  default     = true
}

variable "grafana_aws_external_id" {
  description = <<-EOT
    sts:ExternalId for the Grafana Assume Role trust policy.
    Defaults to the stack prometheus_user_id (same pattern as app CloudWatch scrape).
    Override with the External ID shown on the CloudWatch data source Settings tab if AssumeRole fails.
  EOT
  type        = string
  default     = null
}
