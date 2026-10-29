# 🧰 dotfiles

> A reference for setting up a new machine the way I like it — **Homebrew, Git, .NET, and
> VS Code**, each with notes on *what it's for* and *how to put it in place*. The Claude Code
> tooling (plugin, rules, templates) lives in [kitsune](https://github.com/max-ranger/kitsune).

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
3. [📜 Scripts — .NET SDK and the Windows move](#-scripts--net-sdk-and-the-windows-move)
4. [🌿 Git — config, SSH keys & signed commits](#-git--config-ssh-keys--signed-commits)
5. [🤖 Claude Code — lives in kitsune](#-claude-code--lives-in-kitsune)
6. [🧩 VS Code — settings, keybindings & extensions](#-vs-code--settings-keybindings--extensions)
7. [🐚 PowerShell — profile (Windows)](#-powershell--profile-windows)
8. [📁 Workspace layout — `~/Code`](#-workspace-layout--code)
9. [🔄 Maintaining this repo](#-maintaining-this-repo)

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
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile   # …and for every new shell, ahead of /usr/bin

# 2. Clone this repo (no SSH key yet? use the HTTPS line instead)
mkdir -p ~/Code/ranger-ecosystem
git clone git@github.com:max-ranger/dotfiles.git ~/Code/ranger-ecosystem/dotfiles
# git clone https://github.com/max-ranger/dotfiles.git ~/Code/ranger-ecosystem/dotfiles
cd ~/Code/ranger-ecosystem/dotfiles

# 3. Install everything in one shot — CLIs, apps, fonts, AND VS Code extensions
brew bundle --file=brew/Brewfile

# 4. Install Claude Code, open it in the repo, and let the AI finish the setup
curl -fsSL https://claude.ai/install.sh | bash       # or: npm install -g @anthropic-ai/claude-code
claude
```

Then, inside `claude`, just ask:

> **"Set up this machine from these dotfiles — copy the VS Code and Git configs per the README,
> run the .NET install script, then clone max-ranger/kitsune and follow its README for the
> Claude Code config and the ranger-claude plugin."**

Claude reads this README and runs the copy/install steps below for you. ✨

### 🪟 Windows

```powershell
# 1. winget ships with Windows 10/11 (App Installer). Get git, then clone:
winget install Git.Git
git clone https://github.com/max-ranger/dotfiles.git C:\Code\ranger-ecosystem\dotfiles
cd C:\Code\ranger-ecosystem\dotfiles

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
| `postgres-app` | `PostgreSQL.PostgreSQL.18` (full server + psql) |
| `supabase` | Not on winget — per project: `pnpm add -D supabase`, or [Scoop](https://supabase.com/docs/guides/local-development/cli/getting-started?platform=windows) |
| `sops` | Not on winget (`Mozilla.SOPS` was pulled in 2026) — grab `sops-v*.exe` from the [releases page](https://github.com/getsops/sops/releases) onto `PATH`, or [Scoop](https://scoop.sh) (`scoop install sops`) |
| `font-hack-nerd-font` | Manual — download from [nerdfonts.com](https://www.nerdfonts.com/font-downloads), right-click → *Install* |
| `cocoapods` | macOS/iOS-only — skip |
| `orbstack` | `Docker.DockerDesktop` (OrbStack provides `docker` + `compose` on macOS) |
| `flutter` | Not on winget — [flutter.dev](https://docs.flutter.dev/get-started/install/windows) installer |
| `whisper.cpp` · `appcleaner` · `dockdoor` · `boring-notch` | No equivalent — skip |
| `git-filter-repo` | Not on winget — `uv tool install git-filter-repo` (git picks it up from `PATH`) |
| `npm "@playwright/cli"` | Same as macOS: `npm i -g @playwright/cli` (after Node via fnm) |

> 🔄 When the Brewfile changes, update [`winget/packages.json`](winget/packages.json) to match
> (`winget search <name>` finds the ID). No Chocolatey — winget + the fallbacks above cover
> everything.

### 🛠️ CLI tools (formulae)

Only tools that are wired into the shell, required by a repo, or used by a hook. Pruned
2026-10-08 (see `docs/decisions/0004`); re-add anything with one line when it earns its place.

| Tool | What it's for |
|---|---|
| `age` · `sops` | File encryption + in-place editing of encrypted secrets (keyed with `age`) |
| `cocoapods` | iOS dependency manager (Pegasus builds) |
| `fnm` · `pnpm` | Node version manager (`--use-on-cd`) + package manager |
| `gh` · `git` · `git-filter-repo` | GitHub CLI, version control, history rewrite (break-glass) |
| `jq` · `ripgrep` · `shellcheck` | JSON, search, and shell lint — kitsune's hooks depend on them |
| `starship` | The prompt |
| `supabase` | Supabase CLI — local stack, migrations, type-gen (via `supabase/tap`) |
| `uv` | Python tool runner (fast `pipx`) |
| `whisper.cpp` | Local speech-to-text (`ggml-small` model in `~/.cache/whisper`) |

### 📦 Apps (casks)

| App | What it's for |
|---|---|
| `visual-studio-code` | Primary editor / IDE (see VS Code section) |
| `orbstack` | Fast, light Docker Desktop replacement |
| `postgres-app` | One-click PostgreSQL on macOS |
| `fork` | Git GUI client |
| `jetbrains-toolbox` | Manages Rider / WebStorm / etc. |
| `flutter` | Flutter SDK |
| `google-chrome` | Web browser |
| `claude` | Anthropic's Claude desktop app |
| `spotify` · `zoom` | Music · video calls |
| `dockdoor` | Window peeking on Dock hover |
| `boring-notch` | Turns the notch into a media widget 🎸 |
| `appcleaner` | Clean app uninstaller |
| `font-hack-nerd-font` | Hack Nerd Font (terminal + editor font) |

> ➕ The Brewfile also installs **`@playwright/cli`** through `npm` (`playwright-cli`, browser
> automation for coding agents).

### 🖱️ Outside any package manager

- **[Synergy](https://symless.com/synergy)** — keyboard/mouse sharing across the Mac and the
  Windows PC. No Homebrew cask exists (only the GUI-less `synergy-core` formula), so on macOS
  install it manually from the [download page](https://symless.com/synergy/download). On
  Windows it's `Symless.Synergy` (included in `winget/packages.json`).

---

## 📜 Scripts — .NET SDK and the Windows move

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

### 🪟 Moving a Windows machine to `C:\Code`

[`scripts/migrate-windows.ps1`](scripts/migrate-windows.ps1) takes a machine from the old
`C:\Dev\{ranger,clients,sandbox}` layout to the flat one described under
[Workspace layout](#-workspace-layout--code): it moves the repos, repairs git worktrees, renames
Claude Code's per-project state, zips the old notes vault and uninstalls basic-memory, and installs
the plugin from kitsune. Dry run by default; close the editors and
every Claude session before `-Apply`.

```powershell
pwsh -File scripts\migrate-windows.ps1            # prints every move and rename
pwsh -File scripts\migrate-windows.ps1 -Apply     # executes
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

**Tell git to SSH-sign** (global; lives in `~/.config/git/config` on the Mac, which this repo does not track):

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

Two rules in it carry the Claude setup: `.claude/*` with `!.claude/settings.json` keeps everything
in `.claude/` personal except the shared project settings, and `docs/plans/` is ignored because
plan-mode drafts are scratch ([kitsune ADR 0017](https://github.com/max-ranger/kitsune/blob/main/docs/decisions/0017-project-settings-committed-plan-drafts-scratch.md)).
The root `CLAUDE.md` and `AGENTS.md` are committed. Only `CLAUDE.local.md` stays personal.

```bash
cp ~/Code/ranger-ecosystem/dotfiles/git/gitignore ./.gitignore          # macOS / Linux
```
```powershell
Copy-Item C:\Code\ranger-ecosystem\dotfiles\git\gitignore .\.gitignore   # Windows
```

---

## 🤖 Claude Code — lives in kitsune

The global `CLAUDE.md`, the rules, `settings.json`, the `ranger-claude` plugin (gates, SDLC
skills, verifier agent), the repo template and the Cowork template moved to
[kitsune](https://github.com/max-ranger/kitsune) on 2026-10-29
([ADR 0024](docs/decisions/0024-claude-tooling-moved-to-kitsune.md)). Its README has the copy
steps, the plugin install and the hook table.

```bash
git clone git@github.com:max-ranger/kitsune.git ~/Code/kitsune
# then follow ~/Code/kitsune/README.md
```

The marketplace is still named `ranger` and the plugin `ranger-claude`, so a repo's
`.claude/settings.json` only changes its marketplace source to `max-ranger/kitsune`.

---

## 🧩 VS Code — settings, keybindings & extensions

**What it is:** [Visual Studio Code](https://code.visualstudio.com) is the primary editor.
Install the extensions below and it is a working editor for **.NET / C# · TypeScript ·
Tailwind**, with formatting, linting, IntelliSense and Git tooling wired up. There is no Vue,
Docker or PostgreSQL extension in the list; Rider and WebStorm cover those.

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
- 🤖 **Claude Code** docked in the sidebar. The Copilot and GitLens keys in the file are inert:
  neither extension is in the Brewfile.
- 🌳 **Git Graph** as the Git view; `.env*` files highlighted as makefiles for visibility.

### ⌨️ Keybindings ([`vscode/keybindings.json`](vscode/keybindings.json))

Rebinds **column (box) selection** to `Shift+Ctrl+↑/↓` and removes it from `Shift+Alt+Ctrl+↑/↓`,
for faster multi-cursor editing. The file uses `ctrl` on both platforms, so it copies to Windows
unchanged.

### 🧰 Extensions (installed via the Brewfile)

| Group | Extensions |
|---|---|
| **.NET / C#** | C# Dev Kit, C#, .NET Runtime |
| **Web / TS** | ESLint, Prettier, npm-intellisense, JS snippets, pretty-ts-errors, auto-close/rename-tag, styled-components, MDX |
| **Tailwind** | Tailwind CSS IntelliSense, Tailwind Docs, Headwind, Tailwind Fold |
| **Git** | Git Graph |
| **AI** | Claude Code |
| **Editor UX** | Better Comments, GitHub Theme, Color Highlight, Todo Highlight, dotenv, font-size shortcuts, status-bar format toggle |

---

## 🐚 PowerShell — profile (Windows)

**What it is:** the Windows counterpart of `~/.zshrc` — without it, the shell-integrated CLIs
from the manifest (fnm, starship) install fine but never activate in a session.
[`powershell/Microsoft.PowerShell_profile.ps1`](powershell/Microsoft.PowerShell_profile.ps1)
wires them up, with every hook guarded so a missing tool degrades silently.

- **fnm** — `--use-on-cd`: auto-switches Node on entering a repo with `.nvmrc` / `.node-version`
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

## 📁 Workspace layout — `~/Code`

One folder, flat by project. A repo sits directly under `~/Code`; the only grouping folder is
`ranger-ecosystem/`, whose name is load-bearing (product repos reach their siblings through
`../ranger-ecosystem/<repo>`). Decision: [`docs/decisions/0015`](docs/decisions/0015-flat-code-workspace.md).

```text
~/Code/
  handbook/             cross-repo decisions, shared-stack as-built, non-code projects (private repo)
  <product>/            one folder per product repo
  kitsune/              Claude Code tooling and the agent OS
  ranger-ecosystem/     dotfiles · ranger-infra · ranger-vue · ranger-dotnet · ranger-app-template
  sandbox/              throwaways
  archive/              inactive checkouts
  assets/               brand assets and test data that must stay outside git (each with a README)
  backups/              database dumps and pre-rewrite mirrors, never committed
```

Knowledge follows the same shape: *describes one repo → that repo's `docs/`; spans repos or has no
repo → `handbook/docs/`.* No notes outside git.

> 🪟 Windows uses the same layout under `C:\Code`. [`scripts/migrate-windows.ps1`](scripts/migrate-windows.ps1)
> performs the move from `C:\Dev` (dry run by default, `-Apply` to execute), renames Claude Code's
> per-project state, retires basic-memory and installs the plugin from kitsune — the same steps the Mac went through.

---

## 🔄 Maintaining this repo

Nothing is symlinked, so live files and this repo **don't sync automatically** — that's the point.
When you improve a setting, script, or template:

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


