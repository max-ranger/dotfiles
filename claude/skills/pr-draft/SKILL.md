---
name: pr-draft
description: Use when the user wants to create a pull request, generate a PR description, write a draft PR, or asks for /pr-draft or /pr. Analyzes branch diff and commits to produce a filled PR and creates a draft PR via gh CLI.
---

# Draft PR Creator

Generate a complete PR description from the current branch's changes and create a draft PR via `gh`.

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

# Check gh CLI
command -v gh 2>/dev/null || where gh 2>/dev/null && echo "gh available" || echo "gh not available"

# Check if branch is pushed
git rev-parse --abbrev-ref @{upstream} 2>/dev/null && echo "tracking" || echo "not tracking"
```

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

**Title generation:**
- With ticket: `<emoji> <Type> #<ticket>: <descriptive title from changes>`
- Without ticket: `<emoji> <Type>: <descriptive title from changes>`
- The descriptive title should be derived from the actual changes (commits + diff), not just the branch slug
- Keep under 70 characters

**Type emoji mapping:**
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

**If `gh` CLI is available:**

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

**If `gh` CLI is NOT available:**

Save the body to a file in the current working directory. Since the body no longer contains the title, put the title on the first line as an `# H1` in the saved file (so the file is self-describing), then report:
```
PR description saved to pr-<ticket-or-slug>.md
gh CLI not found — install it to create draft PRs directly, or paste the title + description manually.
```

### Step 5: Report to user

Always end with:
- The PR title
- The base branch it targets
- The draft PR URL (if created) or file path (if saved)
- Reminder: "Review the draft, add reviewers, and publish when ready."
