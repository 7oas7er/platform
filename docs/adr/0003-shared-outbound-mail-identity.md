# 0003 — Shared outbound mail identity (SES) for @7oas7er.com

- **Status:** accepted
- **Date:** 2026-11-26

## Context

DressMe invites test users through Cognito. Cognito's default sender (`no-reply@verificationemail.com`) is shared, unrelated to any domain of ours, and its invitation mails landed in spam. A sender on our own domain needs a verified identity with DKIM and SPF/DMARC alignment. Other apps may need to send mail later.

## Decision

1. **Own one outbound identity in `platform`**: `infra/terraform/shared-mail` creates an Amazon SES domain identity for `7oas7er.com` in eu-north-1 (a Cognito pool in eu-north-1 can only use an SES identity in the same region), Easy DKIM, and a custom MAIL FROM subdomain (`mail.7oas7er.com`). The Cloudflare DNS records it needs live in the same stack.
2. **Apps consume only the identity ARN** (`ses_domain_identity_arn`) through a variable (for example DressMe `cognito_ses_source_arn`). No remote-state reads: `app -> platform` only.
3. **Apex SPF and DMARC stay in `shared-edge`** (reject-all or Cloudflare Email Routing's SPF; DMARC `p=none`). DMARC passes through DKIM alignment and the aligned MAIL FROM subdomain.
4. **Inbound is separate**: `dressme@7oas7er.com` is a Cloudflare Email Routing address (`shared-edge`) that forwards to the operator's mailbox. It is not mailbox hosting.
5. **SES production access is manual** (console request, once per region). Apps must not switch to the identity before it is granted: in the sandbox, mail to unverified recipients fails.

## Consequences

- One place to rotate or harden outbound mail (DMARC to quarantine, a configuration set for bounces) for every app.
- Removing the identity breaks every sender; there is no `prevent_destroy` yet.
- Cognito from-address must be at `7oas7er.com`.
