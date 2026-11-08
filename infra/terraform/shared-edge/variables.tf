variable "zone_id" {
  description = "Cloudflare zone id for 7oas7er.com."
  type        = string
  default     = "701810fff825f90c0eea671970a0cc9e"
}

variable "zone_name" {
  description = "Apex hostname for the Cloudflare zone (email DNS + Email Routing)."
  type        = string
  default     = "7oas7er.com"
}

variable "cloudflare_account_id" {
  description = "Cloudflare account id (required when enable_email_routing is true; Email Routing destination addresses are account-scoped)."
  type        = string
  default     = ""
}

# --- Email auth / optional Email Routing -------------------------------------

variable "enable_email_routing" {
  description = <<-EOT
    When false (default): apex SPF is v=spf1 -all (no senders) and no MX.
    When true: Cloudflare Email Routing owns MX + routing SPF
    (include:_spf.mx.cloudflare.net); destination/custom rules are created from
    the email_routing_* vars. Destination must be verified via Cloudflare's
    email before mail forwards. Not mailbox hosting — inbound forward only.
  EOT
  type        = bool
  default     = false
}

variable "email_routing_destination" {
  description = "External mailbox that receives forwarded @zone mail. Placeholder in tfvars.example — set the real address locally; never commit it if sensitive."
  type        = string
  default     = ""
}

variable "email_routing_catch_all" {
  description = "When Email Routing is enabled, create a catch-all rule forwarding any @zone address to email_routing_destination."
  type        = bool
  default     = true
}

variable "email_routing_custom_addresses" {
  description = "Optional literal custom addresses to forward (e.g. contact@7oas7er.com). Ignored unless enable_email_routing is true."
  type        = list(string)
  default     = []
}

variable "dmarc_rua" {
  description = "Optional DMARC aggregate report mailbox (address only, no mailto:). Empty = p=none without rua. Prefer an inbox you monitor; do not invent one."
  type        = string
  default     = ""
}

# Block Drop — must match that app's AWS envs/*/ origin_verify_secret.
variable "blockdrop_stg_origin_verify_secret" {
  description = "X-Origin-Verify for blockdrop-stg.7oas7er.com."
  type        = string
  sensitive   = true
}

variable "blockdrop_prod_origin_verify_secret" {
  description = "X-Origin-Verify for blockdrop.7oas7er.com."
  type        = string
  sensitive   = true
}

# Netrunner — must match netrunner AWS envs/*/ origin_verify_secret.
variable "netrunner_stg_origin_verify_secret" {
  description = "X-Origin-Verify for netrunner-stg.7oas7er.com."
  type        = string
  sensitive   = true
}

variable "netrunner_prod_origin_verify_secret" {
  description = "X-Origin-Verify for netrunner.7oas7er.com."
  type        = string
  sensitive   = true
}

# DressMe — must match dressme AWS envs/*/ origin_verify_secret.
variable "dressme_stg_origin_verify_secret" {
  description = "X-Origin-Verify for dressme-stg.7oas7er.com."
  type        = string
  sensitive   = true
}

variable "dressme_prod_origin_verify_secret" {
  description = "X-Origin-Verify for dressme.7oas7er.com."
  type        = string
  sensitive   = true
}

# Homepage — must match homepage AWS envs/*/ origin_verify_secret.
variable "homepage_stg_origin_verify_secret" {
  description = "X-Origin-Verify for www-stg.7oas7er.com."
  type        = string
  sensitive   = true
}

variable "homepage_prod_origin_verify_secret" {
  description = "X-Origin-Verify for www.7oas7er.com."
  type        = string
  sensitive   = true
}

# FUBoot Tours — must match fuboot-tours AWS envs/*/ origin_verify_secret.
variable "fuboot_stg_origin_verify_secret" {
  description = "X-Origin-Verify for fuboot-stg.7oas7er.com."
  type        = string
  sensitive   = true
}

variable "fuboot_prod_origin_verify_secret" {
  description = "X-Origin-Verify for fuboot.7oas7er.com."
  type        = string
  sensitive   = true
}

variable "api_rate_limit_period_seconds" {
  description = "Counting window for /api/scores rate limiting (Free: must be 10)."
  type        = number
  default     = 10

  validation {
    condition     = contains([10, 15, 20, 30, 40, 45, 60, 90, 120, 180, 240, 300, 480, 600, 900, 1200, 1800, 2400, 3600], var.api_rate_limit_period_seconds)
    error_message = "api_rate_limit_period_seconds must be a Cloudflare-supported counting period."
  }
}

variable "api_rate_limit_requests_per_period" {
  description = "Max requests per IP (per colo) to /api/scores within the counting period."
  type        = number
  default     = 20

  validation {
    condition     = var.api_rate_limit_requests_per_period >= 1 && var.api_rate_limit_requests_per_period <= 1000000
    error_message = "api_rate_limit_requests_per_period must be between 1 and 1000000."
  }
}

variable "api_rate_limit_mitigation_timeout_seconds" {
  description = "Mitigation timeout after threshold (Free: must be 10)."
  type        = number
  default     = 10

  validation {
    condition     = contains([10, 15, 20, 30, 40, 45, 60, 90, 120, 180, 240, 300, 480, 600, 900, 1200, 1800, 2400, 3600, 65535, 86400], var.api_rate_limit_mitigation_timeout_seconds)
    error_message = "api_rate_limit_mitigation_timeout_seconds must be a Cloudflare-supported mitigation period."
  }
}

variable "enable_bot_fight_mode" {
  description = <<-EOT
    Bot Fight Mode (zone-wide JS challenges). Default false: Free BFM cannot be
    skipped via WAF rules and commonly breaks Grafana synthetics, curl health
    probes, headless CI, and non-browser /api clients. Set true only after an
    explicit opt-in and post-apply synthetic/API checks.
  EOT
  type        = bool
  default     = false
}
