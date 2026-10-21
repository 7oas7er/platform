# CodeQL (SAST)

Workflow: [`.github/workflows/codeql.yml`](../.github/workflows/codeql.yml)  
Config: [`.github/codeql/codeql-config.yml`](../.github/codeql/codeql-config.yml)

In-repo **advanced** setup. GitHub **default** code scanning setup must stay **off**.

| Language pack | Paths |
|---------------|--------|
| `actions` | `.github/workflows/**` |

Terraform is covered by Checkov (`docs/iac-policy.md`), not CodeQL.
