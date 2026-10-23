# AWS billing via Grafana Cloud Provider scrape → Prometheus (same auth path as app
# CloudWatch scrape). The CloudWatch data source + grafana_assume_role path failed
# with "get credentials: failed" — External ID / Assume Role for that auth provider
# is not the same as Cloud Provider's prometheus_user_id trust.

resource "grafana_cloud_provider_aws_account" "platform" {
  count    = local.create_grafana_aws_account ? 1 : 0
  provider = grafana.cloud_provider

  depends_on = [
    time_sleep.grafana_billing_iam_propagation,
    aws_iam_role.grafana_billing,
  ]

  stack_id = data.grafana_cloud_stack.platform.id
  role_arn = aws_iam_role.grafana_billing[0].arn
  name     = "platform"
  regions  = ["us-east-1"] # Billing metrics only exist here
}

resource "grafana_cloud_provider_aws_cloudwatch_scrape_job" "billing" {
  count    = var.enable_aws_billing_costs ? 1 : 0
  provider = grafana.cloud_provider

  stack_id                = data.grafana_cloud_stack.platform.id
  name                    = "platform-aws-billing"
  aws_account_resource_id = local.grafana_aws_account_resource_id
  enabled                 = true
  export_tags             = false
  # Billing is global in us-east-1 only.
  regions_subset_override = ["us-east-1"]

  service {
    name = "AWS/Billing"
    # Cloud Provider rejects 3600; allowed set matches app scrapes (e.g. 300).
    scrape_interval_seconds = 300

    metric {
      name       = "EstimatedCharges"
      statistics = ["Maximum"]
    }
  }

  static_labels = {
    project = "platform"
  }
}
