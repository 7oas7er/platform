output "ses_domain_identity_arn" {
  description = "Pass to an app as its SES source ARN (for example dressme cognito_ses_source_arn)."
  value       = aws_sesv2_email_identity.domain.arn
}

output "sender_domain" {
  description = "Domain that may send; From addresses must be at this domain."
  value       = var.zone_name
}

output "dkim_status" {
  description = "SES verification status of DKIM (SUCCESS once the DNS records have propagated)."
  value       = aws_sesv2_email_identity.domain.dkim_signing_attributes[0].status
}
