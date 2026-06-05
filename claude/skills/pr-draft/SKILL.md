---
name: pr-draft
description: Use when the user wants to create a pull request, generate a PR description, write a draft PR, or asks for /pr-draft or /pr. Analyzes branch diff and commits to produce a filled PR and creates a draft PR via gh CLI.
disable-model-invocation: true
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

Use this template structure:

```markdown
# <title line from step 2>

### 📝 Description

<2-4 sentence summary of what changed and why, based on the diff and commits>

💪 **Highlights**

<bullet list of key changes — derived from the actual diff, not generic>

---

### 🧪 Testing Instructions

<numbered steps a reviewer should follow to validate the changes — be specific to what actually changed>

---

### 📷 Screenshots & Recordings

|         |         |
|  :----  | :-----: |
| Before | _to be added_ |
| After  | _to be added_ |

---

### 🧰 Dependencies & Requirements

<list new dependencies, or "None" if no new dependencies were added>

---

### 💥 Breaking Changes & Alerts

<describe breaking changes, or "None" if backwards compatible>
```

**Rules for generating content:**
- Description: focus on the WHY, not just the WHAT
- Highlights: concrete, specific to the diff — no filler
- Testing instructions: actionable steps tied to the actual changes
- Dependencies: check package.json diff for new deps
- Breaking changes: check for removed/renamed exports, changed interfaces, API changes

### Step 4: Create the PR

**If `gh` CLI is available:**

```bash
# Push branch if not tracking remote
git push -u origin <branch>

# Create draft PR targeting the detected base branch
# Include the H1 title line inside the body so it appears above the description on GitHub
gh pr create --draft --base <base-branch> --title "<title>" --body "$(cat <<'EOF'
# <title>

<rest of body from the template>
EOF
)"
```

Report the draft PR URL to the user.

**If `gh` CLI is NOT available:**

Save the full body (including the H1 title line) to a file in the current working directory and report:
```
PR description saved to pr-<ticket-or-slug>.md
gh CLI not found — install it to create draft PRs directly, or paste the description manually.
```

### Step 5: Report to user

Always end with:
- The PR title
- The base branch it targets
- The draft PR URL (if created) or file path (if saved)
- Reminder: "Review the draft, add reviewers, and publish when ready."
