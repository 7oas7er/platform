# shared-obs — shared Grafana stack objects

Owns:

- Infinity DS `infinity-cloudflare` (Cloudflare GraphQL for apps)
- Infinity DS `infinity-platform` (platform cost dashboard; inline P0)
- Catalog plugin `grafana-github-datasource` (pinned)
- Grafana folder **Platform** + dashboard **Platform — Costs (EUR)** ([ADR 0002](../../../docs/adr/0002-platform-cost-dashboard.md))

App grafana roots create per-app GitHub data sources (`github-block-drop`, `github-netrunner`) and must **not** install the plugin, recreate Infinity UIDs above, or recreate the platform cost dashboard.

## Apply

```bash
export AWS_PROFILE=7oas7er-terraform
terraform init
terraform apply
```

Copy the Cloudflare analytics probe script usage from Block Drop / Netrunner grafana READMEs; token lives here.

## Cost dashboard (EUR) — P0

1. Edit [`costs/monthly.json`](costs/monthly.json) — amounts in **euros**, one object per vendor per month.
2. Regenerate the dashboard JSON:

   ```bash
   python3 scripts/generate-costs-dashboard.py
   ```

3. `terraform apply` (local).

Optional `project` on each row (`shared`, `blockdrop`, `netrunner`, …) for later splits; currency must stay `EUR`.

**Later:** wire AWS Cost Explorer / vendor APIs into `infinity-platform` URL mode; keep subscription rows manual if no API exists.
