# 7oas7er platform

Shared infrastructure for **isolated app repositories**. Apps (Block Drop, Netrunner, future products) each own their product and AWS site stack; this repo owns multi-tenant Cloudflare zone policy and shared Grafana Free objects.

**Architecture:** [docs/architecture.md](docs/architecture.md) · **ADRs:** [0001](docs/adr/0001-shared-edge-and-obs.md) · [0002 costs EUR](docs/adr/0002-platform-cost-dashboard.md) · **Agents:** [AGENTS.md](AGENTS.md) · **Security floor:** [docs/github-branch-protection.md](docs/github-branch-protection.md) · **Secrets:** [SECURITY.md](SECURITY.md)

Delivery matches the app template pattern: feature PRs → **`staging`**, promote **`staging` → `main`**. CI runs Terraform fmt/Checkov/validate and CodeQL on Actions; apply stays local.

```text
app repos ──► 7oas7er/platform   (never app ──► app)
```

| Root | Purpose |
|------|---------|
| [`infra/terraform/bootstrap`](infra/terraform/bootstrap/) | S3 state bucket for platform roots |
| [`infra/terraform/shared-edge`](infra/terraform/shared-edge/) | Zone rulesets: origin-verify, cache, redirects, rate-limit, SSL |
| [`infra/terraform/shared-obs`](infra/terraform/shared-obs/) | Shared Grafana Infinity DS + GitHub plugin + platform cost dashboard (EUR) |

**Apps own:** DNS CNAMEs, AWS site (S3/CloudFront/…), Grafana folder/dashboard/synthetics/CloudWatch/per-app GitHub DS, site CI deploy.

**Apps must not:** recreate zone rulesets, Infinity `infinity-cloudflare` / `infinity-platform`, the GitHub Cloud plugin, or the platform cost dashboard.

## Apply order (local)

```bash
export AWS_PROFILE=7oas7er   # or 7oas7er-terraform for aws login sessions
export CLOUDFLARE_API_TOKEN=…

cd infra/terraform/bootstrap && terraform init && terraform apply
cd ../shared-edge && cp terraform.tfvars.example terraform.tfvars   # fill secrets
terraform init && terraform apply
cd ../shared-obs && cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

One-time move from Block Drop state: [docs/MIGRATION.md](docs/MIGRATION.md).

Never commit `terraform.tfvars` or state files.
