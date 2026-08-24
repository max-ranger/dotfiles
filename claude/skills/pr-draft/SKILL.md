---
name: pr-draft
description: Use when the user wants to create a pull request, generate a PR description, write a draft PR, or asks for /pr-draft or /pr. Analyzes branch diff and commits to produce a filled PR and creates a draft PR via gh CLI (GitHub) or az repos (Azure DevOps).
---

# Draft PR Creator

Generate a complete PR description from the current branch's changes and create a draft PR via `gh` (GitHub) or `az repos` (Azure DevOps) — whichever the remote calls for.

## Trigger

User says `/pr-draft`, `/pr`, "create a PR", "write a PR", or similar.

## Process

Follow these steps exactly. Do NOT skip steps or reorder.

### Step 1: Gather context

Run these commands in parallel:

```bash
# Detect the branch this was forked from (parent branch)
# Try git log to find the merge-base with common branches
git branch --show-current

# Find the parent branch: check which branch this was created from
# by finding the nearest common ancestor among remote branches
git log --oneline --decorate --simplify-by-decoration HEAD | head -20

# Diff stats (determined after base branch is found)
# Full diff (determined after base branch is found)
# Commit log (determined after base branch is found)

# Detect remote host (GitHub vs Azure DevOps) — drives which CLI Step 4 uses
git remote get-url origin 2>/dev/null

# Check gh CLI (GitHub)
command -v gh 2>/dev/null || where gh 2>/dev/null && echo "gh available" || echo "gh not available"

# Check az CLI + azure-devops extension (Azure DevOps)
command -v az 2>/dev/null && az extension show --name azure-devops >/dev/null 2>&1 && echo "az devops available" || echo "az devops not available"

# Check if branch is pushed
git rev-parse --abbrev-ref @{upstream} 2>/dev/null && echo "tracking" || echo "not tracking"
```

**Remote host detection:** inspect the `origin` URL from above.
- Contains `github.com` → **GitHub**.
- Contains `dev.azure.com` or `visualstudio.com` → **Azure DevOps**. Parse organization/project/repository out of it — both remote formats appear in the wild:
  - SSH: `git@ssh.dev.azure.com:v3/<org>/<project>/<repo>` (URL-decode `%20` in `<project>` back to spaces)
  - HTTPS: `https://dev.azure.com/<org>/<project>/_git/<repo>`

**Base branch detection (priority order):**

1. Find the branch this was forked from using `git merge-base`:
   ```bash
   # For each candidate: develop, main, master — find the one with the closest merge-base
   for branch in develop main master; do
     git merge-base HEAD $branch 2>/dev/null
   done
   ```
   Pick the candidate whose merge-base is closest to HEAD (fewest commits between merge-base and HEAD). This is the true parent branch.

2. If the parent branch has been deleted or merged, fall back to `develop`.
3. If `develop` doesn't exist, fall back to `main`, then `master`.

Once base branch is determined, run:
```bash
git diff <base>...HEAD --stat
git diff <base>...HEAD
git log <base>..HEAD --oneline
```

### Step 2: Extract ticket and classify

**Branch pattern:** `<type>/<ticket>/<slug>` or `<type>/<slug>`

**Type mapping:**
| Branch prefix | PR type |
|---|---|
| `feature/` | Feature |
| `feat/` | Feature |
| `fix/` | Fix |
| `bugfix/` | Fix |
| `hotfix/` | Hotfix |
| `refactor/` | Refactor |
| `chore/` | Chore |
| `docs/` | Docs |
| Anything else | Change |

**Ticket extraction:**
- Look at the second path segment for patterns like `AP-123`, `JIRA-456`, `#abc123`, or any `LETTERS-DIGITS` / `#alphanumeric` pattern
- If found: ticket number (e.g., `AP-348`)
- If not found: no ticket number

**Title generation — the format depends on the remote host detected in Step 1.**

*GitHub:*
- With ticket: `<emoji> <Type> #<ticket>: <descriptive title from changes>`
- Without ticket: `<emoji> <Type>: <descriptive title from changes>`

