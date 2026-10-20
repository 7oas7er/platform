# Agent definition of done — 7oas7er platform

This repo is the **shared platform** for isolated app repositories (Block Drop, Netrunner, …).

## Defaults

- Prefer **small diffs**. No drive-by refactors outside the task.
- **Apps must not depend on each other.** Shared zone/Grafana objects live here; apps consume them.
- App Cloudflare roots are DNS-only; do not move DNS into this repo without a new ADR.
- App Grafana dashboards/synthetics/CloudWatch stay in app repos; this repo owns Infinity + GitHub **plugin** only.
- **Terraform apply is local** — never add CI apply unless an ADR says so.
- Never commit `.tfstate`, `terraform.tfvars`, API tokens, or AWS keys.
- Tag AWS resources with `Project=platform` (and `Environment` as appropriate).

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
