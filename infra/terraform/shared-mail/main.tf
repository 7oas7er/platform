# Shared outbound mail identity for @7oas7er.com (Amazon SES, eu-north-1).
# Apps send through it (for example Cognito invites) and consume only the
# identity ARN: app -> platform, never the other way round.
# Inbound (forwarding dressme@ to a real mailbox) is Cloudflare Email Routing in shared-edge.

locals {
  mail_from_domain = "${var.mail_from_subdomain}.${var.zone_name}"
}

resource "aws_sesv2_email_identity" "domain" {
  email_identity = var.zone_name

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }
}

resource "aws_sesv2_email_identity_mail_from_attributes" "domain" {
  email_identity         = aws_sesv2_email_identity.domain.email_identity
  mail_from_domain       = local.mail_from_domain
  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
}

# --- DNS in the Cloudflare zone ------------------------------------------------

# Easy DKIM: three CNAMEs (tokens are known after the identity exists).
resource "cloudflare_dns_record" "dkim" {
  count = 3

  zone_id = var.zone_id
  name    = "${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${var.zone_name}"
  type    = "CNAME"
  ttl     = 1 # automatic
  content = "${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"
  proxied = false
  comment = "SES Easy DKIM"
}

# Custom MAIL FROM: bounces and complaints come back to SES.
resource "cloudflare_dns_record" "mail_from_mx" {
  zone_id  = var.zone_id
  name     = local.mail_from_domain
  type     = "MX"
  ttl      = 1
  priority = 10
  content  = "feedback-smtp.${var.aws_region}.amazonses.com"
  comment  = "SES custom MAIL FROM"
}

resource "cloudflare_dns_record" "mail_from_spf" {
  zone_id = var.zone_id
  name    = local.mail_from_domain
  type    = "TXT"
  ttl     = 1
  content = "v=spf1 include:amazonses.com ~all"
  comment = "SES custom MAIL FROM SPF"
}
