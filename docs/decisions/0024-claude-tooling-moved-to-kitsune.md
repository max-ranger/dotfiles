# 0024. The Claude Code tooling moved to its own repo, kitsune

Date: 2026-10-29
Status: accepted

## Context
This repo describes a machine setup that is copied into place by hand. The Claude Code tooling that grew under `claude/` became a tool in its own right: a plugin with hook scripts and test suites, skills, an agent, a marketplace, and a planned agent OS with a TypeScript mod. By 2026-10-29 it was 73 of this repo's 107 files and 17 of its 23 ADRs.

## Decision
The whole of `claude/`, the marketplace manifest and the Claude ADRs (0001 to 0003, 0005, 0008, 0010, 0011, 0013, 0014, 0016 to 0023) moved to `~/Code/kitsune` (GitHub `max-ranger/kitsune`), keeping their numbers. The marketplace is still named `ranger` and the plugin `ranger-claude`, so every repo's `ranger-claude@ranger` keeps working once its marketplace source says `max-ranger/kitsune`. This repo keeps the machine setup and points at kitsune for Claude Code. ADR 0001 stays here as well, since this repo keeps recording its own decisions.

## Consequences
- The README's Claude Code section is a pointer. Install and maintenance steps for the plugin live in kitsune's README.
- Numbers 0002, 0003, 0005, 0008, 0010, 0011, 0013, 0014, 0016 to 0023 are gaps here. kitsune's `docs/decisions/` has them.
- `scripts/migrate-windows.ps1` still refers to copying the Claude config from this repo. It documents a one-time move that already happened and is left as is.
- Door: two-way; cost if wrong: one `git mv` back and one marketplace source change.

## Alternatives considered
- Keep the tooling here and rename the repo. The Brewfile, Git and VS Code notes would then sit inside a tool repo with a test suite and a review policy they do not need.
