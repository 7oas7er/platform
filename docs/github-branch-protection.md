# GitHub branch protection and security floor

Target branches: **`staging`** and **`main`**. Default branch must be **`main`**.

**Hard rule:** copying workflows / docs does **not** configure GitHub. Apply Settings with `gh` and **verify via API**. This repo must stay **public** on GitHub Free so rulesets, secret scanning, and Code scanning match Block Drop (private Free cannot enable rulesets).

## Hard-required check

| Check name | Workflow | Why |
|------------|----------|-----|
| `Required CI` | [`.github/workflows/required-ci.yml`](../.github/workflows/required-ci.yml) | Always reports on PRs to `staging`/`main` |

## Path-filtered checks

| Check name | Workflow | When it runs |
|------------|----------|--------------|
| `Format` | Terraform plan | `infra/terraform/**` or that workflow |
| `IaC policy (Checkov)` | Terraform plan | same |
| `Analyze (actions)` | CodeQL | workflows / `.github/codeql/**` |

**Process:** open **high/critical** Dependabot alerts on `staging`/`main` are merge blockers. Weekly Dependabot PRs target `staging`.

## Ruleset settings

One ruleset on `refs/heads/staging` and `refs/heads/main`:

1. Restrict deletions — on  
2. Block force pushes — on  
3. Require a pull request before merging — on (0 approvals while solo)  
4. Require status checks — **`Required CI`** only  

## Repo security floor (must match Block Drop)

| Control | Expected |
|---------|----------|
| Visibility | **Public** (GitHub Free) |
| Default branch | **`main`** |
| Dependabot **alerts** | **Enabled** |
| Secret scanning + push protection | **Enabled** |
| CodeQL **default** setup | **Off** |
| Branch ruleset `default` | **Active** on `main` + `staging` |
| Actions `GITHUB_TOKEN` | **Read**; cannot approve PRs |
| Issues / Wiki / Projects | **Off** |

## Apply / verify via `gh`

```bash
REPO=7oas7er/platform

gh api -X PATCH "repos/$REPO" -f private=false -F has_issues=false -F has_wiki=false -F has_projects=false
gh api -X PUT "repos/$REPO/vulnerability-alerts"
gh api -X PATCH "repos/$REPO" --input - <<'EOF'
{
  "security_and_analysis": {
    "secret_scanning": { "status": "enabled" },
    "secret_scanning_push_protection": { "status": "enabled" }
  }
}
EOF
gh api -X PUT "repos/$REPO/actions/permissions/workflow" \
  -f default_workflow_permissions=read \
  -F can_approve_pull_request_reviews=false

# Create ruleset once (see block-drop docs/github-branch-protection.md for full JSON)
gh api repos/$REPO/rulesets --jq '.[] | {id,name,enforcement}'
```

Verify: Dependabot alerts HTTP 204, `security_and_analysis.secret_scanning.status=enabled`, ruleset active on `main`+`staging`.
