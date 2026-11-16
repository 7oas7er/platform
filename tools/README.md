# Platform tools

Helpers that live in this repo but are **not** Terraform. They contain **no secrets** — only CLI glue.

## Rotate Grafana GitHub PAT (local tfvars)

Frank uses one shared fine-grained GitHub PAT as `github_access_token` in each app’s local grafana tfvars. After rotating the PAT on GitHub, push the new value into those gitignored files:

```bash
cd /path/to/platform
./tools/rotate-grafana-github-token          # hidden prompt
# or non-interactive:
GRAFANA_GITHUB_TOKEN='…' ./tools/rotate-grafana-github-token
./tools/rotate-grafana-github-token --dry-run
```

Default roots: sibling checkouts next to this `platform` clone, else `~/SynologyDrive/private/devel/{dressme,block-drop,netrunner,homepage,fuboot-tours}`. Override with a positional `DEVEL_ROOT`, `GRAFANA_TFVARS_ROOTS` / `--roots`, or `GRAFANA_TFVARS_APPS`. See `./tools/rotate-grafana-github-token --help`.

Prints updated paths only (never the token). Does **not** apply Terraform and does **not** update the GitHub Environment secret `GRAFANA_GITHUB_TOKEN` used by CI — rotate that separately in GitHub Settings → Environments if plan CI needs the new PAT.

## Cloudflare Client-side security

Until the Cloudflare Terraform provider exposes a zone-level Page Shield enable
resource ([#7006](https://github.com/cloudflare/terraform-provider-cloudflare/issues/7006)),
turn on Free continuous script monitoring with:

```bash
export CLOUDFLARE_API_TOKEN=…   # needs Page Shield or Zone Settings Write
./tools/enable-client-side-security
```

Optional: `CLOUDFLARE_ZONE_ID` (defaults to `7oas7er.com`). Run after
`shared-edge` apply; the call is idempotent.

## Bitwarden ↔ `terraform.tfvars`

Import local gitignored `terraform.tfvars` into Bitwarden, or recreate those files on a new machine from Secure Notes.

| Script | Role |
|--------|------|
| [`bw-import-tfvars`](bw-import-tfvars) | Disk → Bitwarden (Secure Notes + hidden custom fields) |
| [`bw-export-tfvars`](bw-export-tfvars) | Bitwarden → disk (`terraform.tfvars` under devel roots) |

**Collection:** `7oas7er-terraform` (override with `BW_TFVARS_COLLECTION`).

**Item name:** `{project} / {relative/path}` — e.g. `homepage / aws/envs/stg` → `…/devel/homepage/aws/envs/stg/terraform.tfvars`.

### Unlock (once per shell)

```bash
brew install bitwarden-cli   # once per Mac
bw login                     # if needed
export BW_SESSION="$(bw unlock --raw)"
bw sync
```

### Workflow

```bash
# From a clone of this repo (or PATH that includes tools/)
cd /path/to/platform

# 1) Import existing local tfvars into Bitwarden (skip-if-exists)
./tools/bw-import-tfvars --dry-run
./tools/bw-import-tfvars

# 2) On another Mac: recreate files (skip existing unless --force)
./tools/bw-export-tfvars --dry-run
./tools/bw-export-tfvars
./tools/bw-export-tfvars --force   # only when you intend to overwrite
```

Default devel root: `~/SynologyDrive/private/devel`. Pass another root as the first positional argument.

Neither script prints secret field values (status lines are names/paths/counts only). Do not paste `terraform.tfvars` contents into chat.

### Limits

- Simple `key = "value"` lines only (same style as current tfvars). Maps/lists need a one-off.
- Import skips items that already exist — delete the Bitwarden item to re-import.
- Export skips existing files unless `--force`.
