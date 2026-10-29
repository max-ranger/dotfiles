# 0022. Commit CLAUDE.md and AGENTS.md as the project's agent guide

Date: 2026-10-29
Status: accepted

## Context
The canonical gitignore ignored every `CLAUDE.md` and, through `.claude/*` from [0017](0017-project-settings-committed-plan-drafts-scratch.md), `.claude/CLAUDE.md` too. The idea was that the file held personal notes. That is no longer true. A repo's `CLAUDE.md` or `AGENTS.md` now holds project knowledge: the layout, the exact commands, the gotchas. A fresh clone or a cloud session without it starts blind. Three repos had already worked around the rule: ranger-app-template un-ignores `/CLAUDE.md` and `/AGENTS.md`, ranger-infra and handbook un-ignore `.claude/CLAUDE.md`. Claude Code keeps a separate file for personal notes, `CLAUDE.local.md`.

## Decision
The canonical gitignore no longer ignores `CLAUDE.md` and adds `!.claude/CLAUDE.md`. `CLAUDE.md` and `AGENTS.md` are committed wherever they sit. `CLAUDE.local.md` and the rest of `.claude/` except `settings.json` stay ignored.

## Consequences
- A new repo commits its agent guide without a local override. The overrides in ranger-app-template are gone. The ones in ranger-infra and handbook are now redundant but harmless.
- Personal notes must go in `CLAUDE.local.md`. A personal `CLAUDE.md` in an older checkout now shows up as untracked and could be committed by mistake.
- Repos that copied the old gitignore (ranger-dotnet, ranger-vue) still ignore `CLAUDE.md` until their copy is refreshed.
- Door: two-way; cost if wrong: one line back in the canonical gitignore and its copies, though whatever a committed `CLAUDE.md` said stays in history.

## Alternatives considered
- Keep ignoring `CLAUDE.md` and override per repo. Every repo that matters already needed the override, so the default was wrong.
- Commit only `AGENTS.md` and keep `CLAUDE.md` personal. The template's `CLAUDE.md` is just `@AGENTS.md`, and other repos use `.claude/CLAUDE.md` as the guide, so both names carry project content.
