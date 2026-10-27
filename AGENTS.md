# Agent definition of done — 7oas7er platform

This repo is the **shared platform** for isolated app repositories (Block Drop, Netrunner, …).

## Defaults

- Prefer **small diffs**. No drive-by refactors outside the task.
- **Apps must not depend on each other.** Shared zone/Grafana objects live here; apps consume them.
- App Cloudflare roots are DNS-only; do not move DNS into this repo without a new ADR.
- App Grafana dashboards/synthetics/CloudWatch stay in app repos; this repo owns Infinity + GitHub **plugin**, plus the platform **cost** folder/dashboard (EUR; live AWS Billing via Cloud Provider scrape — ADR 0002).
- **Terraform apply is local** — never add CI apply unless an ADR says so.
- Never commit `.tfstate`, `terraform.tfvars`, API tokens, or AWS keys.
- Tag AWS resources with `Project=platform` (and `Environment` as appropriate).

## GitHub workflow

- Feature work: branch → PR → **`staging`**. Promote via **`staging` → `main`** when asked.
- Do **not** push or merge unless Frank asks. Do **not** force-push protected branches.
- **Security floor** (public repo, Dependabot alerts, secret scanning + push protection, ruleset with **require signed commits**, read-only `GITHUB_TOKEN`): apply and API-verify per [`docs/github-branch-protection.md`](docs/github-branch-protection.md). Private Free GitHub cannot host rulesets — keep this repo **public** like the app templates. Signed commits are mandatory on `main`/`staging` (Frank’s GPG key `413A590799A3CF31AB2C9ECDE27E5FD506790203`).

## Definition of done

1. [ ] Change matches the request; no unrelated refactors.
2. [ ] Docs / ADR / README stay aligned with [docs/architecture.md](docs/architecture.md).
3. [ ] No secrets or state files staged.
4. [ ] If Terraform changed: remind Frank to `plan` / `apply` locally; warn about ForceNew on Cloudflare ruleset **names**.
5. [ ] If a new shared host is added: update `shared-edge` origin-verify + cache rules and tfvars.example.

## Explicit non-goals

- Hosting app site content or app-specific AWS site stacks here
- Second monitoring SaaS
- CI `terraform apply` by default
