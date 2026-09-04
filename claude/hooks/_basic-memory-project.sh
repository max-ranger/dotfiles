#!/bin/bash
# Shared helper: resolve the basic-memory project for a working directory.
#
#   source ~/.claude/hooks/_basic-memory-project.sh
#   bm_resolve_project "$CWD"
#
# Exports:
#   BM_PROJECT   registered project slug (key in ~/.basic-memory/config.json), or ""
#   BM_NAME      the project's display name (basename of its path), for `bm --project`
#   BM_VIA       how it matched: repo | parent | cwd | cwd-parent | ""
#   BM_REPO      basename of the git root when CWD is inside a repo, else ""
#   BM_QUEUE     ~/.claude/memory-queue/<BM_PROJECT>.md (only meaningful if BM_PROJECT set)
#
# Rules (CLAUDE.md "Knowledge Memory"): one project per big project. Inside a git repo the
# project is the git-root folder name, or -- multi-repo layout -- the parent folder's name.
# Outside a repo (workspace root, cowork) the cwd basename and its parent are tried, so a
# session opened at "C:\Dev\CADS\Global Data Store" still finds `global-data-store`.
# basic-memory slugifies project names (lower-case, spaces -> hyphens); compare slugs.

bm_resolve_project() {
  local cwd="$1"
  local config="$HOME/.basic-memory/config.json"
  BM_PROJECT=""; BM_NAME=""; BM_VIA=""; BM_REPO=""; BM_QUEUE=""

  [ -n "$cwd" ] || return 0
  [ -f "$config" ] || return 0

  local repo_root
  repo_root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)

  local -a cands vias
  if [ -n "$repo_root" ]; then
    BM_REPO=$(basename "$repo_root")
    cands=("$BM_REPO" "$(basename "$(dirname "$repo_root")")")
    vias=(repo parent)
  else
    cands=("$(basename "$cwd")" "$(basename "$(dirname "$cwd")")")
    vias=(cwd cwd-parent)
  fi

  local i slug
  for i in 0 1; do
    slug=$(printf '%s' "${cands[$i]}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
    if jq -e --arg p "$slug" '.projects[$p]' "$config" >/dev/null 2>&1; then
      BM_PROJECT="$slug"
      BM_VIA="${vias[$i]}"
      BM_NAME=$(basename "$(jq -r --arg p "$slug" '.projects[$p].path' "$config" | tr -d '\r' | tr '\\' '/')")
      break
    fi
  done

  [ -n "$BM_PROJECT" ] && BM_QUEUE="$HOME/.claude/memory-queue/${BM_PROJECT}.md"
  export BM_PROJECT BM_NAME BM_VIA BM_REPO BM_QUEUE
  return 0
}
