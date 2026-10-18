---
name: intent
description: Use when a change bigger than half a day is about to start and nobody has written down why — "/intent", "new feature", "add a feature/view", "let's plan X", "I want to build", a vague ask that would otherwise go straight to code. Not for fixes or chores; not when docs/specs/<feature>/intent.md already exists (spec).
---

# Intent

Capture *why* before *what*. Output is `docs/specs/<feature>/intent.md`; nothing else is written.

## Process

0. Size gate: fixes, chores and changes under half a day get no intent file. Say so in one line and proceed without one. An existing `intent.md` for the feature means the next step is `/spec`, not a second interview.
1. Read `docs/overview.md` and `docs/architecture.md` if they exist. Skip the interview for anything you can answer from the repo.
2. Hypothesize the intent with a confidence number ("I think you want X, ~70%").
3. Ask **one** question at a time, each with your best guess attached, so a "yes" is enough. Stop asking at ~95% confidence or when the user says "go". Method: `${CLAUDE_PLUGIN_ROOT}/references/interview-method.md`.
4. Listen for "want vs. should want": name the difference once, let the user decide. Ask once what would make this a failure even if it technically works, and what would make the user wince if it were built wrong; those become constraints.
5. Write the file, restate the intent in the user's own words, and **stop the turn** so they can accept it. Status stays `draft` until they say so.

## File

`docs/specs/<feature>/intent.md` — `<feature>` is a short slug, no date, no number.

```markdown
# Intent: <title>

Status: draft | ready
Author: <git config user.name; never asked>

## Problem
<what hurts today, for whom, evidence>

## Proposed outcome
<what is true when this is done; observable, not implementation>

## Affected users & systems
<who notices; which repos, modules, data, integrations>

## Constraints
<non-negotiables: security, data, compatibility, deadline, budget>

## Open questions
- [ ] <question> — owner, needed by
```
