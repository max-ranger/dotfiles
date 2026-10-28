#!/bin/bash
# Shared helper for the git gates: find every git invocation in a Bash command
# string, with its subcommand, its arguments and the repo it acts on.
#
#   source "$(dirname "$0")/_git-cmd.sh"
#   gc_parse "$COMMAND" "$SESSION_CWD"         # fills GC_N and the GC_* arrays
#   for i in $(gc_find commit); do             # every `git … commit` in the command
#     gc_git "$i" diff --cached --name-only    # git, pointed at that invocation's repo
#     gc_flag "$i" a --all && …                # -a, a cluster like -am, or --all
#     gc_known "$i" || …                       # its repo is a guess (a variable path)
#     gc_pending "$i"                          # paths an earlier `git add` / -a adds
#   done
#
# Understood: quoting ('…', "…", $'…', \), comments, ; && || | & and newlines,
# ( ) subshells, $( ) ` ` <( ) substitutions (parsed as commands of their own),
# heredoc and here-string bodies (data, unless a shell reads its script from them:
# `bash <<'EOF'`), redirections, NAME=value prefixes, the wrappers
# env/command/builtin/exec/nohup/time, `bash|sh|zsh -c '…'` and `eval …` (parsed
# again), cd/pushd (followed through the command, undone when a subshell
# closes), and git's global options before the subcommand: -C (cumulative, as
# in git), -c, --git-dir, --work-tree, --namespace, --config-env, --attr-source
# and every flag (-p, -P, --no-pager, --bare, …).
# Quoted text is data: `echo "git commit"` is not a git invocation.
# Not understood: git or shell aliases, functions, GIT_DIR=… prefixes, and
# variables other than $HOME: a `-C "$X"`, `cd "$X"` or `cd -` keeps the previous
# directory (the session's repo, for callers that need one) and marks the
# invocation's repo unknown (GC_KNOWN=0), so a gate can ask instead of judging the
# wrong repo. An absolute path later in the command makes it known again.
#
# bash 3.2 (macOS /bin/bash): no namerefs, no associative arrays. The parser's
# helpers share state through bash's dynamic scoping (the callers' locals). It runs
# in the C locale, reads plain runs in 512-byte windows and leaves heredoc bodies to
# one grep each, so a long heredoc (a file write) stays linear. Each token still
# costs O(length) in bash, so only commands of >100 KB of short words get slow.

_GC_US=$'\x1f'                               # terminates each stored argument
_GC_SPECIAL=$' \t\n\'"\\\\$`;&|()<>'         # ends a run of plain word text
_GC_DQ=$'"\\\\$`'                            # ends a run of text inside "…"

# Finish the current word of _gc_tok: a redirection target is dropped, a heredoc
# delimiter is queued, anything else becomes a W token.
_gc_end() {
  [ "$inw" = 1 ] || return 0
  case $pend in
    r) ;;
    h|H) hd+=("$pend$w") ;;
    b) [ "$emit" = 1 ] && _T+=("H$w") ;;        # here-string: a body, like a heredoc
    *) [ "$emit" = 1 ] && _T+=("W$w") ;;
  esac
  w=''; inw=0; pend=''
}
_gc_op() { _gc_end; pend=''; [ "$emit" = 1 ] && _T+=("O$1"); }

# _gc_upto <pos> <chars>: _R = s from <pos> up to the first of <chars> (a bracket
# expression body), or to the end. Reads 512-char windows instead of the whole rest.
_gc_upto() {
  local k=$1 win cut
  _R=''
  while :; do
    win=${s:k:512}; cut=${win%%[$2]*}
    _R+=$cut
    [ "${#cut}" -lt 512 ] && return 0
    k=$((k + 512))
  done
}

# At s[i] = $( <( or >(: scan to the closing ) and keep the inside as an S token.
_gc_capture() {
  _gc_tok "$s" $((i + 2)) 0
  [ "$emit" = 1 ] && _T+=("S${s:i+2:_P-i-3}")
  w+='$()'; inw=1; i=$_P
}

