resource "cloudflare_ruleset" "cache" {
  zone_id = local.zone_id
  # Keep name identical to live Cloudflare ruleset — renaming ForceNew-replaces the ruleset.
  name        = "Block Drop cache settings"
  description = "Respect origin Cache-Control for Block Drop, Netrunner, DressMe, and Homepage hosts; bypass Block Drop /api/scores."
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
    {
      ref         = "dressme_respect_origin"
      description = "Respect origin Cache-Control for DressMe static assets"
      expression  = "(http.host in {\"dressme.7oas7er.com\" \"dressme-stg.7oas7er.com\"})"
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
      ref         = "homepage_respect_origin"
      description = "Respect origin Cache-Control for Homepage static assets"
      expression  = "(http.host in {\"www.7oas7er.com\" \"www-stg.7oas7er.com\"})"
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
