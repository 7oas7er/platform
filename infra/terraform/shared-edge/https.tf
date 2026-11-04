# Zone HTTPS / TLS / DNSSEC for 7oas7er.com.
# Advice: homepage project note cloudflare-https-hsts-dnssec.md

# Full (strict): Cloudflare↔origin requires a valid cert (ACM on CloudFront).
resource "cloudflare_zone_setting" "ssl" {
  zone_id    = local.zone_id
  setting_id = "ssl"
  value      = "strict"
}

# Edge 301 HTTP→HTTPS for the whole zone (complements apex→www HTTPS redirect).
resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = local.zone_id
  setting_id = "always_use_https"
  value      = "on"
}

# Drop TLS 1.0/1.1. Prefer 1.2 over 1.3-only so older clients / probes still work.
resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = local.zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

# HSTS: moderate max-age (6 months), includeSubDomains on, preload off until
# plain HTTP is permanently ruled out for every host on the zone.
resource "cloudflare_zone_setting" "security_header" {
  zone_id    = local.zone_id
  setting_id = "security_header"
  value = {
    strict_transport_security = {
      enabled            = true
      include_subdomains = true
      max_age            = 15552000 # 180 days
      nosniff            = true
      preload            = false
    }
  }
}

# Enable Cloudflare DNSSEC signing. After apply, confirm the DS record is at
# the registrar (automatic if Cloudflare is registrar; otherwise paste
# terraform output dnssec_ds). Wrong/missing DS can break resolution.
resource "cloudflare_zone_dnssec" "zone" {
  zone_id = local.zone_id
  status  = "active"
}
