output "zone_id" {
  description = "Cloudflare zone id for 7oas7er.com."
  value       = local.zone_id
}

output "dnssec_status" {
  description = "Cloudflare DNSSEC status (active once signing is enabled)."
  value       = cloudflare_zone_dnssec.zone.status
}

output "dnssec_ds" {
  description = "Full DS record to publish at the registrar if Cloudflare is not the registrar (or to verify auto-publish)."
  value       = cloudflare_zone_dnssec.zone.ds
}
