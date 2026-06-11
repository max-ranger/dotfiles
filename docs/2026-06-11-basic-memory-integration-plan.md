# basic-memory Integration — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire basic-memory into the Claude workflow via a global memory protocol (`~/.claude/CLAUDE.md`) plus a thin SessionStart hook that surfaces each repo's project and nudges confirm-first knowledge capture.

**Architecture:** Two version-controlled pieces in the dotfiles repo — `claude/CLAUDE.md` (the protocol, symlinked to `~/.claude/CLAUDE.md`) and `claude/hooks/basic-memory-context.sh` (SessionStart activation, auto-deployed via the existing `~/.claude/hooks` symlink and registered in `claude/settings.json`).

**Tech Stack:** bash, jq, git, Claude Code hooks (SessionStart `additionalContext`), basic-memory MCP.

**Spec:** `docs/2026-06-11-basic-memory-integration.md`

---

## Conventions & ground truth (verified)

- `~/.claude/hooks` → symlink to `dotfiles/claude/hooks` (new hook auto-deploys; no extra symlink).
- `~/.claude/settings.json` → symlink to `dotfiles/claude/settings.json` (editing the repo file updates live settings).
- `~/.claude/CLAUDE.md` does **not** exist yet → needs a new symlink.
- SessionStart hook output format (from `push-notify-reminder.sh`): JSON with `hookSpecificOutput.additionalContext`.
- `_parse-input.sh` reads stdin and exposes `_json_extract <key>` / `_json_decode` (reuse to pull `cwd`).
- `jq`, `python3`, `basic-memory` CLI all present.
- The basic-memory `Project Memory` duplication lives in `~/Dev/ranger/CLAUDE.md` (a loose file outside the repo), **not** in `claude/templates/CLAUDE.md` (which has no memory section).
- All commits go to dotfiles `main`; **pushing is gated** by `security-gate.sh` (do not push — leave commits local).

## File structure

- Create: `dotfiles/claude/CLAUDE.md` — global memory protocol (single responsibility: durable-knowledge conventions).
- Create: `dotfiles/claude/hooks/basic-memory-context.sh` — SessionStart activation (single responsibility: resolve repo→project, emit one nudge).
- Modify: `dotfiles/claude/settings.json` — register the hook under `SessionStart`.
- Modify: `dotfiles/README.md` — Layout entry + bootstrap symlink (macOS + Windows).
- Modify (outside repo): `~/Dev/ranger/CLAUDE.md` — trim the duplicated `Project Memory` section to a pointer.

---

## Task 1: Global memory protocol (`claude/CLAUDE.md`) + symlink

**Files:**
- Create: `dotfiles/claude/CLAUDE.md`
- Symlink: `~/.claude/CLAUDE.md` → `dotfiles/claude/CLAUDE.md`

- [ ] **Step 1: Create the protocol file**

Create `dotfiles/claude/CLAUDE.md` with exactly:

```markdown
# Claude — Global Instructions

## Knowledge Memory (basic-memory)

Durable, non-code project knowledge lives in **basic-memory**, structured so it
renders as an Obsidian knowledge graph and gives Claude cross-session context.

**Project mapping (coding sessions):**
- In a git repo, the basic-memory project = the git-root folder name
  (`git rev-parse --show-toplevel` basename), e.g. `manticore`, `rentsales`.
- If that project does not exist, **ask before creating it** (never auto-create).
- The SessionStart hook surfaces the resolved project name and whether it exists.

**At session start (read):** before substantive work, call `recent_activity` and
read the project's `Overview` note. Skip for trivial/throwaway tasks.

**What to capture (durable only):** tech stack, and technical / architectural /
design / product / ops **decisions**. No work logs, no play-by-play.

**Structure (per project):**
- `Overview` — hub note; what the repo is; links to everything.
- `Tech Stack` — stack as tagged observations.
- `decisions/YYYY-MM-DD-<slug>` — one ADR-style note per significant decision.
- `design/<slug>` — design/UX decisions & conventions.
- `architecture/<Component>` — component/system notes, as they emerge.

**Markup (drives the graph):**
- Observations: `- [category] content #tag`
  (categories: framework, language, library, infra, tool, convention,
  constraint, rationale, risk).
