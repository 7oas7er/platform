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

# Inline (P0) / future URL feeds for platform cost dashboard — not for app traffic.
resource "grafana_data_source" "platform_infinity" {
  provider = grafana.stack

  type = "yesoreyeram-infinity-datasource"
  name = "Platform costs"
  uid  = "infinity-platform"

  json_data_encoded = jsonencode({
    auth_method = "none"
    # URL mode later (S3, billing APIs). Inline queries do not need these hosts.
    allowedHosts = [
      "https://api.github.com",
      "https://api.cloudflare.com",
    ]
  })
}
