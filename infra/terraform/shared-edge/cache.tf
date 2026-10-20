resource "cloudflare_ruleset" "cache" {
  zone_id     = local.zone_id
  name        = "7oas7er cache settings"
  description = "Respect origin Cache-Control for app hosts; bypass Block Drop /api/*."
  kind        = "zone"
  phase       = "http_request_cache_settings"

  rules = [
    {
      ref         = "block_drop_api_bypass"
      description = "Do not cache Block Drop high-score API"
      expression  = "(http.host in {\"blockdrop.7oas7er.com\" \"blockdrop-stg.7oas7er.com\"} and starts_with(http.request.uri.path, \"/api/\"))"
      action      = "set_cache_settings"
      action_parameters = {
        cache = false
      }
    },
    {
      ref         = "block_drop_respect_origin"
      description = "Respect origin Cache-Control for Block Drop static assets"
      expression  = "(http.host in {\"blockdrop.7oas7er.com\" \"blockdrop-stg.7oas7er.com\"})"
      action      = "set_cache_settings"
      action_parameters = {
        cache = true
        edge_ttl = {
          mode = "respect_origin"
        }
        browser_ttl = {
          mode = "respect_origin"
        }
      }
    },
    {
      ref         = "netrunner_respect_origin"
      description = "Respect origin Cache-Control for Netrunner static assets"
      expression  = "(http.host in {\"netrunner.7oas7er.com\" \"netrunner-stg.7oas7er.com\"})"
      action      = "set_cache_settings"
      action_parameters = {
        cache = true
        edge_ttl = {
          mode = "respect_origin"
        }
        browser_ttl = {
          mode = "respect_origin"
        }
      }
    },
  ]
}
