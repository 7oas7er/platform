# shared-obs — shared Grafana stack objects

Owns:

- Infinity DS `infinity-cloudflare` (Cloudflare GraphQL for apps)
- Infinity DS `infinity-platform` (platform cost dashboard; inline + Frankfurter FX)
- Cloud Provider scrape job `platform-aws-billing` (`AWS/Billing` → Prometheus)
- Optional IAM role `shared-platform-grafana-cloudwatch-billing-role` (only if creating the Cloud Provider AWS account here)
- Catalog plugin `grafana-github-datasource` (pinned)
- Grafana folder **Platform** + dashboard **Platform — Costs (EUR)** ([ADR 0002](../../../docs/adr/0002-platform-cost-dashboard.md))
- Optional Adaptive Metrics **DROP-only** rules (`adaptive_metrics.tf`; off by default)

App grafana roots create per-app GitHub data sources (`github-block-drop`, `github-netrunner`) and must **not** install the plugin, recreate Infinity UIDs above, or recreate the platform cost dashboard.

## Apply

```bash
export AWS_PROFILE=7oas7er-terraform   # or 7oas7er
terraform init
terraform apply
```

Copy the Cloudflare analytics probe script usage from Block Drop / Netrunner grafana READMEs; token lives here.

## Cost dashboard (EUR)

### AWS (automated via Cloud Provider scrape)

Uses the **same auth path as app CloudWatch scrape** (not a CloudWatch data source). A CW DS with `grafana_assume_role` failed on this stack with `get credentials: failed`.

1. **One-time** in AWS Billing → Billing preferences → enable **Receive CloudWatch Billing Alerts**.
2. Org RCP must allow Grafana Labs account `008923505280` to `sts:AssumeRole`.
3. `cloud_provider_access_token` with `integration-management:read|write` (or reuse `cloud_access_policy_token` if it already has those scopes).
4. **AWS account already linked** (typical — Block Drop created it): set in `terraform.tfvars`:

   ```hcl
   grafana_aws_account_resource_id = "…"  # from Grafana → Cloud Provider → AWS → account, or block-drop state
   ```

   Then this root only adds scrape job `platform-aws-billing`.

5. **No account yet:** leave `grafana_aws_account_resource_id` unset; Terraform creates account `platform` + IAM role (fails if the AWS account is already registered under another name — then use step 4).

Dashboard panels query Prometheus:

- **Total:** `max(aws_billing_estimated_charges_maximum{dimension_Currency="USD",project="platform"})` → USD→EUR via Frankfurter (`api.frankfurter.dev`)
- **By service:** `max by (dimension_ServiceName) (…{dimension_ServiceName=~".+"})` (USD; Cloud Provider keeps the `dimension_` prefix)

These are **EstimatedCharges** (billing alerts), not Cost Explorer / invoice. AWS updates a few times per day; scrape is every 5m. Tag / `Project=` splits remain a later Cost Explorer / CUR item (ADR 0002).

### Non-AWS vendors (manual)

1. Edit [`costs/monthly.json`](costs/monthly.json) — amounts in **euros** (do not put AWS here).
2. Regenerate:

   ```bash
   python3 scripts/generate-costs-dashboard.py
   ```

3. `terraform apply` (local).

Optional `project` on each row (`shared`, `blockdrop`, `netrunner`, …). Currency must stay `EUR`. Set `"aws_live": false` only to omit AWS panels.

## Adaptive Metrics (DROP-only)

**Auto-apply stays off.** Do not click Enable auto-apply / Apply all recommendations — several recommendations would drop metrics used by app dashboards and the platform cost dashboard (`probe_http_duration_seconds`, CloudFront requests/errors/latency, `aws_billing_estimated_charges_maximum`).

Keep vs drop evidence (cross-repo PromQL audit): Project doc `docs/grafana-adaptive-metrics-keep-drop.md`.

### Preferred apply path — Grafana UI (no new token)

1. Open the shared stack → **Adaptive Metrics** → **Overview**. Confirm Auto-apply is **disabled** for the default segment.
2. Open **Metrics**. Apply **only** DROP recommendations / custom Drop rules for:
   - Probe first: `probe_all_duration_seconds_bucket`, `probe_dns_lookup_time_seconds`, `probe_failed_due_to_regex`, `probe_http_content_length`, `probe_http_redirects`, `probe_http_ssl`, `probe_http_uncompressed_body_length`, `probe_http_version`, `probe_http_last_modified_timestamp_seconds`, `probe_all_success_count`, `probe_all_success_sum`, plus prefixes `probe_ip_`, `probe_ssl_`, `probe_tls_` (Add new rule → Drop → match type prefix).
   - Then prefix Drop `aws_lambda_` (scraped, unused in dashboards).
   - Then exact Drop `aws_cloudfront_bytes_downloaded_sum`, `aws_cloudfront_total_error_rate_average`, `aws_cloudfront_info`.
3. **Do not** drop/aggregate: `probe_success`, `probe_duration_seconds`, `probe_http_duration_seconds`, `probe_http_status_code`, `aws_cloudfront_requests_sum`, `aws_cloudfront_4xx_error_rate_average`, `aws_cloudfront_5xx_error_rate_average`, `aws_cloudfront_origin_latency_average`, `aws_billing_estimated_charges_maximum`.
4. Spot-check one app Production dashboard + **Platform — Costs (EUR)**.

### Optional IaC apply

Default `enable_adaptive_metrics_drops = false` — normal `terraform apply` does not touch Adaptive Metrics.

1. Create a Cloud Access Policy token with `adaptive-metrics-rules:read` and `adaptive-metrics-rules:write` (and keep existing scopes on other tokens as-is).
2. In `terraform.tfvars`:

   ```hcl
   enable_adaptive_metrics_drops  = true
   adaptive_metrics_access_token  = "glc_…"
   ```

3. `terraform plan` / `apply` locally (`AWS_PROFILE=7oas7er-terraform` as usual). Resources are individual `grafana-adaptive-metrics_rule` with `drop = true` only — no recommendations ruleset.
4. Leave Grafana Auto-apply **off** after apply.
