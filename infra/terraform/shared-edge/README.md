# shared-edge — zone rulesets for 7oas7er.com

Owns the only zone rulesets for origin-verify, cache, redirects, rate-limit, and zone
HTTPS/TLS settings (SSL Full strict, Always Use HTTPS, HSTS, min TLS 1.2, DNSSEC),
plus Free security toggles (leaked-credentials detection; optional Bot Fight Mode).

App repos must manage **DNS only** (Block Drop / Netrunner / DressMe / Homepage Cloudflare roots).

## Apply (local)

```bash
export AWS_PROFILE=7oas7er-terraform
export CLOUDFLARE_API_TOKEN=…   # Transform Rules, Cache Rules, WAF, Redirects, Zone Settings, DNS, Bot Management, Page Shield
cd infra/terraform/shared-edge
terraform init
terraform plan
terraform apply
```

If the dashboard already differs from these defaults, import before the first apply:

```bash
ZONE=701810fff825f90c0eea671970a0cc9e
terraform import cloudflare_zone_setting.always_use_https "${ZONE}/always_use_https"
terraform import cloudflare_zone_setting.min_tls_version "${ZONE}/min_tls_version"
terraform import cloudflare_zone_setting.security_header "${ZONE}/security_header"
terraform import cloudflare_zone_dnssec.zone "${ZONE}"
```

### After apply — DNSSEC DS at registrar

`terraform apply` turns on Cloudflare zone signing. Confirm the **DS** record is
published at the domain registrar (often automatic when Cloudflare is registrar).
Print the DS Cloudflare expects:

```bash
terraform output dnssec_ds
```

Incomplete DS = little benefit; a wrong cutover can break resolution. Confirm
nameservers are Cloudflare before enabling.

### After apply — Client-side security (Page Shield)

There is **no** official `cloudflare_page_shield` zone-enable resource yet
([provider issue #7006](https://github.com/cloudflare/terraform-provider-cloudflare/issues/7006)).
Enable continuous script monitoring once per zone (idempotent):

```bash
# from repo root, after CLOUDFLARE_API_TOKEN is set
./tools/enable-client-side-security
# or:
curl -sS -X PUT "https://api.cloudflare.com/client/v4/zones/${ZONE_ID:-701810fff825f90c0eea671970a0cc9e}/page_shield" \
  -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"enabled":true,"use_cloudflare_reporting_endpoint":true}'
```

### Bot Fight Mode

Defaults **off** (`enable_bot_fight_mode = false`). Do not flip on without checking
Grafana synthetics, curl probes, and `/api/scores` — Free BFM is zone-wide and
cannot be skipped with WAF rules.

See [docs/MIGRATION.md](../../../docs/MIGRATION.md) to import from Block Drop state.
