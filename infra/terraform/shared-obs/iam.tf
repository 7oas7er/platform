# IAM role for Grafana Cloud Provider to scrape AWS/Billing (us-east-1).
# Only created when we also create grafana_cloud_provider_aws_account.platform.
# If the AWS account is already linked (e.g. by Block Drop), set
# grafana_aws_account_resource_id instead — that account's role is used for scrape.

data "aws_iam_policy_document" "grafana_billing_assume_role" {
  count = local.create_grafana_aws_account ? 1 : 0

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
  count = local.create_grafana_aws_account ? 1 : 0

  statement {
    sid    = "AllowCloudWatchBillingScrape"
    effect = "Allow"
    actions = [
      "tag:GetResources",
      "cloudwatch:GetMetricData",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "grafana_billing" {
  count = local.create_grafana_aws_account ? 1 : 0

  name               = local.grafana_billing_role_name
  description        = "Grafana Cloud Provider scrapes AWS/Billing EstimatedCharges for platform costs."
  assume_role_policy = data.aws_iam_policy_document.grafana_billing_assume_role[0].json

  tags = {
    Name = local.grafana_billing_role_name
  }
}

resource "aws_iam_role_policy" "grafana_billing" {
  count = local.create_grafana_aws_account ? 1 : 0

  name   = local.grafana_billing_policy_name
  role   = aws_iam_role.grafana_billing[0].id
  policy = data.aws_iam_policy_document.grafana_billing[0].json
}

resource "time_sleep" "grafana_billing_iam_propagation" {
  count = local.create_grafana_aws_account ? 1 : 0

  depends_on = [
    aws_iam_role.grafana_billing,
    aws_iam_role_policy.grafana_billing,
  ]

  create_duration = "15s"
}
