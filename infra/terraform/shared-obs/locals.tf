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
}
