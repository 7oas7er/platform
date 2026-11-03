# shared-edge — zone rulesets for 7oas7er.com

Owns the only zone rulesets for origin-verify, cache, redirects, rate-limit, and SSL mode,
plus Free security toggles (leaked-credentials detection; optional Bot Fight Mode).

App repos must manage **DNS only** (Block Drop / Netrunner / DressMe / Homepage Cloudflare roots).

## Apply (local)

```bash
export AWS_PROFILE=7oas7er-terraform
export CLOUDFLARE_API_TOKEN=…   # Transform Rules, Cache Rules, WAF, Redirects, Zone Settings, Bot Management, Page Shield
cd infra/terraform/shared-edge
terraform init
terraform plan
terraform apply
```

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
