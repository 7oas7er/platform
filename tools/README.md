# Platform tools

Helpers that live in this repo but are **not** Terraform. They contain **no secrets** — only CLI glue.

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
