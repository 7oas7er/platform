# Platform state bootstrap

Creates `shared-7oas7er-platform-terraform-state-bucket` (override via `state_bucket_name`).

Uses a **local** backend so the first apply does not need the bucket it creates.

```bash
export AWS_PROFILE=7oas7er-terraform
terraform init -reconfigure
terraform apply
```