*Azure DevOps* — ticket number **first**, type in parentheses, and **no emoji** (Azure DevOps does not render them):
- With ticket: `<TICKET> (<type>): <descriptive title from changes>`
  - e.g. `GDS-991 (chore): bump Testcontainers to 4.14.0`
  - e.g. `GDS-966 (feature): audit SDK 0.1.0.29 + ambient correlation scope`
- Without ticket: `(<type>): <descriptive title from changes>`
- `<type>` is **lowercase**: `feature`, `fix`, `hotfix`, `refactor`, `chore`, `docs`, `change`

Both hosts:
- The descriptive title should be derived from the actual changes (commits + diff), not just the branch slug
- Keep under 70 characters

**Type emoji mapping (GitHub only — never use emoji in Azure DevOps titles or bodies):**
| Type | Emoji |
|---|---|
| Feature | 🚀 |
| Fix | 🐛 |
| Hotfix | 🩹 |
| Refactor | ♻️ |
| Chore | 🧹 |
| Docs | 📝 |
| Change | 🏗️ |

### Step 3: Generate PR body

**Select the template that matches the PR type from Step 2, then fill it from the diff and commits.** Each template has its own sections, icons, and layout tuned to that kind of change — do not force every PR into the feature shape.

| PR type (from Step 2) | Template file |
|---|---|
| Feature | `templates/feature.md` |
| Fix | `templates/bugfix.md` |
| Hotfix | `templates/hotfix.md` |
| Refactor | `templates/refactor.md` |
| Chore | `templates/chore.md` |
| Docs | `templates/feature.md` (trim to Description + Highlights) |
| Change (fallback) | `templates/feature.md` |

Read the chosen template file and use the fenced ```markdown block inside it as the body structure. Replace every `<…>` placeholder with real content derived from the actual changes; delete any section a template marks as optional when it doesn't apply.

**Rules for generating content (apply to whichever template is used):**
- Focus on the WHY, not just the WHAT.
- Every bullet is concrete and specific to the diff — no filler or generic boilerplate.
- Testing/verification steps are actionable and tied to what actually changed.
- Dependencies: check the package manifest diff (package.json, pubspec.yaml, *.csproj, etc.) for new/updated deps.
- Breaking changes / risk: check for removed or renamed exports, changed signatures, and API changes.
- **Unfillable sections:** when the diff and commits genuinely can't supply a section (e.g. before/after screenshots, or reproduction steps that need runtime state), keep the section and fill it with `_to be added_` — do not delete a non-optional section, and do not invent details. Only delete sections a template explicitly marks as optional (e.g. the chore Dependency Updates table when no deps changed).
- **Fix vs Hotfix tie-breaker:** default a `fix/`/`bugfix/` branch to the bugfix template. Use hotfix only when there is an explicit production-incident signal — the branch is `hotfix/`, the commits/PR reference an incident or Sev level, or the user says it's an urgent production fix. Absent such a signal, stay with bugfix. Mention the choice when reporting so the user can correct a mislabeled branch.

### Step 4: Create the PR

Use the remote host detected in Step 1.

**GitHub, `gh` available:**

```bash
# Push branch if not tracking remote
git push -u origin <branch>

# Create draft PR targeting the detected base branch.
# The <title> goes ONLY in --title (GitHub renders it as the PR title). The body
# starts directly at the first section — do NOT repeat the title as an H1 in the body.
gh pr create --draft --base <base-branch> --title "<title>" --body "$(cat <<'EOF'
<filled template body from Step 3 — starts with the first section, no title H1>
EOF
)"
```

Report the draft PR URL to the user.

**Azure DevOps, `az` available with the `azure-devops` extension:**

Four constraints, each verified the hard way — read these *before* composing the body:

1. **`description` is hard-capped at 4000 characters.** 4000 succeeds; 4001 returns `400 Bad Request`.
   Compose to fit. If the content genuinely needs more, keep the description reviewer-facing and put
   only reviewer-relevant overflow (detailed test steps, breaking changes) in the PR's first comment
   thread — ticket-level narrative belongs in the ticket, not the PR.
2. **Some typographic characters are rejected** in `title` and `description` with an unhelpful 400 —
   em dashes, en dashes and curly quotes among them. ASCII-fold before sending: `—`/`–` → `-`,
   curly quotes → straight quotes, `…` → `...`, NBSP → space. (Emoji are separately unwanted; see Step 2.)
3. **`az repos pr create` passes the description as a command-line argument**, so a long body blows the
   Windows ~8191-character command-line limit and fails with "The command line is too long." Keep the
   description short, or use the REST API below.
4. **`az` may be installed but absent from PATH.** Before concluding it is missing, check
   `C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin\az.cmd` — a bare `command -v az` gives a false negative.

If the extension isn't installed yet, add it once: `az extension add --name azure-devops`.
Azure Repos PRs have no separate title field for the body — the description IS the body,
so put the title as an `# H1` on its own first line as well as in `--title`.

