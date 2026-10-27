variable "zone_id" {
  description = "Cloudflare zone id for 7oas7er.com."
  type        = string
  default     = "701810fff825f90c0eea671970a0cc9e"
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
