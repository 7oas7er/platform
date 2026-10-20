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