```bash
# Push branch if not tracking remote
git push -u origin <branch>

# <org>/<project>/<repo> from the remote URL parsed in Step 1.
az repos pr create \
  --organization "https://dev.azure.com/<org>" \
  --project "<project>" \
  --repository "<repo>" \
  --source-branch "<branch>" \
  --target-branch "<base-branch>" \
  --title "<title>" \
  --description "$(cat <<'EOF'
# <title>

<filled template body from Step 3>
EOF
)" \
  --draft true
```

The command returns JSON with `pullRequestId`. Report the draft PR URL to the user as
`https://dev.azure.com/<org>/<project>/_git/<repo>/pullrequest/<pullRequestId>`.

**Azure DevOps via REST — use this when the description is more than a few hundred characters.**
It avoids the command-line limit entirely and is the reliable path on Windows. It reuses the
existing `az login`, so no PAT is needed and no credential is ever handled in plain text. Build the
JSON in-process and send it as UTF-8 bytes with `-ContentType 'application/json'` — do **not** put
`Content-Type` in the headers hashtable and do **not** append `charset=utf-8`; either makes
PowerShell 5.1 mangle the body, and the API then reports misleading errors like
"Both a source and target reference is required."

```powershell
$env:PATH = "C:\Program Files\Microsoft SDKs\Azure\CLI2\wbin;$env:PATH"
$token   = az account get-access-token --resource "499b84ac-1321-427f-aa17-267ca6975798" --query accessToken -o tsv
$headers = @{ Authorization = "Bearer $token" }
$base    = "https://dev.azure.com/<org>/$([uri]::EscapeDataString('<project>'))/_apis/git/repositories/<repo>"

function Send-Json($Method, $Uri, $Object) {
    $json = $Object | ConvertTo-Json -Depth 6 -Compress
    Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers `
        -ContentType 'application/json' -Body ([System.Text.Encoding]::UTF8.GetBytes($json))
}

# Create (description must already be ASCII-folded and <= 4000 chars)
$pr = Send-Json Post "$base/pullrequests?api-version=7.1" @{
    sourceRefName = "refs/heads/<branch>"
    targetRefName = "refs/heads/<base-branch>"
    title         = "<title>"
    description   = $desc
    isDraft       = $true
}

# Optional: reviewer-facing overflow as the first comment thread (much larger limit)
Send-Json Post "$base/pullRequests/$($pr.pullRequestId)/threads?api-version=7.1" @{
    comments = @(@{ parentCommentId = 0; content = $overflow; commentType = 1 })
    status   = 1
}
```

**Never probe field limits against a live PR** — a failed `PATCH` leaves the last successful value
in place, so a length probe can silently overwrite a real description with filler.

**Neither CLI is available for this remote's host:**

Save the body to a file in the current working directory. Since the body no longer contains the title, put the title on the first line as an `# H1` in the saved file (so the file is self-describing), then report:
```
PR description saved to pr-<ticket-or-slug>.md
<gh|az> CLI not found — install it to create draft PRs directly, or paste the title + description manually.
```

### Step 5: Report to user

Always end with:
- The PR title
- The base branch it targets
- The draft PR URL (if created) or file path (if saved)
- Reminder: "Review the draft, add reviewers, and publish when ready."