- Relations: `- relation_type [[Note]]`
  (vocabulary: part_of, affects, depends_on, supersedes, motivated_by).
  Every decision/design/architecture note links `part_of [[Overview]]`.
- Decision tags: #technical #architectural #design #product #ops.

**Writing (confirm-first):** capture during work; at checkpoints (task done,
before a commit, session wind-down) present the draft note(s) — title, folder,
key observations + relations — get approval, then `write_note` / `edit_note`.
Nothing is written without approval.

**Non-coding / cowork sessions:** the same capture discipline applies; the target
project convention for non-repo work will be defined when that is enabled.
```

- [ ] **Step 2: Create the symlink**

Run:
```bash
ln -sf "$HOME/Dev/ranger/ranger-ecosystem/dotfiles/claude/CLAUDE.md" ~/.claude/CLAUDE.md
```

- [ ] **Step 3: Verify the symlink resolves to the protocol**

Run:
```bash
readlink ~/.claude/CLAUDE.md && head -1 ~/.claude/CLAUDE.md
```
Expected: prints the dotfiles path, then `# Claude — Global Instructions`.

- [ ] **Step 4: Commit**

```bash
cd ~/Dev/ranger/ranger-ecosystem/dotfiles
git add claude/CLAUDE.md
git commit -m "feat(claude): add global basic-memory knowledge protocol"
```

---

## Task 2: SessionStart hook (`basic-memory-context.sh`)

**Files:**
- Create: `dotfiles/claude/hooks/basic-memory-context.sh`

- [ ] **Step 1: Write the failing check (hook not yet present)**

Run:
```bash
echo '{"hook_event_name":"SessionStart","cwd":"/Users/maxranger/Dev/ranger/homepage"}' \
  | bash ~/.claude/hooks/basic-memory-context.sh
```
Expected: FAIL — `bash: .../basic-memory-context.sh: No such file or directory`.

- [ ] **Step 2: Create the hook**

Create `dotfiles/claude/hooks/basic-memory-context.sh` with exactly:

```bash
#!/bin/bash
# SessionStart: surface this repo's basic-memory project and nudge the
# knowledge-capture protocol (full rules in ~/.claude/CLAUDE.md).
# Thin by design: resolve repo -> project name, check existence in
# ~/.basic-memory/config.json, emit one additionalContext line.
# No-op outside a git repo.

source ~/.claude/hooks/_parse-input.sh   # consumes stdin; exposes _json_extract/_json_decode

CWD=$(_json_decode "$(_json_extract cwd)")
[ -z "$CWD" ] && CWD="$PWD"

REPO_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && exit 0

PROJECT=$(basename "$REPO_ROOT")
CONFIG="$HOME/.basic-memory/config.json"

if [ -f "$CONFIG" ] && jq -e --arg p "$PROJECT" '.projects[$p]' "$CONFIG" >/dev/null 2>&1; then
  MSG="📓 basic-memory project \`${PROJECT}\`: before substantive work, load context (recent_activity + Overview). Capture durable decisions at checkpoints — draft, confirm, then write."
else
  MSG="📓 No basic-memory project for \`${PROJECT}\` yet: offer to create one before capturing knowledge. Capture durable decisions at checkpoints — draft, confirm, then write."
fi

jq -nc --arg m "$MSG" \
  '{continue:true,suppressOutput:true,hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$m}}'
```

- [ ] **Step 3: Make it executable**

Run:
```bash
chmod +x ~/Dev/ranger/ranger-ecosystem/dotfiles/claude/hooks/basic-memory-context.sh
```

- [ ] **Step 4: Verify — existing project (homepage)**

Run:
```bash
echo '{"hook_event_name":"SessionStart","cwd":"/Users/maxranger/Dev/ranger/homepage"}' \
  | bash ~/.claude/hooks/basic-memory-context.sh
```
Expected: one JSON line whose `additionalContext` contains:
`📓 basic-memory project \`homepage\`: before substantive work, ...`

