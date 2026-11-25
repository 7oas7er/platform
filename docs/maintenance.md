# Maintenance

## Automation (already on)

| Tool | Scope | Cadence |
|------|--------|---------|
| [Dependabot](../.github/dependabot.yml) | GitHub Actions, Terraform providers (per root) | Weekly PRs → `staging` |
| CodeQL | Actions workflows (public-repo SAST path) | Path-filtered + weekly |
| Secret scanning + push protection | GitHub-native (public path) | Continuous |
| Checkov | `infra/terraform/**` | On infra PRs |

**Visibility fork:** this repo is **public** → GitHub secret scanning + push protection + CodeQL. **Private** apps (no GHAS) use **gitleaks** + **Semgrep CE** in Required CI instead — see [`github-branch-protection.md`](github-branch-protection.md) and [`7oas7er/long-way-home` `docs/private-repo-github-floor.md`](https://github.com/7oas7er/long-way-home/blob/staging/docs/private-repo-github-floor.md). Do not add gitleaks/Semgrep here while platform stays public.

## Weekly

```
[ ] Open Dependabot PRs on staging — merge when CI is green
[ ] Clear or explicitly waive high/critical Dependabot / code-scanning alerts
[ ] Glance Grafana Costs (EUR) / AWS scrape and shared synthetics health (optional)
[ ] Adaptive Metrics: Auto-apply still OFF; only DROP unused probe_/lambda_/unused CloudFront series (shared-obs README)
```

## Monthly

```
[ ] Patch management — Terraform CLI+providers, Actions pins, Grafana plugin pins; prefer Dependabot
[ ] Documentation accuracy — architecture/ADRs/maintenance vs shared-edge/shared-obs reality
[ ] Confirm branch ruleset + Dependabot alerts + scanners for this visibility
    (public: CodeQL advanced + secret scanning / push protection — docs/github-branch-protection.md;
    private apps: gitleaks + Semgrep CE in Required CI per long-way-home private-repo floor)
[ ] Terraform CLI: if CI pin in terraform-plan.yml drifted from local, bump both
[ ] Terraform providers: review Dependabot PRs (or terraform init -upgrade per root)
[ ] AWS Project= tag audit for shared resources (expect Project=platform)
```
