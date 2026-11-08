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

output "email_routing_enabled" {
  description = "Whether Cloudflare Email Routing resources are managed (enable_email_routing)."
  value       = var.enable_email_routing
}

output "email_spf_policy" {
  description = "Effective SPF intent: reject-all (TF TXT) or Cloudflare Email Routing–managed include."
  value       = var.enable_email_routing ? "routing: include:_spf.mx.cloudflare.net ~all (via email_routing_dns)" : local.spf_reject_all
}

output "email_dmarc_policy" {
  description = "DMARC TXT content published at _dmarc."
  value       = local.dmarc_policy
}

output "email_routing_destination_verified" {
  description = "Timestamp when the Email Routing destination was verified (null until Frank clicks the verify link)."
  value       = try(cloudflare_email_routing_address.destination[0].verified, null)
}
