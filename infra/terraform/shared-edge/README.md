# shared-edge — zone rulesets for 7oas7er.com

Owns the only zone rulesets for origin-verify, cache, redirects, rate-limit, and SSL mode.

App repos must manage **DNS only** (Block Drop / Netrunner Cloudflare roots).

```bash
export AWS_PROFILE=7oas7er-terraform
export CLOUDFLARE_API_TOKEN=…   # Transform Rules, Cache Rules, WAF, Redirects, Zone Settings
terraform init
terraform apply
```

See [docs/MIGRATION.md](../../../docs/MIGRATION.md) to import from Block Drop state.
