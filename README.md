# 7oas7er platform (shared edge + observability)

Explicit **platform** layer for apps that share zone `7oas7er.com` and one Grafana Cloud Free stack. Apps (Block Drop, Netrunner) depend on this repo — they must **not** depend on each other.

| Root | Purpose |
|------|---------|
| [`infra/terraform/bootstrap`](infra/terraform/bootstrap/) | S3 state bucket for platform roots (local backend on first apply) |
| [`infra/terraform/shared-edge`](infra/terraform/shared-edge/) | Zone rulesets: origin-verify, cache, redirects, rate-limit, SSL |
| [`infra/terraform/shared-obs`](infra/terraform/shared-obs/) | Shared Grafana Infinity DS + GitHub plugin |

App Cloudflare roots: **DNS only**. App Grafana roots: dashboards, synthetics, CloudWatch scrape, per-app GitHub data sources.

See [docs/adr/0001-shared-edge-and-obs.md](docs/adr/0001-shared-edge-and-obs.md) and [docs/MIGRATION.md](docs/MIGRATION.md).

## Apply order (local)

```bash
export AWS_PROFILE=7oas7er   # or 7oas7er-terraform if using aws login sessions
export CLOUDFLARE_API_TOKEN=…

cd infra/terraform/bootstrap && terraform init && terraform apply
cd ../shared-edge && cp terraform.tfvars.example terraform.tfvars   # fill secrets
terraform init && terraform apply
cd ../shared-obs && cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

Never commit `terraform.tfvars` or state files.
