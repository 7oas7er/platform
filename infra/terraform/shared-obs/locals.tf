locals {
  name_prefix                 = "shared-platform"
  grafana_billing_role_name   = "${local.name_prefix}-grafana-cloudwatch-billing-role"
  grafana_billing_policy_name = "${local.name_prefix}-grafana-cloudwatch-billing-policy"
  # Grafana Labs AWS account that assumes CloudWatch / Cloud Provider roles.
  grafana_labs_aws_account_id = "008923505280"

  grafana_aws_external_id = coalesce(
    var.grafana_aws_external_id,
    tostring(data.grafana_cloud_stack.platform.prometheus_user_id),
  )

  # One AWS account per Grafana stack. If Block Drop (or another app) already
  # linked the account, pass its resource_id and skip creating a duplicate.
  create_grafana_aws_account = (
    var.enable_aws_billing_costs
    && var.grafana_aws_account_resource_id == null
  )

  grafana_aws_account_resource_id = var.enable_aws_billing_costs ? coalesce(
    var.grafana_aws_account_resource_id,
    try(grafana_cloud_provider_aws_account.platform[0].resource_id, null),
  ) : null
}
