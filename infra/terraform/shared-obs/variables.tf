variable "stack_slug" {
  description = "Grafana Cloud stack slug (shared Free stack for all 7oas7er apps)."
  type        = string
}

variable "cloud_access_policy_token" {
  description = "Grafana Cloud access policy token (stacks:read, stack-service-accounts:write, stack-plugins:read|write)."
  type        = string
  sensitive   = true
}

variable "cloud_provider_access_token" {
  description = <<-EOT
    Access policy token with integration-management:read|write and stacks:read for Cloud Provider
    AWS account + CloudWatch scrape jobs. Prefer GRAFANA_CLOUD_PROVIDER_ACCESS_TOKEN.
    Required when enable_aws_billing_costs is true.
  EOT
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
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
    Create Cloud Provider CloudWatch scrape job for AWS/Billing EstimatedCharges (Prometheus).
    Requires one-time Billing preference: Receive CloudWatch Billing Alerts.
    Org RCP must allow Grafana Labs account 008923505280 to sts:AssumeRole.
    Also requires cloud_provider_access_token.
  EOT
  type        = bool
  default     = true
}

variable "grafana_aws_account_resource_id" {
  description = <<-EOT
    Existing Grafana Cloud Provider AWS account resource_id on this stack.
    Set this when the account is already linked (e.g. by Block Drop grafana root) so we
    only add the platform-aws-billing scrape job. Leave null to create account "platform"
    (fails if the AWS account is already registered under another name).
  EOT
  type        = string
  default     = null
  nullable    = true
}

variable "grafana_aws_external_id" {
  description = <<-EOT
    sts:ExternalId for the Cloud Provider IAM trust policy (only when creating the platform account).
    Defaults to the stack prometheus_user_id. Override from Grafana → Cloud Provider → AWS → Add account
    if account create returns aws_authentication_error.
  EOT
  type        = string
  default     = null
  nullable    = true
}
