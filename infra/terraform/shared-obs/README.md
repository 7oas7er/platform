# shared-obs — shared Grafana stack objects

Owns:

- Infinity DS `infinity-cloudflare` (Cloudflare GraphQL for apps)
- Infinity DS `infinity-platform` (platform cost dashboard; inline + Frankfurter FX)
- CloudWatch DS `cloudwatch-billing` (AWS `EstimatedCharges`, Grafana Assume Role)
- IAM role `shared-platform-grafana-cloudwatch-billing-role`
- Catalog plugin `grafana-github-datasource` (pinned)
- Grafana folder **Platform** + dashboard **Platform — Costs (EUR)** ([ADR 0002](../../../docs/adr/0002-platform-cost-dashboard.md))

App grafana roots create per-app GitHub data sources (`github-block-drop`, `github-netrunner`) and must **not** install the plugin, recreate Infinity / CloudWatch billing UIDs above, or recreate the platform cost dashboard.

## Apply

```bash
export AWS_PROFILE=7oas7er-terraform   # or 7oas7er
terraform init
terraform apply
```

Copy the Cloudflare analytics probe script usage from Block Drop / Netrunner grafana READMEs; token lives here.

## Cost dashboard (EUR)

### AWS (automated)

1. **One-time** in AWS Billing → Billing preferences → enable **Receive CloudWatch Billing Alerts**.
2. Org RCP must allow Grafana Labs account `008923505280` to `sts:AssumeRole` (same exemption as app CloudWatch scrape).
3. `enable_aws_billing_costs = true` (default) creates the IAM role + `cloudwatch-billing` DS.
4. Dashboard panels show month-to-date **EstimatedCharges** (USD) and **EUR** via Frankfurter `USD→EUR`. Metric region is always `us-east-1`.

If AssumeRole fails, copy the External ID from the CloudWatch data source Settings tab into `grafana_aws_external_id` and re-apply.

### Non-AWS vendors (manual)

1. Edit [`costs/monthly.json`](costs/monthly.json) — amounts in **euros** (do not put AWS here; live panels own it).
2. Regenerate:

   ```bash
   python3 scripts/generate-costs-dashboard.py
   ```

3. `terraform apply` (local).

Optional `project` on each row (`shared`, `blockdrop`, `netrunner`, …). Currency must stay `EUR`. Set `"aws_live": false` only if you need to ship the dashboard without the CloudWatch DS.
