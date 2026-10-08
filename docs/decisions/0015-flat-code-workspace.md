# 0015. Flat `~/Code` workspace; `ranger-ecosystem` keeps its name

Date: 2026-10-08
Status: accepted

## Context
The workspace was `~/Dev/{ranger,clients,sandbox}`. Neither grouping was true any more: there is no client work, and not everything under `ranger/` is a Ranger product. Project notes lived in a separate `~/BasicMemory` vault, which [0002](0002-knowledge-lives-in-git-basic-memory-retired.md) retired. Product repos reach shared repos through relative paths (`../ranger-ecosystem/ranger-infra` in the `bin/_lib.sh` of the products, `../ranger-ecosystem/ranger-vue` in the frozen v1 of one of them, including its Dockerfile, lockfile and CI).

## Decision
One root, `~/Code`, flat by project: every product repo sits directly under it. The only grouping folder is `ranger-ecosystem/`, and it keeps that exact name, because renaming it would break every relative path above, including in a frozen production branch. Next to the repos: `handbook/` (cross-repo knowledge, its own private repo), `sandbox/`, `archive/` (inactive checkouts), `assets/` (brand assets and test data that must stay outside git) and `backups/` (dumps, never committed).

Because the product repos moved up one level together with `ranger-ecosystem/`, every relative path between them is unchanged. Only absolute `~/Dev/...` references had to be rewritten.

## Consequences
- Session history and project memory of Claude Code are keyed by path; the stored project folders were renamed to the new paths.
- Generated files with absolute paths (Flutter iOS config, `.dart_tool`, pnpm shims, .NET `obj/`) regenerate on the next `pub get` / `install` / `restore`.
- The Windows machine still uses `C:\Dev\...` and is moved separately.
- `~/Code` leaves room for a sibling folder for non-code projects if one is ever needed.

## Alternatives considered
- Rename the group to `ecosystem/` — breaks the relative paths in three product repos and one frozen branch for a cosmetic gain.
- Keep `~/Dev` and only drop the `ranger/` and `clients/` tiers — the name no longer described the content either.
- A hub repo per multi-repo project — one `handbook` repo for all cross-repo knowledge is the common pattern and one repo instead of several.
