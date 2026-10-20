locals {
  zone_id = var.zone_id
}

# One zone ruleset per phase on 7oas7er.com — all app hosts live here.
resource "cloudflare_ruleset" "origin_verify" {
  zone_id     = local.zone_id
  # Keep name identical to live Cloudflare ruleset — renaming ForceNew-replaces the ruleset.
  name        = "Block Drop origin verify headers"
  description = "Inject X-Origin-Verify so CloudFront accepts only Cloudflare-proxied traffic (Block Drop + Netrunner hosts)."
  kind        = "zone"
  phase       = "http_request_late_transform"

  rules = [
    {
      # Keep refs stable for import from Block Drop state.
      ref         = "stg_origin_verify"
      description = "Staging Block Drop origin verify"
      expression  = "http.host eq \"blockdrop-stg.7oas7er.com\""
      action      = "rewrite"
      action_parameters = {
        headers = {
          "X-Origin-Verify" = {
            operation = "set"
            value     = var.blockdrop_stg_origin_verify_secret
          }
        }
      }
    },
    {
      ref         = "prod_origin_verify"
      description = "Production Block Drop origin verify"
      expression  = "http.host eq \"blockdrop.7oas7er.com\""
      action      = "rewrite"
      action_parameters = {
        headers = {
          "X-Origin-Verify" = {
            operation = "set"
            value     = var.blockdrop_prod_origin_verify_secret
          }
        }
      }
    },
    {
      ref         = "netrunner_stg_origin_verify"
      description = "Staging Netrunner origin verify"
      expression  = "http.host eq \"netrunner-stg.7oas7er.com\""
      action      = "rewrite"
      action_parameters = {
        headers = {
          "X-Origin-Verify" = {
            operation = "set"
            value     = var.netrunner_stg_origin_verify_secret
          }
        }
      }
    },
    {
      ref         = "netrunner_prod_origin_verify"
      description = "Production Netrunner origin verify"
      expression  = "http.host eq \"netrunner.7oas7er.com\""
      action      = "rewrite"
      action_parameters = {
        headers = {
          "X-Origin-Verify" = {
            operation = "set"
            value     = var.netrunner_prod_origin_verify_secret
          }
        }
      }
    },
  ]
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = local.zone_id
  setting_id = "ssl"
  value      = "strict"
}
