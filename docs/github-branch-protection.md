# GitHub branch protection and security floor

Target branches: **`staging`** and **`main`**. Default branch must be **`main`**.

**Hard rule:** copying workflows / docs does **not** configure GitHub. Apply Settings with `gh` and **verify via API**. This repo (**platform**) stays **public** on GitHub Free so rulesets and GitHub-native scanners match Block Drop.

## Scanners by visibility (shared guidance)

Scanner choice follows **repo visibility**, not “match Block Drop blindly”:

| Visibility | Secrets | SAST | Notes |
|------------|---------|------|--------|
| **Public** | GitHub **secret scanning** + **push protection** | In-repo **CodeQL** (advanced setup; default setup **off**) | Platform, Block Drop, and other public apps |
| **Private** (no GHAS) | **gitleaks** inside Required CI | **Semgrep CE** inside Required CI | Do **not** buy GHAS solely for native private scanning unless Frank decides otherwise. Reference: [`7oas7er/long-way-home`](https://github.com/7oas7er/long-way-home) → [`docs/private-repo-github-floor.md`](https://github.com/7oas7er/long-way-home/blob/staging/docs/private-repo-github-floor.md) |

**Platform is public** — keep GitHub-native secret scanning / push protection / CodeQL. Do **not** add gitleaks or Semgrep to this repo’s Required CI.

Private apps still share the same ruleset / Dependabot / Actions-token floor where Pro unlocks it; only the **scanner mechanism** forks. Full private Settings path (Pro rulesets, admin `gh`, Free classic fallback): long-way-home’s private-repo floor doc above.

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
5. Require signed commits — on (verified GPG; Frank’s key `413A590799A3CF31AB2C9ECDE27E5FD506790203` / `frank@schlesinger.com`)  

## Repo security floor (this repo — public)

| Control | Expected |
|---------|----------|
| Visibility | **Public** (GitHub Free) |
| Default branch | **`main`** |
| Dependabot **alerts** | **Enabled** |
| Secret scanning + push protection | **Enabled** (GitHub-native; public path) |
| CodeQL **advanced** / **default** setup | Advanced **on** (Actions); default **off** |
| Branch ruleset `default` | **Active** on `main` + `staging` (incl. **require signed commits**) |
| Actions `GITHUB_TOKEN` | **Read**; cannot approve PRs |
| Issues / Wiki / Projects | **Off** |
| gitleaks / Semgrep in Required CI | **No** — public → GitHub-native scanners |

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

Verify: Dependabot alerts HTTP 204, `security_and_analysis.secret_scanning.status=enabled`, ruleset active on `main`+`staging` with `required_signatures` in rules.
