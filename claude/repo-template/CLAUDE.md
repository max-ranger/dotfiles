# CLAUDE.md

> Project scaffold — fill the placeholders, delete what doesn't apply, and append the
> relevant stack file(s) from `dotfiles/claude/repo-template/stacks/`. Living document:
> when a correction reveals a project rule, record it here so the mistake doesn't repeat.
> Keep it lean — only what Claude can't infer from the code.

## Project

<!-- One paragraph: what this repo is, who/what it serves, anything non-obvious. -->

## Commands

<!-- Copy-paste-ready: dev, build, test, lint. Exact commands, not descriptions. -->

## Architecture

<!-- Only the non-obvious: entry points, module boundaries, where things live. -->

## Conventions & Gotchas

- When adding a dependency that already exists in a sibling workspace/package, match its
  version exactly — don't scaffold a fresh `^latest`.
- Semantic commit messages.
- Never add `Co-Authored-By` lines to commits.
<!-- Add project quirks: required env vars, flaky areas, things that bit you before. -->
