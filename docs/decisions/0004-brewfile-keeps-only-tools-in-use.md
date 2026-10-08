# 0004. The Brewfile keeps only tools in use

Date: 2026-10-08
Status: accepted

## Context
`~/.zshrc` initialised only starship and fnm; bat, eza, fzf, zoxide and direnv were installed but never wired (zoxide db empty, no `.envrc` anywhere). docker/docker-compose formulae were shadowed by OrbStack's symlinks. fvm had no `.fvmrc`; awscli no `~/.aws`; gnupg no keys (signing is SSH); coreutils no gnubin on PATH; deno no `deno.json`; corepack ships with Node.

## Decision
Dropped: bat, eza, fzf, zoxide, direnv, docker, docker-compose, fvm, awscli, gnupg, coreutils, deno, wget, htop, tree, `npm corepack`, `uv basic-memory`. Kept: age, sops, jq, gh, git, git-filter-repo, ripgrep, shellcheck, starship, fnm, pnpm, uv, supabase, cocoapods (Pegasus iOS), whisper.cpp (model present), @playwright/cli. winget mirrors the removals. Criterion for re-adding: wired into the shell or required by a repo or a hook.

## Consequences
- Fewer binaries to update; the manifest describes what is actually used.
- Re-adding anything is one line.

## Alternatives considered
- Wire the shell tools into `.zshrc` — nobody missed them in four months.
