# 0001 — Isolated apps + shared platform repository

- **Status:** accepted
- **Date:** 2026-10-21

## Context

Multiple public apps share zone `7oas7er.com` and one Grafana Cloud Free stack. Cloudflare allows **one zone ruleset per phase**. Putting those rulesets (and shared Infinity / GitHub plugin objects) inside a single app repo made sibling apps **implicitly depend** on that app — brittle for humans and agents.

## Decision

1. **Each app is its own GitHub repository** (product code, AWS site stack, DNS records, app Grafana dashboards/synthetics).
2. **Shared multi-tenant edge and observability objects** live in [`7oas7er/platform`](https://github.com/7oas7er/platform):
   - `infra/terraform/shared-edge` — origin-verify, cache, www/apex redirects, rate-limit, SSL
   - `infra/terraform/shared-obs` — Infinity DS `infinity-cloudflare`, GitHub catalog plugin (pinned); platform cost dashboard owned under ADR 0002
3. Dependency graph is **app → platform** only. **Never app → app.**
4. Apply stays local (same policy as app Terraform ADRs).

## Consequences

- New hostnames get origin-verify (and cache host rules) in **platform**, not in Block Drop or Netrunner.
- App Cloudflare Terraform roots must remain **DNS only** — never create competing zone rulesets.
- App Grafana roots must not create Infinity or install `grafana-github-datasource`.
- Cloning a new app from the template must include wiring to platform (secrets in `shared-edge`, zoneTag + GitHub DS in app grafana).
- Agents and docs must treat this split as a **fundamental** solo+AI platform choice, not an incidental refactor.

## See also

- [architecture.md](../architecture.md)
- App mirrors: Block Drop / Netrunner `docs/adr/0007-shared-edge-and-obs-platform.md`
