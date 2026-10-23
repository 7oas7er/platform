# Shared Infinity → Cloudflare GraphQL. Apps reference uid infinity-cloudflare only.
resource "grafana_data_source" "cloudflare_infinity" {
  provider = grafana.stack

  type = "yesoreyeram-infinity-datasource"
  name = "Cloudflare GraphQL"
  uid  = "infinity-cloudflare"

  json_data_encoded = jsonencode({
    auth_method = "bearerToken"
    allowedHosts = [
      "https://api.cloudflare.com",
      "https://api.cloudflare.com/client/v4/graphql",
    ]
  })

  secure_json_data_encoded = jsonencode({
    bearerToken = var.cloudflare_analytics_token
  })
}

# Inline + FX URL for platform cost dashboard — not for app traffic.
resource "grafana_data_source" "platform_infinity" {
  provider = grafana.stack

  type = "yesoreyeram-infinity-datasource"
  name = "Platform costs"
  uid  = "infinity-platform"

  json_data_encoded = jsonencode({
    auth_method = "none"
    allowedHosts = [
      "https://api.frankfurter.app",
      "https://api.github.com",
      "https://api.cloudflare.com",
    ]
  })
}

# Live AWS MTD estimated charges (USD in us-east-1). Dashboard converts to EUR via Frankfurter.
resource "grafana_data_source" "cloudwatch_billing" {
  count    = var.enable_aws_billing_costs ? 1 : 0
  provider = grafana.stack

  depends_on = [time_sleep.grafana_billing_iam_propagation]

  type = "cloudwatch"
  name = "CloudWatch Billing"
  uid  = "cloudwatch-billing"

  json_data_encoded = jsonencode({
    authType      = "grafana_assume_role"
    defaultRegion = "us-east-1"
    assumeRoleArn = aws_iam_role.grafana_billing[0].arn
  })
}
