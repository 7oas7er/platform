# Apex → Homepage www. Do NOT redirect www itself (Homepage owns www.7oas7er.com).
# Cutover changes live traffic: previously www+apex redirected to Block Drop.
resource "cloudflare_ruleset" "redirects" {
  zone_id = local.zone_id
  # Keep name identical to live Cloudflare ruleset — renaming ForceNew-replaces the ruleset.
  name        = "Block Drop canonical redirects"
  description = "Redirect apex to www.7oas7er.com (Homepage). www is served by Homepage — not redirected."
  kind        = "zone"
  phase       = "http_request_dynamic_redirect"

  rules = [
    {
      ref         = "apex_to_www"
      description = "Canonical redirect apex → www.7oas7er.com"
      expression  = "(http.host eq \"7oas7er.com\")"
      action      = "redirect"
      action_parameters = {
        from_value = {
          status_code = 301
          target_url = {
            expression = "concat(\"https://www.7oas7er.com\", http.request.uri.path)"
          }
          preserve_query_string = true
        }
      }
    },
  ]
}
