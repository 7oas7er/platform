# Architecture — apps + shared platform

## Principle

**Each public app is an isolated repository.** Shared multi-tenant infrastructure (one Cloudflare zone, one Grafana Cloud Free stack) lives in **`7oas7er/platform`**. Apps depend on the platform; **apps must not depend on each other**.

```text
                    ┌─────────────────────────┐
                    │   7oas7er/platform      │
                    │  shared-edge (CF zone)  │
                    │  shared-obs (Grafana)   │
                    └───────────┬─────────────┘
                                │
              ┌─────────────────┼─────────────────┐
              ▼                 ▼                 ▼
       ┌────────────┐    ┌────────────┐    ┌────────────┐
       │ block-drop │    │ netrunner  │    │  dressme   │
       │  (app)     │    │  (app)     │    │  (app)     │
       └────────────┘    └────────────┘    └────────────┘
```

## What lives where

| Concern | Owner |
|---------|--------|
| Zone rulesets (origin-verify, cache, redirects, rate-limit, SSL) | platform `shared-edge` |
| Shared Grafana Infinity DS + GitHub **plugin** | platform `shared-obs` |
| Platform cost overview (EUR; non-AWS feed + live AWS Billing metrics) | platform `shared-obs` |
| App DNS (host CNAMEs) | each app `infra/terraform/cloudflare` |
| App AWS (S3, CloudFront, IAM deploy/plan, Lambda…) | each app `infra/terraform/aws` |
| App Grafana (folder, dashboard, synthetics, CW scrape, per-app GitHub DS) | each app `infra/terraform/grafana` |
| Site content + CI deploy | each app repo |

## Same AWS account, separate tags

Apps may share one AWS account. Always tag taggable resources with `Project=<slug>` (`blockdrop`, `netrunner`, `dressme`, `platform`, …) plus `Environment` so Cost Explorer / console filters stay sane.

## New app checklist (platform-aware)

1. Clone / copy an app template (e.g. Block Drop); keep `app-*` Cursor rules.
2. Fresh Terraform state bucket/keys; never reuse another app’s state keys.
3. App Cloudflare root = **DNS only**; add origin-verify secrets for new hosts in platform `shared-edge`.
4. App Grafana = dashboards/synthetics/CW/GitHub DS only; do **not** recreate Infinity, the GitHub plugin, or the platform cost dashboard.
5. Document the app → platform dependency in the app’s ADR (mirror of platform ADR 0001).

Canonical decision records: [adr/0001-shared-edge-and-obs.md](adr/0001-shared-edge-and-obs.md), [adr/0002-platform-cost-dashboard.md](adr/0002-platform-cost-dashboard.md).
