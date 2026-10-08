# 0006. Copy-based setup, no symlinks

Date: 2026-06-22
Status: accepted; the plugin is installed from a marketplace since 0003

Dotfiles are applied by **copying** files into place — not symlinking and not running an
installer/daemon. The repo is documentation plus the canonical record; the live machine and the
repo are reconciled by hand.

## Context
A new machine is set up by running explicit per-tool copy commands (`cp` / `Copy-Item`) from the
cloned repo. There is deliberately no bootstrap script that mutates the system automatically.

## Key points
- **architectural:** Explicit copy commands per tool — no symlinks, no installer, no sync daemon
- **rationale:** Keeps the repo a readable reference and avoids surprise overwrites of live config
- **convention:** Update flow: change the live file → copy it back into the repo → commit & push
- **constraint:** Live machine and repo do not stay in sync automatically — drift is accepted and reconciled manually
