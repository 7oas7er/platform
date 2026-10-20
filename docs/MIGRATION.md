# Migrate Block Drop → platform (one-time)

Do this **before** merging app PRs that strip rulesets / Infinity from Block Drop, or live edge config will be destroyed.

## 1. Bootstrap platform state bucket

```bash
export AWS_PROFILE=7oas7er
cd infra/terraform/bootstrap
terraform init -reconfigure
terraform apply
```

## 2. shared-edge — import existing rulesets

```bash
export CLOUDFLARE_API_TOKEN=…
cd ../shared-edge
cp terraform.tfvars.example terraform.tfvars
# Map from Block Drop cloudflare terraform.tfvars:
#   stg_origin_verify_secret      → blockdrop_stg_origin_verify_secret
#   prod_origin_verify_secret     → blockdrop_prod_origin_verify_secret
#   netrunner_stg_origin_verify_secret → netrunner_stg_origin_verify_secret
#   netrunner_prod_origin_verify_secret → netrunner_prod_origin_verify_secret
terraform init
```

Import IDs (Cloudflare provider **v5** needs the `zones/` prefix — not bare `zone_id/ruleset_id`):

```bash
ZONE=701810fff825f90c0eea671970a0cc9e
terraform import cloudflare_ruleset.origin_verify "zones/${ZONE}/9a0540dbe98b4421b3784787f055db2d"
terraform import cloudflare_ruleset.cache "zones/${ZONE}/69cc6ed866f946658be4d6a6a13b540b"
terraform import cloudflare_ruleset.redirects "zones/${ZONE}/ddb6636b089a4f1a8d0856da7890b470"
terraform import cloudflare_ruleset.rate_limit "zones/${ZONE}/baee8dfa55564c45997beaea46005185"
# zone_setting uses bare zone_id/setting_id (no zones/ prefix — unlike rulesets)
terraform import cloudflare_zone_setting.ssl "${ZONE}/ssl"
terraform plan
# Expect **no** destroy/replace. If you see -/+ on rulesets, a `name` change is
# ForceNew — keep the live Cloudflare ruleset names (do not rename to "7oas7er …").
terraform apply   # only if plan is empty or in-place-only (no -/+ rulesets)
```

## 3. Remove from Block Drop state (do not destroy)

In `7oas7er/block-drop` → `infra/terraform/cloudflare`:

```bash
terraform state rm \
  cloudflare_ruleset.origin_verify \
  cloudflare_ruleset.cache \
  cloudflare_ruleset.redirects \
  cloudflare_ruleset.rate_limit \
  cloudflare_zone_setting.ssl
terraform plan   # DNS only remaining
terraform apply  # after DNS-only code is merged
```

## 4. shared-obs — import Infinity + GitHub plugin

The plugin resource has **no** `count` (address is `.github`, not `.github[0]`).
The stack provider needs `stack_service_account_token` in tfvars up front (cannot
depend on the token resource — that blocks import). Bootstrap with any Admin stack
SA token, then switch to `platform-terraform` after it is created.

```bash
cd ../shared-obs
cp terraform.tfvars.example terraform.tfvars
# Fill stack_slug, cloud_access_policy_token, cloudflare_analytics_token,
# and stack_service_account_token (temporarily: Block Drop's stack SA token is fine).
terraform init

# 1) Create platform-terraform SA + token (cloud provider only)
terraform apply \
  -target=grafana_cloud_stack_service_account.terraform \
  -target=grafana_cloud_stack_service_account_token.terraform

# 2) Put the new token in tfvars (replace the temporary one)
terraform output -raw stack_service_account_token
# → stack_service_account_token = "…" in terraform.tfvars

# 3) Import shared objects (no [0] on the plugin)
terraform import grafana_cloud_plugin_installation.github \
  joyfulraspberry90:grafana-github-datasource
terraform import grafana_data_source.cloudflare_infinity \
  '1:infinity-cloudflare'

terraform plan   # expect empty / trivial; must NOT create Infinity or reinstall plugin
terraform apply
```

In Block Drop `infra/terraform/grafana` after shared-obs owns them:

```bash
terraform state rm 'grafana_data_source.cloudflare_infinity[0]'
terraform state rm 'grafana_cloud_plugin_installation.github[0]'
# Then merge code that stops managing those resources; plan should be clean.
```

## 5. App docs

Point Netrunner / Block Drop Cloudflare + Grafana READMEs at this repo (already updated in app PRs).
