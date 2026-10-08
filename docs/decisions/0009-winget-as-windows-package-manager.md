# 0009. Winget as Windows package manager

Date: 2026-08-03
Status: accepted

**Decision:** Windows machine setup uses **winget** with a tracked import manifest
(`winget/packages.json`) as the Brewfile's stand-in. **Chocolatey is explicitly rejected**
(user preference). Scoop is not adopted as a manager either — it appears only as a documented
per-tool fallback.

## Key points

- **tool:** `winget/packages.json` is a `winget import` manifest (schema 2.0) mirroring the Brewfile
- **convention:** Every package ID in the manifest was verified to exist in microsoft/winget-pkgs before being added
- **convention:** Brewfile stays the single source of truth for VS Code extensions — Windows installs them by parsing the Brewfile's `vscode "…"` lines with Select-String → `code --install-extension`
- **convention:** When the Brewfile gains/loses a package, winget/packages.json and the README substitutions table are updated in the same change
- **constraint:** Chocolatey is banned from the setup; winget + documented fallbacks must cover everything
- **rationale:** winget ships with Windows 10/11 (no bootstrap step) and has a declarative import format equivalent to `brew bundle`
- **rationale:** macOS-only casks get explicit Windows substitutions: OrbStack→Docker Desktop, Postgres.app→PostgreSQL.PostgreSQL.18, Rectangle→PowerToys FancyZones
- **risk:** Supabase CLI and fvm are not on winget — fallbacks are pnpm dev-dependency / GitHub release binary; revisit if they land on winget

## Related

- affects [0006. Copy-based setup, no symlinks](0006-copy-based-setup-no-symlinks.md)
