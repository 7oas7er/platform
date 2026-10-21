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
```

## Monthly

```
[ ] Confirm branch ruleset + CodeQL advanced setup + secret scanning / Dependabot alerts
    (docs/github-branch-protection.md verify commands)
[ ] Terraform providers: review Dependabot PRs (or terraform init -upgrade per root)
```
