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

# AWS billing is scraped by Cloud Provider (cloudwatch.tf) into Prometheus — no
# CloudWatch data source. grafana_assume_role on a CW DS failed with
# "get credentials: failed" on this stack; scrape uses the working auth path.
