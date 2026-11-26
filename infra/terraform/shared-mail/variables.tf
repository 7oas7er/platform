variable "aws_region" {
  description = "SES region. Cognito user pools in eu-north-1 can only use an SES identity in eu-north-1."
  type        = string
  default     = "eu-north-1"
}

variable "zone_id" {
  description = "Cloudflare zone id for 7oas7er.com (same zone as shared-edge)."
  type        = string
  default     = "701810fff825f90c0eea671970a0cc9e"
}

variable "zone_name" {
  description = "Domain that sends mail (SES domain identity)."
  type        = string
  default     = "7oas7er.com"
}

variable "mail_from_subdomain" {
  description = "Subdomain for SES custom MAIL FROM (bounce handling and SPF). Keeps SPF aligned without touching the apex SPF that shared-edge or Email Routing owns."
  type        = string
  default     = "mail"
}

variable "alert_email" {
  description = "Mailbox that receives SES bounce, complaint and reject notifications and reputation alarms. Set it in the local terraform.tfvars (never commit a personal address). Empty creates the topic without a subscriber."
  type        = string
  default     = ""
}

variable "bounce_rate_alarm" {
  description = "Account bounce-rate alarm threshold as a fraction (0.02 = 2%). SES reviews accounts at 5% and pauses sending at 10%."
  type        = number
  default     = 0.02
}

variable "complaint_rate_alarm" {
  description = "Account complaint-rate alarm threshold as a fraction (0.0005 = 0.05%). SES reviews accounts at 0.1% and pauses sending at 0.5%."
  type        = number
  default     = 0.0005
}
