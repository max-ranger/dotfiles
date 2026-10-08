<#
.SYNOPSIS
  Move the Windows machine from C:\Dev\{ranger,clients,sandbox} to the flat C:\Code layout
  (dotfiles docs/decisions/0015) and retire basic-memory there, the way the Mac was moved.

.DESCRIPTION
  Dry run by default: prints every move and every change. Re-run with -Apply to execute.
  Idempotent: a step whose target already exists is skipped. Nothing is deleted except
  basic-memory's state folder (its notes vault is zipped into C:\Code\backups first).

  Steps: (1) move repos, backups and assets; (2) rename Claude Code's per-project state folders
  and rewrite the project keys in ~/.claude.json; (3) zip + retire basic-memory;
  (4) copy the Claude config from this repo and install the ranger-claude plugin;
  (5) copy the PowerShell profile. Close VS Code, Rider and every Claude session first.

.EXAMPLE
  pwsh -File C:\Dev\ranger\ranger-ecosystem\dotfiles\scripts\migrate-windows.ps1          # plan
  pwsh -File C:\Dev\ranger\ranger-ecosystem\dotfiles\scripts\migrate-windows.ps1 -Apply   # do it
#>
[CmdletBinding()]
param(
  [switch]$Apply,
  [string]$Old = 'C:\Dev',
  [string]$New = 'C:\Code'
)
$ErrorActionPreference = 'Stop'
$home_ = $env:USERPROFILE
function Say($msg) { Write-Host $msg }
function Do-Step($label, [scriptblock]$action) {
  if ($Apply) { & $action; Say "  done   $label" } else { Say "  would  $label" }
}

