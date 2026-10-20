# 0001 — Shared edge and observability platform

- **Status:** accepted
- **Date:** 2026-10-21

## Context

Multiple public apps on zone `7oas7er.com` and one Grafana Cloud Free stack. Cloudflare allows **one zone ruleset per phase**. Putting origin-verify / cache rules (and shared Infinity / GitHub plugin) inside a single app repo made sibling apps implicitly depend on that app.

## Decision

Own shared zone policy and shared Grafana stack objects in this **platform** repository:

- `infra/terraform/shared-edge` — origin-verify, cache, zone SSL, www/apex redirects, Block Drop `/api/scores` rate limit
- `infra/terraform/shared-obs` — Infinity DS `infinity-cloudflare`, GitHub catalog plugin (pinned version)

App repos manage only app DNS, app Grafana dashboards/synthetics/CloudWatch/per-app GitHub DS, and AWS.

## Consequences

- Dependency graph is **app → platform**, never app → app.
- Agents must not recreate zone rulesets or Infinity / GitHub plugin installs inside app Terraform roots.
- New app hostnames get origin-verify rules in `shared-edge`, not in Block Drop or Netrunner.
- Apply stays local (same as app ADRs for Terraform apply).
