# Zone email authentication + optional Cloudflare Email Routing for 7oas7er.com.
# Inbound only (forward to an external mailbox). Not mailbox hosting.
# DKIM: omit until a real outbound sender exists — Email Routing inbound alone
# does not need a custom DKIM key (Cloudflare does not publish one for routing).

locals {
  # Reject-all when nothing sends as @7oas7er.com. When Email Routing is on,
  # Cloudflare Email Routing DNS owns apex SPF (include:_spf.mx.cloudflare.net ~all)
  # and MX — do not also manage apex SPF here (provider/API overwrite; CF #6444).
  spf_reject_all = "v=spf1 -all"

  dmarc_policy = trimspace(var.dmarc_rua) == "" ? "v=DMARC1; p=none" : "v=DMARC1; p=none; rua=mailto:${trimspace(var.dmarc_rua)}"
}

check "email_routing_requires_destination" {
  assert {
    condition     = !var.enable_email_routing || (trimspace(var.cloudflare_account_id) != "" && trimspace(var.email_routing_destination) != "")
    error_message = "enable_email_routing=true requires cloudflare_account_id and email_routing_destination (set in local tfvars; use placeholders in the example only)."
  }
}

# --- SPF (no routing) --------------------------------------------------------
# Hard fail for forged From: @zone. Flip enable_email_routing to hand SPF/MX
# to cloudflare_email_routing_dns instead.
resource "cloudflare_dns_record" "spf" {
  count = var.enable_email_routing ? 0 : 1

  zone_id = local.zone_id
  name    = var.zone_name
  type    = "TXT"
  ttl     = 1 # automatic
  content = local.spf_reject_all
  comment = "SPF reject-all (no authorized senders yet)"
}

# --- DMARC -------------------------------------------------------------------
# Start monitor-only (p=none). Harden later to quarantine then reject once
# aggregate reports look clean and outbound (if any) is DKIM-aligned.
resource "cloudflare_dns_record" "dmarc" {
  zone_id = local.zone_id
  name    = "_dmarc.${var.zone_name}"
  type    = "TXT"
  ttl     = 1
  content = local.dmarc_policy
  comment = "DMARC monitor (p=none); raise to quarantine/reject after rua review"
}

# --- Email Routing (optional inbound) ----------------------------------------
# Enables routing and locks Cloudflare-managed MX + routing SPF on the apex.
resource "cloudflare_email_routing_dns" "zone" {
  count = var.enable_email_routing ? 1 : 0

  zone_id = local.zone_id
  name    = var.zone_name
}

# Destination mailbox (external). Cloudflare emails a verification link —
# apply creates the address; Frank must verify before rules forward mail.
resource "cloudflare_email_routing_address" "destination" {
  count = var.enable_email_routing ? 1 : 0

  account_id = var.cloudflare_account_id
  email      = var.email_routing_destination
}

# Optional literal custom addresses (e.g. contact@7oas7er.com).
# Lower priority numbers run first — keep these ahead of the catch-all.
resource "cloudflare_email_routing_rule" "custom" {
  for_each = var.enable_email_routing ? toset(var.email_routing_custom_addresses) : toset([])

  zone_id  = local.zone_id
  name     = "Forward ${each.value}"
  enabled  = true
  priority = 10

  matchers = [{
    type  = "literal"
    field = "to"
    value = each.value
  }]

  actions = [{
    type  = "forward"
    value = [var.email_routing_destination]
  }]

  depends_on = [
    cloudflare_email_routing_dns.zone,
    cloudflare_email_routing_address.destination,
  ]
}

# Catch-all: any @zone → destination (after destination is verified).
# High priority number so literal custom rules win when both exist.
resource "cloudflare_email_routing_rule" "catch_all" {
  count = var.enable_email_routing && var.email_routing_catch_all ? 1 : 0

  zone_id  = local.zone_id
  name     = "Catch-all → destination"
  enabled  = true
  priority = 100

  matchers = [{
    type = "all"
  }]

  actions = [{
    type  = "forward"
    value = [var.email_routing_destination]
  }]

  depends_on = [
    cloudflare_email_routing_dns.zone,
    cloudflare_email_routing_address.destination,
  ]
}
