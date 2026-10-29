# 0017. Project settings are committed; plan-mode drafts are gitignored scratch

Date: 2026-10-13
Status: accepted; superseded in part by 0022 (CLAUDE.md is committed)

## Context
The canonical gitignore ignored `.claude/` wholesale, so no repo could carry a `.claude/settings.json`. Two things followed: plan mode wrote its files to `~/.claude/plans`, outside the repo it was planning for, and a cloud session started in a repo had no way to learn that the `ranger-claude` plugin belongs there. [0002](0002-knowledge-lives-in-git-basic-memory-retired.md) puts knowledge in git; the playbook this setup follows commits the plan next to the spec.

## Decision
Every repo commits `.claude/settings.json` with three keys: `plansDirectory: ./docs/plans`, the plugin under `enabledPlugins`, and the GitHub marketplace under `extraKnownMarketplaces`. The canonical gitignore becomes `.claude/*` plus `!.claude/settings.json`, so the rest of `.claude/` stays personal, and it ignores `docs/plans/`.

Plan-mode output is a draft: one auto-named file per planning session, including the abandoned ones. It lives in the repo it belongs to but never enters history. The plan that was accepted is copied to `docs/specs/<feature>/plan.md`, which is what the verifier and the review check against. The app template ships the same settings file, so generated apps start with it.

## Consequences
- Worktrees and cloud sessions each get their own draft folder; nothing leaks between them.
- A repo template no longer needs its own `.gitignore`; the canonical one carries both rules.
- On a machine that registered the marketplace from a local checkout, watch that a project session does not re-register it from GitHub; plugin edits there are tested from the checkout.
- Door: two-way; cost if wrong: one line in each repo's settings.

## Alternatives considered
- Keep drafts in `~/.claude/plans` — invisible to the repo and to cloud sessions, with the same copy step.
- Commit `docs/plans/` — history fills with abandoned drafts under generated names.
