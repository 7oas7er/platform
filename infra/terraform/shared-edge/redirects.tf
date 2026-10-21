# www / apex → blockdrop.7oas7er.com (zone-wide canonical for the apex domain).
resource "cloudflare_ruleset" "redirects" {
  zone_id = local.zone_id
  # Keep name identical to live Cloudflare ruleset — renaming ForceNew-replaces the ruleset.
  name        = "Block Drop canonical redirects"
  description = "Redirect www and apex to blockdrop.7oas7er.com."
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules = [
    {
      ref         = "www_apex_to_blockdrop"
      description = "Canonical redirect www/apex → blockdrop.7oas7er.com"
      expression  = "(http.host in {\"www.7oas7er.com\" \"7oas7er.com\"})"
      action      = "redirect"
      action_parameters = {
        from_value = {
          status_code = 301
          target_url = {
            expression = "concat(\"https://blockdrop.7oas7er.com\", http.request.uri.path)"
          }
          preserve_query_string = true
        }
      }
    },
  ]
}
