# Maintenance

## Automation (already on)

| Tool | Scope | Cadence |
|------|--------|---------|
| [Dependabot](../.github/dependabot.yml) | GitHub Actions, Terraform providers (per root) | Weekly PRs → `staging` |
| CodeQL | Actions workflows | Path-filtered + weekly |
| Checkov | `infra/terraform/**` | On infra PRs |

## Weekly

```
[ ] Open Dependabot PRs on staging — merge when CI is green
[ ] Clear or explicitly waive high/critical Dependabot / code-scanning alerts
[ ] Glance Grafana Costs (EUR) / AWS scrape and shared synthetics health (optional)
```

## Monthly

```
[ ] Patch management — Terraform CLI+providers, Actions pins, Grafana plugin pins; prefer Dependabot
[ ] Documentation accuracy — architecture/ADRs/maintenance vs shared-edge/shared-obs reality
[ ] Confirm branch ruleset + CodeQL advanced setup + secret scanning / Dependabot alerts
    (docs/github-branch-protection.md verify commands)
[ ] Terraform CLI: if CI pin in terraform-plan.yml drifted from local, bump both
[ ] Terraform providers: review Dependabot PRs (or terraform init -upgrade per root)
[ ] AWS Project= tag audit for shared resources (expect Project=platform)
```