# At s[i] = $ or `: take a $( … ) or ` … ` as an S token, or a plain $.
_gc_sub() {
  local j c2
  if [ "${s:i:2}" = '$(' ]; then
    _gc_capture
  elif [ "${s:i:1}" = '`' ]; then
    j=$((i + 1))
    while [ "$j" -lt "$n" ]; do
      c2=${s:j:1}
      [ "$c2" = '`' ] && break
      [ "$c2" = '\' ] && j=$((j + 1))
      j=$((j + 1))
    done
    [ "$emit" = 1 ] && _T+=("S${s:i+1:j-i-1}")
    w+='$()'; inw=1; i=$((j + 1))
  else
    w+='$'; inw=1; i=$((i + 1))
  fi
}

# _gc_tok <string> <pos> <emit>: tokenize from <pos>. With emit=1, append to the
# caller's _T: "W<word>" (quotes removed), "O<operator>", "S<substitution>",
# "H<heredoc or here-string body>".
# With emit=0 it only scans a $( … ): it stops after the `)` that closes it and
# leaves that position in _P.
_gc_tok() {
  local s=$1 i=$2 emit=$3 n=${#1} c rest pre j d t blen w='' inw=0 pend='' depth=0 _R
  local -a hd=()
  while [ "$i" -lt "$n" ]; do
    c=${s:i:1}
    case $c in
      ' '|$'\t') _gc_end; i=$((i + 1)) ;;
      $'\n')
        _gc_end; i=$((i + 1))
        for d in "${hd[@]}"; do                # the heredoc bodies start here
          t=${d:0:1}; d=${d:1}; j=$i; blen=$((n - i))
          # grep finds the delimiter line (byte offset:line) in one linear pass;
          # <<- allows tabs before it
          if [ "$t" = h ]; then
            pre=$(printf '%s\n' "${s:i}" | LC_ALL=C grep -bxFm1 -- "$d")
          else
            pre=$(printf '%s\n' "${s:i}" | LC_ALL=C grep -bxEm1 -- \
              "$(printf '\t')*$(printf '%s' "$d" | sed 's/[][\.*^$+?(){}|/]/\\&/g')")
          fi
          if [ -n "$pre" ]; then blen=${pre%%:*}; rest=${pre#*:}; i=$((i + blen + ${#rest} + 1)); else i=$n; fi
          [ "$emit" = 1 ] && _T+=("H${s:j:blen}")
        done
        hd=(); _gc_op ';' ;;
      '#')
        if [ "$inw" = 1 ]; then w+=$c; i=$((i + 1))
        else _gc_upto "$i" $'\n'; i=$((i + ${#_R})); fi ;;
      "'")
        _gc_upto $((i + 1)) "'"
        w+=$_R; inw=1; i=$((i + ${#_R} + 2)) ;;
      '"')
        inw=1; i=$((i + 1))
        while [ "$i" -lt "$n" ]; do
          _gc_upto "$i" "$_GC_DQ"
          w+=$_R; i=$((i + ${#_R}))
          c=${s:i:1}
          case $c in
            '"') i=$((i + 1)); break ;;
            '\')
              case ${s:i+1:1} in
                $'\n') ;;
                '"'|'\'|'$'|'`') w+=${s:i+1:1} ;;
                *) w+="\\${s:i+1:1}" ;;
              esac
              i=$((i + 2)) ;;
            '$'|'`') _gc_sub ;;
            *) break ;;
          esac
        done ;;
      '\')
        [ "${s:i+1:1}" = $'\n' ] || { w+=${s:i+1:1}; inw=1; }
        i=$((i + 2)) ;;
      '$')
        if [ "${s:i:2}" = "\$'" ]; then        # $'…': up to the next unescaped '
          j=$((i + 2))
          while [ "$j" -lt "$n" ]; do
            [ "${s:j:1}" = "'" ] && break
            [ "${s:j:1}" = '\' ] && j=$((j + 1))
            j=$((j + 1))
          done
          w+=${s:i+2:j-i-2}; inw=1; i=$((j + 1))
        else
          _gc_sub
        fi ;;
      '`') _gc_sub ;;
      ';') _gc_op ';'; i=$((i + 1)) ;;
      '&')
        case ${s:i+1:1} in
          '&') _gc_op '&&'; i=$((i + 2)) ;;
          '>') _gc_end; pend=r; i=$((i + 2)); [ "${s:i:1}" = '>' ] && i=$((i + 1)) ;;
          *) _gc_op '&'; i=$((i + 1)) ;;
        esac ;;
      '|')
        case ${s:i+1:1} in
          '|') _gc_op '||'; i=$((i + 2)) ;;
          '&') _gc_op '|'; i=$((i + 2)) ;;
          *) _gc_op '|'; i=$((i + 1)) ;;
        esac ;;
      '(') _gc_op '('; depth=$((depth + 1)); i=$((i + 1)) ;;
      ')')
        if [ "$emit" = 0 ] && [ "$depth" = 0 ]; then _gc_end; _P=$((i + 1)); return 0; fi
        _gc_op ')'; depth=$((depth - 1)); i=$((i + 1)) ;;
      '<'|'>')
        if [ "$inw" = 1 ] && [[ $w =~ ^[0-9]+$ ]]; then w=''; inw=0; else _gc_end; fi  # 2>: an fd
        case ${s:i:3} in
          '<<<') pend=b; i=$((i + 3)) ;;
          '<<-') pend=H; i=$((i + 3)) ;;
          *)
            case ${s:i:2} in
              '<<') pend=h; i=$((i + 2)) ;;
              '<('|'>(') _gc_capture ;;
              '>>'|'>&'|'<&'|'<>'|'>|') pend=r; i=$((i + 2)) ;;
              *) pend=r; i=$((i + 1)) ;;
            esac ;;
        esac ;;
      *)
        _gc_upto "$i" "$_GC_SPECIAL"
        [ -n "$_R" ] || _R=$c
        w+=$_R; inw=1; i=$((i + ${#_R})) ;;
    esac
  done
  _gc_end; _P=$((n + 1))
}

# _gc_path <base> <path>: resolve <path> against <base> into _GC_R; _GC_ABS=1 when
# the result does not depend on <base>. Fails for a path whose value is not known
# here ($VAR other than $HOME, a substitution).
# ranger: shortcut — callers then keep the previous directory (the session's repo,
# the pre-parser behaviour) instead of tracking assignments made in the command.
# Upgrade (track `VAR=…; cd $VAR`) when a gate judges the wrong repo because of it.
_gc_path() {
  local p=$2
  case $p in
    \~|\~/*) p=$HOME${p#\~} ;;
    '$HOME'|'$HOME/'*) p=$HOME${p#\$HOME} ;;
    '${HOME}'|'${HOME}/'*) p=$HOME${p#\$\{HOME\}} ;;
  esac
  case $p in *'$'*) return 1 ;; esac
  case $p in
    '') _GC_R=$1; _GC_ABS=0 ;;
    /*|[A-Za-z]:[\\/]*) _GC_R=$p; _GC_ABS=1 ;;
    *) _GC_R=$1/$p; _GC_ABS=0 ;;
  esac
}

# _gc_git <arg>...: record one git invocation (in _gc_cmd's dir; known as _gc_cmd's).
_gc_git() {
  local d=$dir k=$known gd='' wt='' a args=''
  while [ $# -gt 0 ]; do
    case $1 in
      -C|-c|--git-dir|--work-tree|--namespace|--config-env|--attr-source)
        [ $# -ge 2 ] || return 0
        case $1 in
          -C)                                   # each -C is relative to the one before
            if _gc_path "$d" "$2"; then d=$_GC_R; [ "$_GC_ABS" = 0 ] || k=1; else k=0; fi ;;
          --git-dir) gd=$2 ;;
          --work-tree) wt=$2 ;;
        esac
        shift 2 ;;
      --git-dir=*) gd=${1#*=}; shift ;;
      --work-tree=*) wt=${1#*=}; shift ;;
      -*) shift ;;
      *) break ;;
    esac
  done
  [ $# -gt 0 ] || return 0
  # a relative --git-dir / --work-tree is relative to the final -C directory
  if [ -n "$gd" ]; then
    if _gc_path "$d" "$gd"; then gd=$_GC_R; [ "$_GC_ABS" = 0 ] || k=1; else gd=''; k=0; fi
  fi
  if [ -n "$wt" ]; then _gc_path "$d" "$wt" && wt=$_GC_R || wt=''; fi
  GC_SUB[GC_N]=$1; shift
  for a in "$@"; do args+=$a$_GC_US; done
  GC_DIR[GC_N]=$d; GC_KNOWN[GC_N]=$k; GC_GITDIR[GC_N]=$gd; GC_WT[GC_N]=$wt; GC_ARGS[GC_N]=$args
  GC_N=$((GC_N + 1))
}

# _gc_simple <word>...: one simple command (reads and moves _gc_cmd's dir and
# known, reads its bodies).
_gc_simple() {
  local b
  while [ $# -gt 0 ]; do                     # keywords, NAME=value, wrappers
    case $1 in
      '!'|'{'|'}'|if|then|else|elif|fi|do|done|while|until) shift ;;
      exec|command|builtin|nohup|time) shift; while [[ $1 == -* ]]; do shift; done ;;
      env)
        shift
        while [ $# -gt 0 ]; do
          case $1 in -u|--unset) shift 2 || shift ;; -*|*=*) shift ;; *) break ;; esac
        done ;;
      *=*) [[ $1 =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || break; shift ;;
      *) break ;;
    esac
  done
  [ $# -gt 0 ] || return 0
  local cmd=${1##*[\\/]}; shift
  case $cmd in
    cd|pushd)
      while [[ $1 == -?* ]]; do shift; done
      if [ $# -eq 0 ]; then dir=$HOME; known=1
      elif [ "$1" != - ] && _gc_path "$dir" "$1"; then dir=$_GC_R; [ "$_GC_ABS" = 0 ] || known=1
      else known=0; fi ;;
    git|git.exe) _gc_git "$@" ;;
    bash|sh|zsh|dash|ksh)
      while [[ $1 == -* ]]; do
        case $1 in --*) ;; *c*) [ $# -ge 2 ] && _gc_cmd "$2" "$dir" $((depth + 1)) "$known"; return 0 ;; esac
        shift
      done
      if [ $# -eq 0 ]; then                  # script on stdin: its heredoc / here-string
        for b in "${bodies[@]}"; do _gc_cmd "$b" "$dir" $((depth + 1)) "$known"; done
      fi ;;
    eval) _gc_cmd "$*" "$dir" $((depth + 1)) "$known" ;;
  esac
}

# _gc_cmd <string> <dir> <depth> [<known>]: parse a command string that runs in
# <dir>; known=0 when <dir> is only the fallback for a path not known here.
_gc_cmd() {
  [ "$3" -gt 8 ] && return 0
  local dir=$2 depth=$3 known=${4:-1} t top
  local -a _T=() words=() stack=() bodies=()
  _gc_tok "$1" 0 1
  for t in "${_T[@]}" 'O;'; do
    case $t in
      W*) words+=("${t:1}") ;;
      S*) _gc_cmd "${t:1}" "$dir" $((depth + 1)) "$known" ;;
      H*) bodies+=("${t:1}") ;;
      O*)
        [ ${#words[@]} -gt 0 ] && _gc_simple "${words[@]}"
        words=(); bodies=()
        case $t in
          'O(') stack+=("$known$dir") ;;           # known (one digit), then the dir
          'O)')
            if [ ${#stack[@]} -gt 0 ]; then
              top=${stack[${#stack[@]}-1]}; unset "stack[${#stack[@]}-1]"
              known=${top:0:1}; dir=${top:1}
            fi ;;
        esac ;;
    esac
  done
}

# gc_parse <command> <session cwd>: find the git invocations. Sets GC_N and, per
# invocation, GC_SUB (subcommand), GC_DIR (directory git runs in), GC_KNOWN (0 when
# GC_DIR is only the fallback for a path not known here, else 1), GC_GITDIR and
# GC_WT (--git-dir / --work-tree, absolute, or empty), GC_ARGS (packed; gc_argv).
gc_parse() {
  local LC_ALL=C                             # byte offsets: no per-access UTF-8 scan
  GC_N=0; GC_SUB=(); GC_DIR=(); GC_KNOWN=(); GC_GITDIR=(); GC_WT=(); GC_ARGS=()
  case $1 in *git*) _gc_cmd "$1" "${2:-$PWD}" 0 1 ;; esac
}

# gc_find <subcommand>: the indices of the invocations that run it, one per line.
gc_find() {
  local i
  for ((i = 0; i < GC_N; i++)); do
    if [ "${GC_SUB[i]}" = "$1" ]; then printf '%s\n' "$i"; fi
  done
}

# gc_known <i>: is the invocation's repo known (no variable path or `cd -` on the way)?
gc_known() { [ "${GC_KNOWN[$1]}" = 1 ]; }

# gc_argv <i>: GC_ARGV=(the arguments after the subcommand).
gc_argv() {
  local s=${GC_ARGS[$1]}
  GC_ARGV=()
  while [ -n "$s" ]; do GC_ARGV+=("${s%%"$_GC_US"*}"); s=${s#*"$_GC_US"}; done
}

# gc_opts <i>: GC_OPTS=(the git options that select the invocation's repo).
gc_opts() {
  GC_OPTS=(-C "${GC_DIR[$1]}")
  if [ -n "${GC_GITDIR[$1]}" ]; then GC_OPTS+=("--git-dir=${GC_GITDIR[$1]}"); fi
  if [ -n "${GC_WT[$1]}" ]; then GC_OPTS+=("--work-tree=${GC_WT[$1]}"); fi
}

# gc_pending <i> [added]: the root-relative paths commit <i> takes beyond the current
# index. The gates run before the command, so `git add -A && git commit` would be judged
# on the index from before the add: this adds what each earlier `git add` / `git stage`
# for the same repo would stage (a `git add --dry-run` of its own arguments, in its own
# directory) and, for `commit -a`, the tracked changes. "added" leaves out deletions.
# The dry-runs use a scratch copy of the index: `add --dry-run` still takes index.lock,
# and the gates run in parallel (an IDE may hold it too). GIT_EDITOR=false: `add -e`
# would open an editor even in a dry-run.
# ranger: shortcut — `commit <pathspec>`/-i/-o, `git rm`/`mv` and a `reset` between the
# add and the commit are not modelled; the last one over-includes, the safe direction.
# Upgrade (model them) when such a command gets denied or asked in daily use.
gc_pending() {
  local i=$1 j gd keep='add|remove' idx
  [ "$2" = added ] && keep='add'
  gd=$(gc_git "$i" rev-parse --absolute-git-dir 2>/dev/null) || return 0
  idx=$(mktemp "${TMPDIR:-/tmp}/ranger-index.XXXXXX") || return 0
  cp "$gd/index" "$idx" 2>/dev/null || rm -f "$idx"   # no index yet: start from empty
  {
    export GIT_INDEX_FILE="$idx" GIT_EDITOR=false
    for ((j = 0; j < i; j++)); do
      case ${GC_SUB[j]} in add|stage) ;; *) continue ;; esac
      [ "$(gc_git "$j" rev-parse --absolute-git-dir 2>/dev/null)" = "$gd" ] || continue
      gc_argv "$j"
      gc_git "$j" add --dry-run "${GC_ARGV[@]}" 2>/dev/null
    done
    if gc_flag "$i" a --all; then gc_git "$i" add --dry-run -u 2>/dev/null; fi
  } | sed -nE "s/^($keep) '(.*)'\$/\\2/p" | sort -u
  rm -f "$idx"
}

# gc_show <i>: that selection as a shell-quoted command prefix, for messages.
gc_show() { gc_opts "$1"; printf 'git'; printf ' %q' "${GC_OPTS[@]}"; }

# gc_git <i> <git args>...: run git against the invocation's repo.
gc_git() {
  gc_opts "$1"; shift
  git "${GC_OPTS[@]}" "$@"
}

# gc_flag <i> <letter|''> [<long option>...]: is the flag among the options (before
# `--`)? Matches the long form exactly or as --opt=…, and the letter in any
# single-dash cluster (-f, -fu, -am).
# ranger: shortcut — option values are not skipped, so a value like `-m "-a…"` can
# match; every caller reads a match as the safer answer, so no per-command option table.
# Upgrade (a per-command option table) when a false match blocks a legitimate commit.
gc_flag() {
  local s=$2 a l
  gc_argv "$1"; shift 2
  for a in "${GC_ARGV[@]}"; do
    [ "$a" = -- ] && return 1
    for l in "$@"; do
      if [ "$a" = "$l" ] || [[ $a == "$l"=* ]]; then return 0; fi
    done
    if [ -n "$s" ] && [[ $a == -[!-]* && $a == *"$s"* ]]; then return 0; fi
  done
  return 1
}