- [ ] **Step 5: Verify — missing project (dotfiles)**

Run:
```bash
echo '{"hook_event_name":"SessionStart","cwd":"/Users/maxranger/Dev/ranger/ranger-ecosystem/dotfiles"}' \
  | bash ~/.claude/hooks/basic-memory-context.sh
```
Expected: `additionalContext` contains:
`📓 No basic-memory project for \`dotfiles\` yet: ...`

- [ ] **Step 6: Verify — not a git repo (no output)**

Run:
```bash
echo '{"hook_event_name":"SessionStart","cwd":"/tmp"}' \
  | bash ~/.claude/hooks/basic-memory-context.sh; echo "exit=$?"
```
Expected: no JSON output, `exit=0`.

- [ ] **Step 7: Verify — valid JSON shape**

Run:
```bash
echo '{"cwd":"/Users/maxranger/Dev/ranger/homepage"}' \
  | bash ~/.claude/hooks/basic-memory-context.sh \
  | jq -e '.hookSpecificOutput.hookEventName=="SessionStart" and (.hookSpecificOutput.additionalContext|length>0)'
```
Expected: prints `true`.

- [ ] **Step 8: Commit**

```bash
cd ~/Dev/ranger/ranger-ecosystem/dotfiles
git add claude/hooks/basic-memory-context.sh
git commit -m "feat(hooks): add SessionStart basic-memory context nudge"
```

---

## Task 3: Register the hook in `settings.json`

**Files:**
- Modify: `dotfiles/claude/settings.json` (SessionStart array)

- [ ] **Step 1: Add the hook entry**

In `dotfiles/claude/settings.json`, the `hooks.SessionStart[0].hooks` array currently holds one entry (`push-notify-reminder.sh`). Add a second entry so it reads:

```json
"SessionStart": [
  {
    "matcher": "",
    "hooks": [
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/push-notify-reminder.sh",
        "timeout": 5
      },
      {
        "type": "command",
        "command": "bash ~/.claude/hooks/basic-memory-context.sh",
        "timeout": 5
      }
    ]
  }
]
```

- [ ] **Step 2: Verify JSON is valid and both hooks are present**

Run:
```bash
jq -e '.hooks.SessionStart[0].hooks | map(.command) | any(test("basic-memory-context"))' \
  ~/Dev/ranger/ranger-ecosystem/dotfiles/claude/settings.json
```
Expected: prints `true` (and jq exits 0, proving the file is valid JSON).

- [ ] **Step 3: Commit**

```bash
cd ~/Dev/ranger/ranger-ecosystem/dotfiles
git add claude/settings.json
git commit -m "chore(claude): register basic-memory-context SessionStart hook"
```

> Note: Claude Code may re-order `settings.json` keys on next startup (it has before). That's cosmetic — the hook entry remains.

---

## Task 4: Reconcile duplicated memory guidance (parent CLAUDE.md)

**Files:**
- Modify (outside repo): `~/Dev/ranger/CLAUDE.md`

The global protocol is now the single source of truth. Trim the parent file's duplicate section to a pointer. (The dotfiles template `claude/templates/CLAUDE.md` has no memory section — nothing to change there.)

- [ ] **Step 1: Replace the section**

In `~/Dev/ranger/CLAUDE.md`, find the `## Project Memory (basic-memory)` section (its three bullets) and replace the section body with:

```markdown
## Project Memory (basic-memory)

Durable non-code knowledge (tech stack, decisions, architecture, design) goes in
this repo's **basic-memory** project (named after the repo), per the global
protocol in `~/.claude/CLAUDE.md` — not committed to the repo. Capture it in
basic-memory (confirm-first); don't leave it as local markdown files.
```

- [ ] **Step 2: Verify the pointer is in place**

Run:
```bash
grep -A4 "## Project Memory (basic-memory)" ~/Dev/ranger/CLAUDE.md
```
Expected: shows the new pointer text referencing `~/.claude/CLAUDE.md`.

