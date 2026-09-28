# 🧰 dotfiles

> A reference for setting up a new machine the way I like it — **Claude Code, Homebrew, Git,
> .NET, and VS Code**, each with notes on *what it's for* and *how to put it in place*.

**📋 It's documentation, not an auto-syncing setup.** Nothing here is symlinked or run
automatically. On a new machine you *copy* what you want into place. When you find a better way
to do something, change the live file and copy it back here by hand. The repo is the canonical
record of the preferred setup, kept current manually.

🖥️ Primary target is **macOS** (Apple Silicon). Every step also has a **Windows** variant using
[winget](https://learn.microsoft.com/windows/package-manager/), the package manager built into
Windows 10/11 — Homebrew doesn't run on Windows, so winget is its stand-in there.

---

## 📑 Contents

1. [⚡ Quick setup — zero to working](#-quick-setup--zero-to-working)
2. [🍺 Homebrew — apps, CLIs & fonts](#-homebrew--apps-clis--fonts)
3. [📜 Scripts — .NET SDK (outside brew)](#-scripts--net-sdk-outside-brew)
4. [🌿 Git — config, SSH keys & signed commits](#-git--config-ssh-keys--signed-commits)
5. [🤖 Claude Code — config, hooks, plugins & skills](#-claude-code--config-hooks-plugins--skills)
6. [🧩 VS Code — settings, keybindings & extensions](#-vs-code--settings-keybindings--extensions)
7. [🐚 PowerShell — profile (Windows)](#-powershell--profile-windows)
8. [🔄 Maintaining this repo](#-maintaining-this-repo)
9. [🙏 Credits — third-party skills & plugins](#-credits--third-party-skills--plugins)

---

## ⚡ Quick setup — zero to working

The fastest path: bootstrap the package manager, clone this repo, install everything in the
Brewfile, then **hand the rest to Claude Code** — point the AI at this repo and let it run the
per-tool copy steps for you. 🤖

### 🍎 macOS

```bash
# 1. Homebrew (its installer also pulls in Xcode Command Line Tools → you get git for free)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"        # add brew to PATH for this shell

# 2. Clone this repo (no SSH key yet? use the HTTPS line instead)
git clone git@github.com-ranger:max-ranger/dotfiles.git ~/dotfiles
# git clone https://github.com/max-ranger/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 3. Install everything in one shot — CLIs, apps, fonts, AND VS Code extensions
brew bundle --file=brew/Brewfile

# 4. Install Claude Code, open it in the repo, and let the AI finish the setup
curl -fsSL https://claude.ai/install.sh | bash       # or: npm install -g @anthropic-ai/claude-code
claude
```

Then, inside `claude`, just ask:

> **"Set up this machine from these dotfiles — copy the Claude, VS Code and Git configs into
> place per the README, and run the .NET install script."**

Claude reads this README and runs the copy/install steps below for you. ✨

### 🪟 Windows

```powershell
# 1. winget ships with Windows 10/11 (App Installer). Get git, then clone:
winget install Git.Git
git clone https://github.com/max-ranger/dotfiles.git C:\Dev\ranger\dotfiles
cd C:\Dev\ranger\dotfiles

# 2. No Homebrew on Windows — winget/packages.json is the Brewfile's stand-in:
winget import --import-file winget\packages.json

# 3. VS Code extensions, read straight from the Brewfile (single source of truth):
Select-String -Path brew\Brewfile -Pattern '^vscode "(.+)"' |
  ForEach-Object { code --install-extension $_.Matches.Groups[1].Value }

# 4. Install Claude Code and let the AI finish the rest
irm https://claude.ai/install.ps1 | iex                # or: npm install -g @anthropic-ai/claude-code
claude
```

> 💡 Every `cp` / `Copy-Item` command below assumes you're **inside the cloned repo**. Re-run any
> of them to refresh from the repo — they just overwrite.

---

## 🍺 Homebrew — apps, CLIs & fonts

**What it is:** [Homebrew](https://brew.sh) is the de-facto package manager for macOS (and Linux).
One `brew install` grabs CLI tools (*formulae*), GUI apps (*casks*), and even fonts. The
[`brew/Brewfile`](brew/Brewfile) is a single manifest of **everything** this setup wants — it
also installs **VS Code extensions** (the `vscode "…"` lines), so editor plugins are managed here
too.

**Install Homebrew + everything:**

```bash
# macOS — install brew (step 1 of Quick Setup), then:
brew bundle --file=brew/Brewfile
```

```powershell
# Windows — Homebrew isn't supported. winget/packages.json mirrors the Brewfile
# (every tool that exists on winget, IDs verified against microsoft/winget-pkgs):
winget import --import-file winget\packages.json

# VS Code extensions aren't winget packages — install them from the Brewfile's
# `vscode "…"` lines, so the Brewfile stays the single source of truth:
Select-String -Path brew\Brewfile -Pattern '^vscode "(.+)"' |
  ForEach-Object { code --install-extension $_.Matches.Groups[1].Value }
```

**Windows substitutions & gaps** (macOS-only brews and their winget stand-ins):

| Brewfile entry | On Windows |
|---|---|
| `orbstack` / `docker` · `docker-compose` | `Docker.DockerDesktop` (bundles the CLI + compose) |
| `postgres-app` | `PostgreSQL.PostgreSQL.18` (full server + psql) |
| `supabase` | Not on winget — per project: `pnpm add -D supabase`, or [Scoop](https://supabase.com/docs/guides/local-development/cli/getting-started?platform=windows) |
| `sops` | Not on winget (`Mozilla.SOPS` was pulled in 2026) — grab `sops-v*.exe` from the [releases page](https://github.com/getsops/sops/releases) onto `PATH`, or [Scoop](https://scoop.sh) (`scoop install sops`) |
| `fvm` / `flutter` | Not on winget — grab the [fvm release binary](https://github.com/leoafarias/fvm/releases) onto `PATH`, let fvm manage Flutter |
| `font-hack-nerd-font` | Manual — download from [nerdfonts.com](https://www.nerdfonts.com/font-downloads), right-click → *Install* |
| `cocoapods` | macOS/iOS-only — skip |
| `htop` · `tree` | Skip — Task Manager / built-in `tree` |
| `whisper-cpp` · `appcleaner` · `dockdoor` · `boring-notch` | No equivalent — skip |
| `uv "basic-memory"` | Same as macOS: `uv tool install basic-memory` (uv is in the manifest) |
| `npm "corepack"` | Ships with Node — `fnm install --lts`, then `corepack enable` |

> 🔄 When the Brewfile changes, update [`winget/packages.json`](winget/packages.json) to match
> (`winget search <name>` finds the ID). No Chocolatey — winget + the fallbacks above cover
> everything.

### 🛠️ CLI tools (formulae)

| Tool | What it's for |
|---|---|
| `age` | Simple, modern file encryption — the key backend for `sops` |
| `awscli` | Official AWS command-line interface |
| `bat` | `cat` with syntax highlighting + git integration |
| `cocoapods` | Dependency manager for Cocoa / iOS projects |
| `coreutils` | GNU file, shell & text utilities |
| `direnv` | Auto-load/unload env vars per directory (`$PWD`) |
| `docker` · `docker-compose` | Container CLI + multi-container orchestration |
| `eza` | Modern, maintained `ls` replacement |
| `fnm` | Fast Node.js version manager |
| `fvm` | Flutter SDK version manager (per project) |
| `fzf` | Command-line fuzzy finder |
| `gh` | GitHub CLI |
| `git` | Version control (the whole point 😉) |
| `gnupg` | OpenPGP / GPG |
| `htop` | Interactive process viewer |
| `jq` | Command-line JSON processor |
| `pnpm` | Fast, disk-efficient package manager |
| `ripgrep` | Blazing-fast `grep` replacement |
| `sops` | Edit encrypted secrets files (YAML/JSON/ENV) in place, keyed with `age` |
| `starship` | Cross-shell prompt |
| `supabase` | Supabase CLI — local stack, migrations, type-gen (via `supabase/tap`) |
| `tree` | Render directories as trees |
| `uv` | Extremely fast Python package installer (Rust) |
| `wget` | Internet file retriever |
| `zoxide` | Smarter `cd` that learns your habits |

### 📦 Apps (casks)

| App | What it's for |
|---|---|
| `visual-studio-code` | Primary editor / IDE (see VS Code section) |
| `warp` | Rust-based terminal |
| `orbstack` | Fast, light Docker Desktop replacement |
| `postgres-app` | One-click PostgreSQL on macOS |
| `fork` | Git GUI client |
| `jetbrains-toolbox` | Manages Rider / WebStorm / etc. |
| `flutter` | Flutter SDK |
| `google-chrome` | Web browser |
| `obsidian` | Markdown knowledge base (also basic-memory's graph) |
| `claude` | Anthropic's Claude desktop app |
| `spotify` · `zoom` | Music · video calls |
| `dockdoor` | Window peeking on Dock hover |
| `boring-notch` | Turns the notch into a media widget 🎸 |
| `appcleaner` | Clean app uninstaller |
| `font-hack-nerd-font` | Hack Nerd Font (terminal + editor font) |

> ➕ The Brewfile also installs two non-brew bits via `brew bundle`: **`basic-memory`** (through
> `uv` — the knowledge-graph backend Claude uses) and **`corepack`** (through `npm`).

### 🖱️ Outside any package manager

- **[Synergy](https://symless.com/synergy)** — keyboard/mouse sharing across the Mac and the
  Windows PC. No Homebrew cask exists (only the GUI-less `synergy-core` formula), so on macOS
  install it manually from the [download page](https://symless.com/synergy/download). On
  Windows it's `Symless.Synergy` (included in `winget/packages.json`).

---

## 📜 Scripts — .NET SDK (outside brew)

**Why a script and not brew?** A few things are better installed from their vendor than from
Homebrew. The **.NET SDK** is the main one: Microsoft ships an official installer that handles
channels (LTS/STS) and side-by-side versions cleanly, so this repo uses that instead of a brew
formula.

[`scripts/install-dotnet.sh`](scripts/install-dotnet.sh) runs Microsoft's `dotnet-install.sh`
into `~/.dotnet`, pinned to the **latest LTS** by default. It's **idempotent** (skips if .NET is
already present) and wires `DOTNET_ROOT` + `PATH` into your `~/.zshrc`.

```bash
# macOS / Linux
./scripts/install-dotnet.sh          # LTS by default
./scripts/install-dotnet.sh STS      # latest standard-term release
./scripts/install-dotnet.sh 10.0     # pin a specific line
```

```powershell
# Windows — the shell script doesn't run; use winget (or the official installer)
winget install Microsoft.DotNet.SDK.10
```

After install, open a new shell (or `source ~/.zshrc`) and verify:

```bash
dotnet --version
```

### 🔄 Updating an existing .NET SDK

The install script deliberately **skips** if .NET is already present — updates go through the
same channel the SDK was originally installed from:

- **Microsoft .pkg installer** (SDK lives in `/usr/local/share/dotnet`): download and run the
  latest SDK .pkg — new patch versions install side-by-side, no uninstall needed.

  ```bash
  curl -fsSLO https://builds.dotnet.microsoft.com/dotnet/Sdk/10.0.302/dotnet-sdk-10.0.302-osx-arm64.pkg
  sudo installer -pkg dotnet-sdk-10.0.302-osx-arm64.pkg -target /
  dotnet --version
  ```

  Find the current latest version + URL on the
  [.NET 10 download page](https://dotnet.microsoft.com/download/dotnet/10.0) (or
  `curl -s https://builds.dotnet.microsoft.com/dotnet/release-metadata/10.0/releases.json | jq -r '.["latest-sdk"]'`).

- **dotnet-install.sh** (SDK lives in `~/.dotnet`, i.e. installed via the script): re-run the
  installer directly — it fetches the newest SDK in the channel side-by-side:

  ```bash
  curl -fsSL https://dot.net/v1/dotnet-install.sh | bash -s -- --channel LTS --install-dir ~/.dotnet
  ```

```powershell
# Windows
winget upgrade Microsoft.DotNet.SDK.10
```

---

## 🌿 Git — config, SSH keys & signed commits

**What it is:** Git is the distributed version-control system everything here runs on. Install it
via Homebrew (`brew "git"`, included in the Brewfile) or `winget install Git.Git` on Windows.

### 1️⃣ First-time identity

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"     # use a VERIFIED GitHub email
git config --global init.defaultBranch main
```

### 2️⃣ One SSH key for **both** auth and signing 🔑

This setup uses a single SSH key (`~/.ssh/ssh-key`) to *authenticate pushes* **and** *sign
commits*, so commits show the **Verified** ✅ badge on GitHub.

```bash
# Create the key if you don't have one yet
ssh-keygen -t ed25519 -C "you@example.com" -f ~/.ssh/ssh-key
ssh-add ~/.ssh/ssh-key                  # load into the agent
```

```powershell
# Windows (OpenSSH ships with Windows 10/11)
ssh-keygen -t ed25519 -C "you@example.com" -f $env:USERPROFILE\.ssh\ssh-key
```

**Tell git to SSH-sign** (global; lives in `~/.gitconfig`, which this repo does not track):

```bash
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/ssh-key
git config --global commit.gpgsign true
```

```powershell
# Windows — if signing fails, point git at OpenSSH's signer:
git config --global gpg.ssh.program "C:/Windows/System32/OpenSSH/ssh-keygen.exe"
```

**Register the key on GitHub _twice_ — ⚠️ gotcha #1.** *Authentication* and *Signing* keys are
separate entries even for identical key bytes. Add `~/.ssh/ssh-key.pub` once for push/pull, then
again at **Settings → SSH and GPG keys → New SSH key → Key type: _Signing Key_**. Also make sure
the commit email is a **verified** email on the account (**⚠️ gotcha #2** — else GitHub reports
`unverified_email`). GitHub verifies dynamically, so this flips already-pushed commits to Verified
too — no re-commit needed.

**Let git verify locally** (else `git log --show-signature` errors on a missing
`allowedSignersFile`):

```bash
mkdir -p ~/.config/git
echo "$(git config user.email) $(cat ~/.ssh/ssh-key.pub)" >> ~/.config/git/allowed_signers
git config --global gpg.ssh.allowedSignersFile ~/.config/git/allowed_signers
git log --show-signature -1     # should print: Good "git" signature for <email>
```

> 🔒 No keys or signer files are tracked in this repo — by design. `~/.ssh/*` and
> `~/.config/git/allowed_signers` are machine-local identity/secrets; the commands above
> regenerate the signer file from whatever key the machine already holds.

### 3️⃣ The project `.gitignore` 🚫

[`git/gitignore`](git/gitignore) is an all-purpose ignore tuned for this stack —
**C# / .NET · TypeScript · Vue · Tailwind · Node (Vite)** across **Visual Studio, JetBrains
(Rider/WebStorm) and VS Code**. It's reconciled against the official `github/gitignore` templates
and covers: secrets & `.env*`, keys/certs, `appsettings*.json`, `node_modules` & build output
(`dist/`, `bin/`, `obj/`), test/coverage artifacts, IDE folders, OS junk, and local Claude/AI
files. Lockfiles (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`) stay **committed**.

```bash
cp ~/dotfiles/git/gitignore ./.gitignore          # macOS / Linux
```
```powershell
Copy-Item C:\Dev\ranger\dotfiles\git\gitignore .\.gitignore   # Windows
```

---

## 🤖 Claude Code — config, hooks, plugins & skills

**What it is:** [Claude Code](https://claude.com/claude-code) is Anthropic's agentic coding tool
that runs in your terminal (and IDE). This section is the **global** setup that applies across
every project: instructions, automation hooks, enabled plugins, and personal skills.

**Install:**

```bash
curl -fsSL https://claude.ai/install.sh | bash       # macOS / Linux
# or: npm install -g @anthropic-ai/claude-code
```
```powershell
irm https://claude.ai/install.ps1 | iex              # Windows
```

> The `claude` **desktop app** is separate and installs via Homebrew (`cask "claude"`); the
> `anthropic.claude-code` **VS Code extension** installs via the Brewfile.

### ⚙️ Config files

- [`claude/CLAUDE.md`](claude/CLAUDE.md) — global user instructions, kept deliberately lean
  for modern (Claude 5-class) models: workflow routing (PRs via `pr-draft`, hook gates,
  loop bounds) + the **basic-memory** protocol. Detail that's only needed on demand lives in
  `claude/docs/` and is referenced by pointer.
- [`claude/docs/`](claude/docs) — on-demand references: `basic-memory-markup.md` (note
  structure & graph markup) and `loop-engineering.md` (closed-loop working guide).
- [`claude/settings.json`](claude/settings.json) — hooks wiring, `enabledPlugins` +
  `extraKnownMarketplaces` (installed on Claude Code startup), and flags (`effortLevel`, `theme`,
  push notifications).
- [`claude/hooks/`](claude/hooks) — deterministic gates (kept precisely because they don't
  depend on model behavior): **security gate**, **secure-commits**, **commit-hygiene**,
  **pre-commit checks**, **format-on-save**, the **memory-queue gate**, plus the two
  basic-memory hooks — the **session-context** injector (resolves the repo's project, or
  asks whether one should be created when there is none) and the **write gate**, which turns
  a Write/Edit into an unregistered folder under the vault root into a permission prompt so
  notes can't land somewhere basic-memory will never index. Notification hooks were retired
  in favor of Claude Code's native push/desktop notifications (`agentPushNotifEnabled`,
  `inputNeededNotifEnabled`).
- [`claude/skills/`](claude/skills) — user-level skills: `pr-draft` (own), plus the vendored
  `emil-design-eng` and `web-interface-guidelines` (see credits).
- [`claude/prompts/prompt-templates.md`](claude/prompts/prompt-templates.md) — reusable prompt
  snippets (pre-planning confidence gate, plan risk review, self code-review). Reference only —
  nothing to copy into place.

```bash
# macOS / Linux  (the /. form stays correct on re-runs — no nested dirs)
mkdir -p ~/.claude/hooks ~/.claude/docs ~/.claude/skills
cp    claude/CLAUDE.md      ~/.claude/CLAUDE.md
cp    claude/settings.json  ~/.claude/settings.json
cp -R claude/hooks/.        ~/.claude/hooks/
cp -R claude/docs/.         ~/.claude/docs/
cp -R claude/skills/.       ~/.claude/skills/
```

```powershell
# Windows  (\* + -Force stays correct on re-runs — no nested dirs)
"hooks", "docs", "skills" | ForEach-Object {
  New-Item -ItemType Directory -Force "$env:USERPROFILE\.claude\$_" | Out-Null }
Copy-Item        claude\CLAUDE.md      "$env:USERPROFILE\.claude\CLAUDE.md"
Copy-Item        claude\settings.json  "$env:USERPROFILE\.claude\settings.json"
Copy-Item -Recurse -Force claude\hooks\*  "$env:USERPROFILE\.claude\hooks\"
Copy-Item -Recurse -Force claude\docs\*   "$env:USERPROFILE\.claude\docs\"
Copy-Item -Recurse -Force claude\skills\* "$env:USERPROFILE\.claude\skills\"
```

### 🧠 Per-project template

[`claude/repo-template/CLAUDE.md`](claude/repo-template/CLAUDE.md) seeds a new project's
`.claude/CLAUDE.md` (auto-loads like a root `CLAUDE.md` and **composes** with the global one —
don't restate global rules in a project file). It's a **thin scaffold** — project description,
commands, architecture, gotchas — plus per-stack convention snippets in
[`claude/repo-template/stacks/`](claude/repo-template/stacks) (`typescript` · `vue` ·
`csharp-dotnet` · `flutter-dart`). Copy the base, append **only the stacks the repo uses**,
then fill the placeholders — generic best practices stay out; modern models don't need them,
and every appended section costs context in every session.

```bash
# macOS / Linux — base + e.g. a Vue+TS project:
mkdir -p .claude
cp  ~/dotfiles/claude/repo-template/CLAUDE.md          ./.claude/CLAUDE.md
cat ~/dotfiles/claude/repo-template/stacks/typescript.md \
    ~/dotfiles/claude/repo-template/stacks/vue.md      >> ./.claude/CLAUDE.md
```
```powershell
# Windows — base + e.g. a .NET project:
New-Item -ItemType Directory -Force .claude | Out-Null
Copy-Item C:\Dev\ranger\dotfiles\claude\repo-template\CLAUDE.md .\.claude\CLAUDE.md
Get-Content C:\Dev\ranger\dotfiles\claude\repo-template\stacks\csharp-dotnet.md |
  Add-Content .\.claude\CLAUDE.md
```

### ☁️ Cowork project-instructions template

[`claude/cowork-template/project-instructions.md`](claude/cowork-template/project-instructions.md)
is the generic template for **Claude Cowork Project** custom instructions — sparring-partner
role, the "Cowork never writes code" boundary (implementation stays with Claude Code in the
repo), and the basic-memory capture protocol. Nothing to copy into place on the machine:
fill in the placeholders (`<PROJECT>`, `<DESCRIPTION>`, `<REPO_PATH>`, `<SCOPE>`, `<OPS>`)
and paste the body into the Cowork project's instructions in the cloud UI.

### 🔌 Plugins & skills in use

Installed automatically on startup from `settings.json` → `enabledPlugins`.

**From the official `claude-plugins-official` marketplace:**
`frontend-design` · `claude-md-management` · `claude-code-setup` · `context7` ·
`typescript-lsp`.

> ✂️ Pruned in the Claude 5 era (behaviors now native to the model or the harness):
> `code-review`, `code-simplifier`, `skill-creator`, `feature-dev`, `commit-commands`,
> `security-guidance`, `andrej-karpathy-skills`, and `superpowers` (process ceremony that
> fights auto-mode; deterministic hooks carry the discipline instead). Design skills were
> consolidated to one per role — direction (`frontend-design`), refinement (`impeccable`),
> interaction polish (`emil-design-eng`) — dropping `ui-ux-pro-max` and
> `design-taste-frontend`.

**Third-party marketplaces** (declared in `extraKnownMarketplaces`):
- `impeccable` — [pbakaus/impeccable](https://github.com/pbakaus/impeccable)
- `warp` — [warpdotdev/claude-code-warp](https://github.com/warpdotdev/claude-code-warp)

**Vendored skills** (copied into `claude/skills/`, pinned): `pr-draft` (own), plus
`emil-design-eng` (see credits) and `web-interface-guidelines` — pruned copy of
[vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines)
`command.md` (MIT, pinned commit in the file header; on-demand UI audit, Vercel
brand-voice rules removed).

> 🧠 **basic-memory** backs the knowledge-graph protocol in `CLAUDE.md` — installed via the
> Brewfile (`uv "basic-memory"`) and rendered as an Obsidian vault.

---

## 🧩 VS Code — settings, keybindings & extensions

**What it is:** [Visual Studio Code](https://code.visualstudio.com) is the primary editor.
Install all the extensions below and it becomes a **basic but fully functioning IDE** for this
stack — **.NET / C# · PostgreSQL · Docker · Vue.js · Tailwind** — with formatting, linting,
IntelliSense, and Git tooling wired up. 🚀

> Extensions are **not** copied here — they install via the Brewfile (`vscode "…"` lines). Only
> `settings.json` and `keybindings.json` live in this folder.

```bash
# macOS / Linux
VSC="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSC"
cp vscode/settings.json    "$VSC/settings.json"
cp vscode/keybindings.json "$VSC/keybindings.json"
```

```powershell
# Windows
Copy-Item vscode\settings.json    "$env:APPDATA\Code\User\settings.json"
Copy-Item vscode\keybindings.json "$env:APPDATA\Code\User\keybindings.json"
```

### 🎛️ Settings highlights ([`vscode/settings.json`](vscode/settings.json))

- 🔤 **Font:** Hack Nerd Font Mono @ 12 (editor + terminal); **theme:** Dark 2026.
- ↹ **Indent:** 4 spaces, no auto-detect; trim trailing whitespace.
- ✨ **Format on save** via Prettier for JS/TS(X) + Astro; **ESLint** `fixAll` + add-missing-imports
  on save (other languages don't auto-format).
- 🤝 **GitHub Copilot** + next-edit suggestions on; **Claude Code** docked in the sidebar.
- 🌳 **GitLens / git-graph** tuned; `.env*` files highlighted as makefiles for visibility.

### ⌨️ Keybindings ([`vscode/keybindings.json`](vscode/keybindings.json))

Rebinds **column (box) selection** to `Shift+Cmd+↑/↓` (from the default `Shift+Alt+Cmd+↑/↓`) for
faster multi-cursor editing.

> 🪟 The keybindings use `cmd` (macOS). On Windows, swap `cmd` → `ctrl` in the copied file.

### 🧰 Extensions (installed via the Brewfile)

| Group | Extensions |
|---|---|
| **.NET / C#** | C# Dev Kit, C#, .NET Runtime |
| **Vue / Web / TS** | ESLint, Prettier, npm-intellisense, JS snippets, pretty-ts-errors, auto-close/rename-tag, styled-components, MDX |
| **Tailwind** | Tailwind CSS IntelliSense, Tailwind Docs, Headwind, Tailwind Fold |
| **Git** | Git Graph |
| **AI** | Claude Code |
| **Editor UX** | Better Comments, GitHub Theme, Color Highlight, Todo Highlight, dotenv, font-size shortcuts, status-bar format toggle |

---

## 🐚 PowerShell — profile (Windows)

**What it is:** the Windows counterpart of `~/.zshrc` — without it, the shell-integrated CLIs
from the manifest (fnm, starship, zoxide, direnv) install fine but never activate in a session.
[`powershell/Microsoft.PowerShell_profile.ps1`](powershell/Microsoft.PowerShell_profile.ps1)
wires them up, with every hook guarded so a missing tool degrades silently.

- **fnm** — `--use-on-cd`: auto-switches Node on entering a repo with `.nvmrc` / `.node-version`
- **direnv** — per-directory env vars (its `pwsh` hook needs PowerShell 7+, guarded)
- **zoxide** — `z` / `zi` smarter-cd commands
- **starship** — the prompt (kept last so it owns the `prompt` function)

Copy it to **both** profile locations so Windows PowerShell 5.1 and PowerShell 7 match
(`$docs` resolves the Documents folder even when OneDrive redirects it):

```powershell
$docs = [Environment]::GetFolderPath('MyDocuments')
"WindowsPowerShell", "PowerShell" | ForEach-Object {
  New-Item -ItemType Directory -Force "$docs\$_" | Out-Null
  Copy-Item powershell\Microsoft.PowerShell_profile.ps1 "$docs\$_\Microsoft.PowerShell_profile.ps1"
}
```

> 🍎 macOS equivalent: `~/.zshrc` — deliberately not tracked here (yet).

---

## 🔄 Maintaining this repo

Nothing is symlinked, so live files and this repo **don't sync automatically** — that's the point.
When you improve a hook, skill, setting, or template:

1. ✏️ Make the change in the live location (or here in the repo).
2. 🔁 Copy it the other way so both match — re-run the relevant command above, or copy the edited
   live file back into the repo.
3. 💾 Commit and push from this repo.

Refresh the Brewfile (and tracked VS Code extensions) from the current Mac:

```bash
brew bundle dump --file=brew/Brewfile --force
git commit -am "chore(brew): refresh package list"
```

When the Brewfile gains or loses a package, mirror the change in
[`winget/packages.json`](winget/packages.json) (and the substitutions table above) so the
Windows manifest stays in lockstep.

### 🙈 Not tracked here (on purpose)

- `~/.claude/projects/` — per-project memory and history, machine-local.
- `~/.claude/plugins/` — managed by Claude Code's plugin system, restored via `enabledPlugins`.
- `~/.claude/cache/`, `~/.claude/telemetry/`, session state — ephemeral.
- `~/.ssh/` keys and `~/.config/git/allowed_signers` — machine-local SSH identity/signer list.
- age private keys (`sops/age/keys.txt` in your config dir) — back them up out of band; lose
  the key and every file encrypted to it is unrecoverable.
- Anything matching `.gitignore` (env files, credentials, local overrides).

---

## 🙏 Credits — third-party skills & plugins

**Vendored skills** (copied into `claude/skills/`, pinned — refresh by re-downloading `SKILL.md`):
- `emil-design-eng` — [emilkowalski/skill](https://github.com/emilkowalski/skill)
- `web-interface-guidelines` — [vercel-labs/web-interface-guidelines](https://github.com/vercel-labs/web-interface-guidelines) (`command.md`, MIT, pruned)

**Plugin marketplaces** (declared in `settings.json`, installed by Claude Code on startup):
- `impeccable@impeccable` — [pbakaus/impeccable](https://github.com/pbakaus/impeccable)
- `warp@claude-code-warp` — [warpdotdev/claude-code-warp](https://github.com/warpdotdev/claude-code-warp)

Other enabled plugins come from the official `claude-plugins-official` marketplace.
