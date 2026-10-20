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
# Copy secrets from Block Drop cloudflare terraform.tfvars (all four origin-verify vars)
terraform init
```

Import IDs (zone `701810fff825f90c0eea671970a0cc9e`):

```bash
ZONE=701810fff825f90c0eea671970a0cc9e
terraform import cloudflare_ruleset.origin_verify ${ZONE}/9a0540dbe98b4421b3784787f055db2d
terraform import cloudflare_ruleset.cache ${ZONE}/69cc6ed866f946658be4d6a6a13b540b
terraform import cloudflare_ruleset.redirects ${ZONE}/ddb6636b089a4f1a8d0856da7890b470
terraform import cloudflare_ruleset.rate_limit ${ZONE}/baee8dfa55564c45997beaea46005185
terraform import cloudflare_zone_setting.ssl ${ZONE}/ssl
terraform plan   # expect no destroy of rules; rename/description updates OK
terraform apply
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

```bash
cd ../shared-obs
cp terraform.tfvars.example terraform.tfvars   # stack_slug, tokens, CF analytics token
terraform init
```

After stack SA exists (first apply may create SA then import DS), or import DS by uid once SA/auth works:

```bash
# Plugin (pin matches live install)
terraform import 'grafana_cloud_plugin_installation.github[0]' joyfulraspberry90:grafana-github-datasource

# Infinity DS uid (provider id form is typically <orgId>:<uid> — confirm with grafana provider docs / state from Block Drop)
# From Block Drop grafana state before rm:
#   terraform state show 'grafana_data_source.cloudflare_infinity[0]'
terraform import 'grafana_data_source.cloudflare_infinity[0]' '<id-from-block-drop-state>'
```

In Block Drop `infra/terraform/grafana` after shared-obs owns them:

```bash
terraform state rm 'grafana_data_source.cloudflare_infinity[0]'
terraform state rm 'grafana_cloud_plugin_installation.github[0]'
# Then merge code that stops managing those resources; plan should be clean.
```

## 5. App docs

Point Netrunner / Block Drop Cloudflare + Grafana READMEs at this repo (already updated in app PRs).
