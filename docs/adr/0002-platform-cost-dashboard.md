# 0002 — Platform cost overview dashboard (EUR)

- **Status:** accepted
- **Date:** 2026-10-23

## Context

App Grafana roots (Block Drop, Netrunner, …) own **product** dashboards: traffic, synthetics, CloudWatch, CI. Operator spend spans many vendors (Cursor, Claude, GitHub, Cloudflare, AWS, …) and is not bound to a single app. Putting a cost overview in an app repo would recreate the ADR 0001 anti-pattern (siblings depending on one app).

Vendor billing APIs are uneven: AWS is automatable later; Cursor / Claude subscriptions and similar often have no public cost API. A useful overview must allow **operator-maintained** amounts while leaving room for API-backed panels.

## Decision

1. **Own a platform cost dashboard in `7oas7er/platform` `shared-obs`**, not in app repos.
2. **Currency is EUR** (€) for all cost panels and the P0 feed.
3. **P0 data feed:** `infra/terraform/shared-obs/costs/monthly.json` — edit amounts, regenerate the dashboard JSON, `terraform apply` locally.
4. **Reuse Infinity** via a dedicated stack data source `infinity-platform` (inline today; URL hosts later for S3/API). Do **not** overload `infinity-cloudflare`.
5. **Phased automation (non-blocking):** P1 AWS Cost Explorer / CUR (respect `Project=` tags); P2 GitHub / Cloudflare billing where tokens allow; P3 keep subscription vendors manual unless APIs appear.
6. App grafana roots stay product-only; they must not recreate this folder/dashboard or `infinity-platform`.

## Consequences

- `shared-obs` scope expands beyond Infinity Cloudflare + GitHub plugin to: platform folder, cost dashboard, `infinity-platform`, `costs/monthly.json`.
- Spend figures in `costs/monthly.json` are committed (public repo). Treat as non-secret operational data; do not put tokens or invoices there.
- Docs / AGENTS “what lives where” must list platform costs under platform, not apps.

## See also

- [0001-shared-edge-and-obs.md](0001-shared-edge-and-obs.md)
- [architecture.md](../architecture.md)
- [`infra/terraform/shared-obs/README.md`](../../infra/terraform/shared-obs/README.md)
