# shared-obs — shared Grafana stack objects

Owns:

- Infinity DS `infinity-cloudflare` (Cloudflare GraphQL for apps)
- Infinity DS `infinity-platform` (platform cost dashboard; inline + Frankfurter FX)
- Cloud Provider scrape job `platform-aws-billing` (`AWS/Billing` → Prometheus)
- Optional IAM role `shared-platform-grafana-cloudwatch-billing-role` (only if creating the Cloud Provider AWS account here)
- Catalog plugin `grafana-github-datasource` (pinned)
- Grafana folder **Platform** + dashboard **Platform — Costs (EUR)** ([ADR 0002](../../../docs/adr/0002-platform-cost-dashboard.md))

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

Dashboard panels query Prometheus `aws_billing_estimated_charges_maximum{currency="USD",project="platform"}` and convert USD→EUR via Frankfurter.

### Non-AWS vendors (manual)

1. Edit [`costs/monthly.json`](costs/monthly.json) — amounts in **euros** (do not put AWS here).
2. Regenerate:

   ```bash
   python3 scripts/generate-costs-dashboard.py
   ```

3. `terraform apply` (local).

Optional `project` on each row (`shared`, `blockdrop`, `netrunner`, …). Currency must stay `EUR`. Set `"aws_live": false` only to omit AWS panels.
