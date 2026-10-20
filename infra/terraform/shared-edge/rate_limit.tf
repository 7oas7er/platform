# Cloudflare Free: one rate-limit rule, path-only expression, 10s periods.
resource "cloudflare_ruleset" "rate_limit" {
  zone_id     = local.zone_id
  name        = "7oas7er rate limiting"
  description = "IP rate limit for Block Drop /api/scores (Cloudflare Free constraints)."
  kind        = "zone"
  phase       = "http_ratelimit"

  rules = [
    {
      ref         = "block_drop_api_scores_ip"
      description = "Rate limit /api/scores by IP (Free: 10s window)"
      expression  = "(http.request.uri.path eq \"/api/scores\")"
      action      = "block"
      ratelimit = {
        characteristics     = ["cf.colo.id", "ip.src"]
        period              = var.api_rate_limit_period_seconds
        requests_per_period = var.api_rate_limit_requests_per_period
        mitigation_timeout  = var.api_rate_limit_mitigation_timeout_seconds
      }
    },
  ]
}
