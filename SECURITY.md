# Security

## Reporting

This is the shared platform repo (Cloudflare zone policy + Grafana Free shared objects). If you find a vulnerability in edge config or shared observability:

1. Contact Frank (repo owner) directly — do not open a public issue with exploit detail.
2. Include rough impact and steps to reproduce if safe.

There is no bug bounty.

## Secrets — never commit

Do not commit `.tfstate`, `terraform.tfvars`, API tokens, AWS keys, Grafana tokens, Cloudflare tokens, origin-verify secrets, or GitHub PATs. Prefer gitignored tfvars, GitHub Environment secrets/vars, or shell env vars.

## If a secret leaks

Act fast; assume compromise until rotated.

| Secret | What to do |
|--------|------------|
| **Origin-verify** (per-app hosts in `shared-edge`) | Rotate via the app’s dual-accept AWS flow, then update platform `shared-edge` tfvars and apply. |
| **Cloudflare API token** | Revoke in Cloudflare → create replacement → update local gitignored tfvars / env used for `shared-edge` apply. |
| **Grafana** (`GRAFANA_*` / tokens in `shared-obs` tfvars) | Revoke/rotate in Grafana Cloud → update gitignored tfvars → `terraform plan` in `shared-obs`. |
| **AWS** (unusual — prefer profile `7oas7er`) | Deactivate key → prefer OIDC/profile for any future CI plan role. |

## Related

- Architecture: [`docs/architecture.md`](docs/architecture.md)
- Branch protection / security floor: [`docs/github-branch-protection.md`](docs/github-branch-protection.md)
- IaC policy: [`docs/iac-policy.md`](docs/iac-policy.md)
- CodeQL: [`docs/codeql.md`](docs/codeql.md)