> No commit — `~/Dev/ranger/` is a loose directory, not a git repo.

---

## Task 5: Update README (Layout + bootstrap symlink)

**Files:**
- Modify: `dotfiles/README.md`

- [ ] **Step 1: Add `claude/CLAUDE.md` to the Layout block**

Find:
```
claude/
  settings.json         # Claude Code user settings (hooks, plugins, flags)
```
Replace with:
```
claude/
  CLAUDE.md             # Global user instructions (basic-memory protocol) → ~/.claude/CLAUDE.md
  settings.json         # Claude Code user settings (hooks, plugins, flags)
```

- [ ] **Step 2: Add the macOS/Linux symlink line**

Find:
```
ln -sf "$PWD/claude/settings.json" ~/.claude/settings.json
```
Replace with:
```
ln -sf "$PWD/claude/CLAUDE.md"     ~/.claude/CLAUDE.md
ln -sf "$PWD/claude/settings.json" ~/.claude/settings.json
```

- [ ] **Step 3: Add the Windows symlink line**

Find:
```
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\settings.json" -Target "$PWD\claude\settings.json"
```
Replace with:
```
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\CLAUDE.md" -Target "$PWD\claude\CLAUDE.md"
New-Item -ItemType SymbolicLink -Path "$env:USERPROFILE\.claude\settings.json" -Target "$PWD\claude\settings.json"
```

- [ ] **Step 4: Verify**

Run:
```bash
grep -nE "claude/CLAUDE.md|\.claude\\\\CLAUDE.md|CLAUDE.md             #" \
  ~/Dev/ranger/ranger-ecosystem/dotfiles/README.md
```
Expected: shows the Layout line and both symlink lines.

- [ ] **Step 5: Commit**

```bash
cd ~/Dev/ranger/ranger-ecosystem/dotfiles
git add README.md
git commit -m "docs(readme): document global CLAUDE.md symlink + memory protocol"
```

---

## Task 6: End-to-end verification

- [ ] **Step 1: Protocol loads via symlink**

Run:
```bash
grep -c "Knowledge Memory (basic-memory)" ~/.claude/CLAUDE.md
```
Expected: `1`.

- [ ] **Step 2: settings.json is valid and wires both SessionStart hooks**

Run:
```bash
jq '.hooks.SessionStart[0].hooks | map(.command)' \
  ~/Dev/ranger/ranger-ecosystem/dotfiles/claude/settings.json
```
Expected: array containing both `push-notify-reminder.sh` and `basic-memory-context.sh`.

- [ ] **Step 3: Live smoke test (manual)**

Start a new Claude Code session inside `~/Dev/ranger/homepage` and confirm the
SessionStart context shows the `📓 basic-memory project homepage` nudge, and that
`~/.claude/CLAUDE.md` guidance is in effect (ask Claude to resolve the current
repo's basic-memory project — it should answer `homepage`).
Expected: nudge present; project resolves correctly.

- [ ] **Step 4: Review commits (do not push — gated)**

Run:
```bash
cd ~/Dev/ranger/ranger-ecosystem/dotfiles && git log --oneline origin/main..HEAD
```
Expected: the four new commits (CLAUDE.md, hook, settings, README). Push manually
when ready (`git push origin main` → approve the security-gate prompt).

---

## Self-review (author checklist — completed)

- **Spec coverage:** mechanism (Tasks 1–3), project resolution (Task 2 hook), note structure/markup (Task 1 protocol), confirm-first read/capture/write (Task 1 protocol), deployment/symlink (Tasks 1, 5), template/duplication reconciliation (Task 4), non-goals respected (no work logs, no auto-create — encoded in the protocol). ✓
- **Placeholder scan:** none — every file/edit has exact content. ✓
- **Type/name consistency:** project name = git-root basename everywhere; hook filename `basic-memory-context.sh` consistent across Tasks 2, 3, 6; config key path `.projects[$p]` consistent. ✓
- **Deviation note:** plan saved to `docs/` (not `docs/superpowers/plans/`) to match the spec's user-chosen location.
```
