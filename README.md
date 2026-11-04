# 7oas7er platform

Shared infrastructure for **isolated app repositories**. Apps (Block Drop, Netrunner, future products) each own their product and AWS site stack; this repo owns multi-tenant Cloudflare zone policy and shared Grafana Free objects.

**Architecture:** [docs/architecture.md](docs/architecture.md) · **ADRs:** [0001](docs/adr/0001-shared-edge-and-obs.md) · [0002 costs EUR](docs/adr/0002-platform-cost-dashboard.md) · **Agents:** [AGENTS.md](AGENTS.md) · **Security floor:** [docs/github-branch-protection.md](docs/github-branch-protection.md) · **Secrets:** [SECURITY.md](SECURITY.md) · **Maintenance:** [docs/maintenance.md](docs/maintenance.md) · **IaC policy:** [docs/iac-policy.md](docs/iac-policy.md) · **CodeQL:** [docs/codeql.md](docs/codeql.md) · **Tools:** [tools/](tools/) (Bitwarden tfvars helpers — no secrets in scripts)

```text
app repos ──► 7oas7er/platform   (never app ──► app)
```

## Layout

| Path | Role |
|------|------|
| [`infra/terraform/bootstrap`](infra/terraform/bootstrap/) | S3 state bucket for platform Terraform roots |
| [`infra/terraform/shared-edge`](infra/terraform/shared-edge/) | Zone rulesets: origin-verify, cache, redirects, rate-limit, SSL/HTTPS/HSTS/DNSSEC, Free security toggles |
| [`infra/terraform/shared-obs`](infra/terraform/shared-obs/) | Shared Grafana Infinity DS + GitHub plugin + platform cost dashboard (EUR) |
| [`tools/`](tools/) | Non-TF helpers (Client-side security enable; Bitwarden ↔ tfvars) — see [`tools/README.md`](tools/README.md) |
| [`.cursor/rules/`](.cursor/rules/) | Platform Cursor rules (`platform-core`) |
| [`AGENTS.md`](AGENTS.md) | Definition of done for AI-assisted changes |
| [`docs/architecture.md`](docs/architecture.md) | App vs shared-platform ownership |
| [`docs/`](docs/) | ADRs, migration notes, maintenance, security-floor docs |
| [`SECURITY.md`](SECURITY.md) | Reporting + secret leak / rotation pointers |

**Apps own:** DNS CNAMEs, AWS site (S3/CloudFront/…), Grafana folder/dashboard/synthetics/CloudWatch/per-app GitHub DS, site CI deploy.

**Apps must not:** recreate zone rulesets, Infinity `infinity-cloudflare` / `infinity-platform`, the GitHub Cloud plugin, or the platform cost dashboard.

## Environments

- Feature work → PR into **`staging`**.
- Promote platform config by merging **`staging` → `main`** when asked.
- This is **not an app**: there is no site deploy to AWS stg/prod and no GitHub Environments for buckets/distributions. Changes here are shared-edge / shared-obs / bootstrap Terraform (local apply).

## CI/CD

| Workflow | What it does |
|----------|----------------|
| [`.github/workflows/terraform-plan.yml`](.github/workflows/terraform-plan.yml) | `fmt` / **Checkov** / `validate` for changed Terraform roots. **Never applies.** (OIDC remote plan is a later add.) |
| [`.github/workflows/required-ci.yml`](.github/workflows/required-ci.yml) | Always-on PR check (`Required CI`) for branch rulesets |
| [`.github/workflows/codeql.yml`](.github/workflows/codeql.yml) | CodeQL SAST for Actions workflows |

No site-deploy workflow in this repo (apps own their deploy pipelines). Dependabot opens weekly PRs to `staging` for Actions and **Terraform providers** (per root). Ongoing cadence: [`docs/maintenance.md`](docs/maintenance.md). Branch rules: [`docs/github-branch-protection.md`](docs/github-branch-protection.md). Checkov: [`docs/iac-policy.md`](docs/iac-policy.md). CodeQL: [`docs/codeql.md`](docs/codeql.md).

## Terraform (local apply)

Apply stays on your machine. Typical profile:

```bash
export AWS_PROFILE=7oas7er   # or 7oas7er-terraform for aws login sessions
export CLOUDFLARE_API_TOKEN=…
```

Apply order:

```bash
cd infra/terraform/bootstrap && terraform init && terraform apply
cd ../shared-edge && cp terraform.tfvars.example terraform.tfvars   # fill secrets
terraform init && terraform apply
# Client-side security (Page Shield) — no TF resource yet
../../../tools/enable-client-side-security
cd ../shared-obs && cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

Roots (separate state):

- `infra/terraform/bootstrap`
- `infra/terraform/shared-edge`
- `infra/terraform/shared-obs`

Never commit `.tfstate`, `terraform.tfvars`, API tokens, or AWS keys. Setup notes:

- [Architecture](docs/architecture.md)
- [shared-edge README](infra/terraform/shared-edge/README.md)
- [shared-obs README](infra/terraform/shared-obs/README.md)
- [bootstrap README](infra/terraform/bootstrap/README.md)
- One-time move from Block Drop state: [docs/MIGRATION.md](docs/MIGRATION.md)

Warn: renaming Cloudflare ruleset **names** is ForceNew — plan carefully before apply.

## Observability

**Grafana Cloud Free** only. This repo’s `shared-obs` owns:

- Infinity DS `infinity-cloudflare` and `infinity-platform`
- Catalog plugin `grafana-github-datasource`
- Platform folder + **Platform — Costs (EUR)** dashboard (live AWS Billing via Cloud Provider scrape — [ADR 0002](docs/adr/0002-platform-cost-dashboard.md))

Apps own their folder/dashboards/synthetics/CloudWatch scrape/per-app GitHub DS. Do not add a second monitoring SaaS. Cloudflare remains DNS/edge (plus analytics pulled into Grafana)—not an APM product.

## Security Principles

- Public traffic for apps must arrive via **Cloudflare**; direct origin (CloudFront URL, etc.) is rejected by platform `shared-edge` origin-verify rules.
- Secrets live in gitignored tfvars, env vars, or Bitwarden (via [`tools/`](tools/))—not in git.
- Reporting and leak response: [`SECURITY.md`](SECURITY.md). Durable “why” for stack choices: [`docs/adr/`](docs/adr/).

## Local development

No app site or test suite lives here. Day-to-day work is Terraform + the helpers under [`tools/`](tools/).

```bash
# Format check (same gate as CI)
terraform fmt -check -recursive infra/terraform

# Per-root validate (after init -backend=false, as CI does)
cd infra/terraform/shared-edge && terraform init -backend=false && terraform validate
```

Client-side security companion and Bitwarden tfvars import/export: [`tools/README.md`](tools/README.md).

## Working with Cursor / agents

Follow [`AGENTS.md`](AGENTS.md) and [`.cursor/rules/`](.cursor/rules/). Prefer small diffs; keep docs/ADRs aligned with [docs/architecture.md](docs/architecture.md). Do not host app site content or app AWS stacks here. Decisions: [`docs/adr/`](docs/adr/).
