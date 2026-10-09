# PowerShell profile — the Windows counterpart of ~/.zshrc on the Mac.
# Tracked in the dotfiles repo (powershell/); copy to BOTH profile locations per the README
# so Windows PowerShell 5.1 and PowerShell 7 behave the same.
# Every hook is guarded: a missing tool degrades silently instead of breaking every new shell.

# fnm — Node version manager; auto-switches versions on cd (.nvmrc / .node-version)
if (Get-Command fnm -ErrorAction SilentlyContinue) {
  fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression
}

# starship — cross-shell prompt (keep last so it owns the prompt function)
if (Get-Command starship -ErrorAction SilentlyContinue) {
  starship init powershell | Out-String | Invoke-Expression
}
