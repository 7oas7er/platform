# IaC policy (Checkov)

CI job: Terraform plan → **IaC policy (Checkov)** on `infra/terraform/**`.  
Config: [`infra/terraform/.checkov.yaml`](../infra/terraform/.checkov.yaml).

Add skips sparingly with a one-line justification in `.checkov.yaml`. Prefer fixing the Terraform.
