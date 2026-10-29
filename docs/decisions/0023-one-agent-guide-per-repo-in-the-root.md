# 0023. One agent guide per repo, in the root: AGENTS.md, imported by CLAUDE.md

Date: 2026-10-29
Status: accepted

## Context
[0022](0022-claude-md-and-agents-md-are-committed.md) made `CLAUDE.md` and `AGENTS.md` committed wherever they sat, `.claude/CLAUDE.md` included. That left two layouts side by side. The repo template, ranger-infra, pegasus and handbook kept the guide in `.claude/CLAUDE.md`. ranger-app-template and the apps generated from it (argos, cerberus, manticore) keep it in a root `AGENTS.md` that a one-line root `CLAUDE.md` imports. homepage, welserhundesportklub and ranger-vue had an ignored copy of the old generic template that was never filled in. Two layouts mean every tool, rule and person has to check both places.

## Decision
A repo has exactly one agent guide, in its root, committed. `AGENTS.md` holds the content, and `CLAUDE.md` is the single line `@AGENTS.md`. Nothing lives in `.claude/CLAUDE.md` or in a subfolder. dotfiles keeps two templates: the global `claude/CLAUDE.md` for Claude Code on the machine, and `claude/repo-template/` with the root pair.

## Consequences
- Claude Code, and agents that read `AGENTS.md`, load the same guide from the same place in every repo.
- The canonical gitignore drops `!.claude/CLAUDE.md`, so a `.claude/CLAUDE.md` is ignored and works only as a local file.
- Repos using `.claude/CLAUDE.md` move it to `AGENTS.md`, and their gitignore copies get the new Claude section.
- No global `AGENTS.md` for now: Claude Code reads `~/.claude/CLAUDE.md`. One gets added when another agent on the machine needs it.
- Door: two-way; cost if wrong: a `git mv` per repo.

## Alternatives considered
- Keep the guide in `CLAUDE.md` and add no `AGENTS.md`. Four repos already use the `AGENTS.md` layout, and only `AGENTS.md` is read by agents other than Claude.
- Allow `.claude/CLAUDE.md` next to the root files. That is the two-layout problem this decision removes.
