# Grafana Cloud assumes this role to query AWS/Billing EstimatedCharges (us-east-1).
# Org RCP must allow Grafana Labs account 008923505280 sts:AssumeRole (same as app scrape).

data "aws_iam_policy_document" "grafana_billing_assume_role" {
  count = var.enable_aws_billing_costs ? 1 : 0

  statement {
    sid     = "AllowGrafanaCloudAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.grafana_labs_aws_account_id}:root"]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [local.grafana_aws_external_id]
    }
  }
}

data "aws_iam_policy_document" "grafana_billing" {
  count = var.enable_aws_billing_costs ? 1 : 0

  statement {
    sid    = "AllowCloudWatchBillingMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "grafana_billing" {
  count = var.enable_aws_billing_costs ? 1 : 0

  name               = local.grafana_billing_role_name
  description        = "Grafana Cloud queries AWS/Billing EstimatedCharges for platform cost dashboard."
  assume_role_policy = data.aws_iam_policy_document.grafana_billing_assume_role[0].json

  tags = {
    Name = local.grafana_billing_role_name
  }
}

resource "aws_iam_role_policy" "grafana_billing" {
  count = var.enable_aws_billing_costs ? 1 : 0

  name   = local.grafana_billing_policy_name
  role   = aws_iam_role.grafana_billing[0].id
  policy = data.aws_iam_policy_document.grafana_billing[0].json
}

resource "time_sleep" "grafana_billing_iam_propagation" {
  count = var.enable_aws_billing_costs ? 1 : 0

  depends_on = [
    aws_iam_role.grafana_billing,
    aws_iam_role_policy.grafana_billing,
  ]

  create_duration = "15s"
}