# ---------------------------------------------------------------- 1. the moves
# Target for a path under $Old. Mirrors the Mac move: product repos go to the root,
# ranger-ecosystem keeps its name (relative paths depend on it), clients go to archive.
function Target([string]$rel) {
  if ($rel -match '^ranger\\ranger-ecosystem(\\.*)?$')        { return "$New\ranger-ecosystem$($Matches[1])" }
  if ($rel -match '^ranger\\backups(\\.*)?$')                 { return "$New\backups$($Matches[1])" }
  if ($rel -match '^ranger\\docs(\\.*)?$')                    { return "$New\assets$($Matches[1])" }
  if ($rel -match '^ranger\\(.+)$')                            { return "$New\$($Matches[1])" }
  if ($rel -match '^(clients\\)?WHK\\welserhundesportklub$')   { return "$New\welserhundesportklub" }
  if ($rel -match '^(clients\\)?WHK\\(.+)$')                   { return "$New\assets\whk-$($Matches[2].ToLower() -replace ' ','-')" }
  if ($rel -match '^(clients\\)?(ABB|codebeam)(\\.*)?$')       { return "$New\archive\$($Matches[2])$($Matches[3])" }
  if ($rel -match '^sandbox(\\.*)?$')                          { return "$New\sandbox$($Matches[1])" }
  return "$New\$(Split-Path $rel -Leaf)"
}
if (-not (Test-Path $Old)) { Say "Nothing to move: $Old does not exist."; }
$moves = @()
if (Test-Path $Old) {
  # top-level units to move: every git repo (depth <= 4), plus the known non-repo folders
  $repos = Get-ChildItem $Old -Directory -Recurse -Depth 3 | Where-Object { Test-Path (Join-Path $_.FullName '.git') }
  $units = @($repos | ForEach-Object { $_.FullName })
  foreach ($extra in @("$Old\ranger\backups", "$Old\ranger\docs", "$Old\sandbox", "$Old\clients\WHK\WHK Design Handoff", "$Old\clients\ABB", "$Old\clients\codebeam")) {
    if (Test-Path $extra) { $units += $extra }
  }
  # a unit inside another unit (e.g. a repo under archive\ABB) moves with its parent
  $all = @($units | Sort-Object -Unique)
  $units = @($all | Where-Object { $u = $_; -not ($all | Where-Object { $_ -ne $u -and $u.StartsWith("$_\") }) })
  foreach ($u in $units) {
    $rel = $u.Substring($Old.Length).TrimStart('\')
    $moves += [pscustomobject]@{ From = $u; To = (Target $rel) }
  }
}
Say "`n== 1. Moves ($Old -> $New)"
foreach ($m in $moves) {
  if (Test-Path $m.To) { Say "  skip   $($m.From)  ->  $($m.To)  (target exists)"; continue }
  Do-Step "$($m.From)  ->  $($m.To)" {
    New-Item -ItemType Directory -Force (Split-Path $m.To -Parent) | Out-Null
    Move-Item -LiteralPath $m.From -Destination $m.To
  }
}
# git worktrees record absolute paths: repair after the move
if ($Apply) {
  foreach ($m in $moves) {
    if (Test-Path (Join-Path $m.To '.git') -PathType Container) {
      try { & git -C $m.To worktree prune 2>&1 | Out-Null; & git -C $m.To worktree repair 2>&1 | Out-Null } catch { Say "  warn   worktree repair in $($m.To): $_" }
    }
  }
}
# this script lives inside the dotfiles repo, which may itself have just moved
$repo = Split-Path $PSScriptRoot -Parent
$hit = $moves | Where-Object { $repo -eq $_.From -or $repo.StartsWith($_.From + '\') } | Select-Object -First 1
if ($hit -and $Apply) { $repo = $hit.To + $repo.Substring($hit.From.Length) }

# ---------------------------------------------------- 2. Claude Code per-project state
# Claude Code keys project state by path: C:\Dev\ranger\cerberus  ->  C--Dev-ranger-cerberus
function Enc([string]$p) { return ($p -replace '[:\\/]', '-') }
$projects = Join-Path $home_ '.claude\projects'
Say "`n== 2. Claude Code project folders and ~/.claude.json keys"
if (Test-Path $projects) {
  foreach ($m in $moves) {
    $from = Join-Path $projects (Enc $m.From); $to = Join-Path $projects (Enc $m.To)
    if (Test-Path $from) {
      if (Test-Path $to) { Say "  skip   $(Split-Path $from -Leaf) (target folder exists; merge by hand)"; continue }
      Do-Step "rename $(Split-Path $from -Leaf)  ->  $(Split-Path $to -Leaf)" { Move-Item -LiteralPath $from -Destination $to }
    }
  }
  $left = Get-ChildItem $projects -Directory | Where-Object { $_.Name -like (Enc $Old) + '-*' }
  foreach ($l in $left) { Say "  note   $($l.Name) still named after $Old (no matching move; a grouping-folder session or a repo not under the known layout)" }
}
$cfg = Join-Path $home_ '.claude.json'
if (Test-Path $cfg) {
  Do-Step "rewrite project keys in $cfg (backup: .claude.json.pre-code-move)" {
    Copy-Item $cfg "$cfg.pre-code-move" -Force
    $j = Get-Content $cfg -Raw | ConvertFrom-Json
    $keys = @($j.projects.PSObject.Properties.Name)
    foreach ($k in $keys) {
      $hit = $moves | Where-Object { $k -eq $_.From -or $k.StartsWith($_.From + '\') } | Select-Object -First 1
      if ($hit) {
        $nk = $hit.To + $k.Substring($hit.From.Length)
        if (-not $j.projects.PSObject.Properties[$nk]) { $j.projects | Add-Member -NotePropertyName $nk -NotePropertyValue $j.projects.$k }
        $j.projects.PSObject.Properties.Remove($k)
      }
    }
    if ($j.mcpServers -and $j.mcpServers.PSObject.Properties['basic-memory']) { $j.mcpServers.PSObject.Properties.Remove('basic-memory') }
    [IO.File]::WriteAllText($cfg, ($j | ConvertTo-Json -Depth 50), (New-Object System.Text.UTF8Encoding $false))   # no BOM: Claude Code parses it with JSON.parse
  }
}

# ------------------------------------------------------------ 3. retire basic-memory
Say "`n== 3. basic-memory"
$bmCfg = Join-Path $home_ '.basic-memory\config.json'
$vaults = @()
if (Test-Path $bmCfg) {
  $bm = Get-Content $bmCfg -Raw | ConvertFrom-Json
  $vaults = @($bm.projects.PSObject.Properties.Value.path) | Sort-Object -Unique
}
if ($env:BASIC_MEMORY_HOME -and (Test-Path $env:BASIC_MEMORY_HOME)) { $vaults += $env:BASIC_MEMORY_HOME }
$vaultRoots = @($vaults | ForEach-Object { if (Test-Path $_) { $_ } } | Sort-Object -Unique)
$vaultRoots = @($vaultRoots | Where-Object { $v = $_; -not ($vaultRoots | Where-Object { $_ -ne $v -and $v.StartsWith("$_\") }) })
if ($vaultRoots.Count -gt 0) {
  $zip = "$New\backups\basic-memory-vaults-windows-$(Get-Date -Format yyyy-MM-dd).zip"
  Do-Step "zip $($vaultRoots -join ', ')  ->  $zip  (the vault folders stay in place; migrate or delete them by hand)" {
    New-Item -ItemType Directory -Force (Split-Path $zip -Parent) | Out-Null
    if (-not (Test-Path $zip)) { Compress-Archive -LiteralPath $vaultRoots -DestinationPath $zip }
  }
} else { Say "  none   no basic-memory vault found" }
if (Get-Command uv -ErrorAction SilentlyContinue) { Do-Step "uv tool uninstall basic-memory" { try { & uv tool uninstall basic-memory 2>&1 | Out-Null } catch { Say "  warn   $_" } } }
if (Test-Path (Join-Path $home_ '.basic-memory')) { Do-Step "remove $home_\.basic-memory (index + logs; the notes are in the zip)" { Remove-Item -LiteralPath (Join-Path $home_ '.basic-memory') -Recurse -Force } }
if ([Environment]::GetEnvironmentVariable('BASIC_MEMORY_HOME', 'User')) { Do-Step "remove the user environment variable BASIC_MEMORY_HOME" { [Environment]::SetEnvironmentVariable('BASIC_MEMORY_HOME', $null, 'User') } }

# ------------------------------------------------- 4. Claude config + plugin from this repo
Say "`n== 4. Claude Code config from $repo"
$claude = Join-Path $home_ '.claude'
Do-Step "copy CLAUDE.md, settings.json, rules\, docs\ into $claude (hooks\ and skills\ are retired there)" {
  foreach ($d in 'rules', 'docs') { New-Item -ItemType Directory -Force (Join-Path $claude $d) | Out-Null }
  Copy-Item (Join-Path $repo 'claude\CLAUDE.md') (Join-Path $claude 'CLAUDE.md') -Force
  Copy-Item (Join-Path $repo 'claude\settings.json') (Join-Path $claude 'settings.json') -Force
  Copy-Item (Join-Path $repo 'claude\rules\*') (Join-Path $claude 'rules') -Recurse -Force
  Copy-Item (Join-Path $repo 'claude\docs\*') (Join-Path $claude 'docs') -Recurse -Force
  foreach ($gone in 'hooks', 'skills\pr-draft', 'skills\emil-design-eng', 'skills\web-interface-guidelines', 'memory-queue') {
    $p = Join-Path $claude $gone; if (Test-Path $p) { Remove-Item -LiteralPath $p -Recurse -Force }
  }
}
if (Get-Command claude -ErrorAction SilentlyContinue) {
  Do-Step "claude plugin marketplace add max-ranger/dotfiles; claude plugin install ranger-claude@ranger" {
    try { & claude plugin marketplace add max-ranger/dotfiles 2>&1 | Out-Null } catch { }
    try { & claude plugin install ranger-claude@ranger 2>&1 | Out-Host } catch { Say "  warn   $_" }
  }
} else { Say "  skip   claude CLI not on PATH; run the two plugin commands after installing it" }

# ------------------------------------------------------------- 5. PowerShell profile
Say "`n== 5. PowerShell profile"
$docs = [Environment]::GetFolderPath('MyDocuments')
foreach ($shell in 'WindowsPowerShell', 'PowerShell') {
  $dst = Join-Path $docs "$shell\Microsoft.PowerShell_profile.ps1"
  Do-Step "copy profile -> $dst" {
    New-Item -ItemType Directory -Force (Split-Path $dst -Parent) | Out-Null
    Copy-Item (Join-Path $repo 'powershell\Microsoft.PowerShell_profile.ps1') $dst -Force
  }
}

Say ""
if (-not $Apply) { Say "Dry run. Re-run with -Apply to execute. Then open a new shell and start Claude Code inside a repo under $New." }
else {
  Say "Done. Still by hand: re-point Fork/Rider/WebStorm at $New, re-trust the folders in Claude Code and the IDEs,"
  Say "re-run 'flutter pub get' / 'pnpm install' / 'dotnet restore' where generated files carried absolute paths,"
  Say "and decide what to do with the old notes vault (zip in $New\backups)."
}
