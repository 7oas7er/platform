# shared-mail

Outbound mail identity for `7oas7er.com`: an Amazon SES domain identity in eu-north-1 with Easy DKIM and a custom MAIL FROM subdomain, plus the Cloudflare DNS records they need. Apps consume only the `ses_domain_identity_arn` output.

Inbound mail (for example `dressme@7oas7er.com` forwarded to a real mailbox) is Cloudflare Email Routing in `../shared-edge` (`enable_email_routing`, `email_routing_custom_addresses`).

## Apply (local)

```bash
export AWS_PROFILE=7oas7er
export CLOUDFLARE_API_TOKEN=...   # DNS edit on the zone
cd infra/terraform/shared-mail
terraform init && terraform plan && terraform apply
terraform output
```

Then wait until `dkim_status` is `SUCCESS` (DNS propagation, usually minutes):

```bash
terraform refresh && terraform output dkim_status
```

## Bounces, complaints and alerts

SES keeps its account-level suppression list on for bounces and complaints. This stack adds a configuration set (`platform-transactional`, outputs `configuration_set_name`) whose BOUNCE, COMPLAINT and REJECT events go to the SNS topic `platform-mail-events`, plus CloudWatch alarms on the account bounce rate (default 2%) and complaint rate (default 0.05%) that notify the same topic. Set `alert_email = "you@example.com"` in the local, gitignored `terraform.tfvars`, apply, then **confirm the subscription** in the mail AWS sends. Apps must send with the configuration set (Cognito: `configuration_set`); mail sent without it is still protected by suppression and the account alarms, but its events are not published.

## SES production access (manual, once)

A new SES account is in the sandbox in each region: it can only send to verified addresses. In the AWS console (region eu-north-1): SES, Account dashboard, Request production access. Mail type: Transactional. Describe it as invitation emails for a small private app (a few messages a month, each sent to a person the operator invited, no marketing, bounces and complaints handled by SES). Approval usually takes about a day. Do not point an app at this identity (for Cognito: `cognito_ses_source_arn`) before it is granted.

## Notes

- Apex SPF is not managed here: `shared-edge` owns it (reject-all, or Cloudflare Email Routing's SPF when routing is on). SES passes DMARC through DKIM alignment and the aligned MAIL FROM subdomain.
- DMARC is `shared-edge` (`p=none`); raise it to quarantine once reports look clean.
- Removing the identity breaks every app sending through it. The identity has no `prevent_destroy` yet; do not `terraform destroy` this stack.
