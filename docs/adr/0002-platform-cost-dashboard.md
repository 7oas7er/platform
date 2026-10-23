# 0002 — Platform cost overview dashboard (EUR)

- **Status:** accepted
- **Date:** 2026-10-23

## Context

App Grafana roots (Block Drop, Netrunner, …) own **product** dashboards: traffic, synthetics, CloudWatch, CI. Operator spend spans many vendors (Cursor, Claude, GitHub, Cloudflare, AWS, …) and is not bound to a single app. Putting a cost overview in an app repo would recreate the ADR 0001 anti-pattern (siblings depending on one app).

Vendor billing APIs are uneven: AWS is automatable later; Cursor / Claude subscriptions and similar often have no public cost API. A useful overview must allow **operator-maintained** amounts while leaving room for API-backed panels.

## Decision

1. **Own a platform cost dashboard in `7oas7er/platform` `shared-obs`**, not in app repos.
2. **Currency is EUR** (€) for all cost panels and the P0 feed.
3. **Manual feed (non-AWS):** `infra/terraform/shared-obs/costs/monthly.json` — edit amounts, regenerate the dashboard JSON, `terraform apply` locally.
4. **Reuse Infinity** via `infinity-platform` (inline + FX URL). Do **not** overload `infinity-cloudflare`.
5. **AWS automation (P1):** Grafana Cloud Provider scrape job `platform-aws-billing` → Prometheus metric from `AWS/Billing` `EstimatedCharges` (USD, `us-east-1`). Convert to EUR with Frankfurter on the dashboard. Reuse an existing Cloud Provider AWS account `resource_id` when the account is already linked (e.g. by an app); otherwise create account `platform` + IAM role. One-time: **Receive CloudWatch Billing Alerts**. Do **not** use a CloudWatch data source with `grafana_assume_role` on this stack (credentials failed).
6. **Later (non-blocking):** Cost Explorer / CUR for tag splits (`Project=`); GitHub / Cloudflare billing APIs; subscription vendors stay manual unless APIs appear.
7. App grafana roots stay product-only; they must not recreate this folder/dashboard or `infinity-platform`.

## Consequences

- `shared-obs` owns: Infinity Cloudflare + GitHub plugin, platform folder/dashboard, `infinity-platform`, billing scrape job, optional billing IAM role, `costs/monthly.json`.
- Spend figures in `costs/monthly.json` are committed (public repo). Treat as non-secret operational data; do not put tokens or invoices there.
- AWS amounts are **estimates in USD** converted at the live FX rate (not the invoice settlement currency).
- Docs / AGENTS “what lives where” must list platform costs under platform, not apps.

## See also

- [0001-shared-edge-and-obs.md](0001-shared-edge-and-obs.md)
- [architecture.md](../architecture.md)
- [`infra/terraform/shared-obs/README.md`](../../infra/terraform/shared-obs/README.md)
