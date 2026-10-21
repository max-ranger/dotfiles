#!/bin/bash
# PreToolUse (Write|Edit|MultiEdit): ask before an edit to an EXISTING lint, format or
# analyzer config, so a failing check doesn't get passed by weakening the check.
# Creating a config passes. Two kinds of file:
# - pure check configs (ESLint, Prettier, Stylelint, Biome, analysis_options.yaml,
#   .editorconfig, .globalconfig, rulesets, Ruff, their ignore files, and the files
#   of a shared eslint config package): any edit asks.
# - mixed files (tsconfig and any JSON with compilerOptions, Directory.Build.props,
#   .csproj): asks only when a check setting changes (strict flags, extends, NoWarn,
#   Nullable, TreatWarningsAsErrors, ...), since paths and package versions change
#   all the time.
# Also asks when an edit to a code file adds an inline suppression (eslint-disable,
# @ts-ignore, Dart's // ignore:, #pragma warning disable, # noqa, ...): the same
# weakening, one line at a time.
# Idea from affaan-m/ECC's config-protection hook, rewritten for these stacks.
INPUT=$(cat)
{ IFS= read -r FILE; IFS= read -r CWD; } < <(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // "", .cwd // ""' 2>/dev/null | tr -d '\r')
[ -z "$FILE" ] && exit 0
[ -z "$CWD" ] && CWD=$PWD
case $FILE in /*|[A-Za-z]:[\\/]*) ;; *) FILE="$CWD/$FILE" ;; esac
NAME=${FILE##*[\\/]}

# 1. Inline suppressions in a code file (new or existing): ask when an edit adds one.
case $NAME in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.mts|*.cts|*.vue|*.svelte|*.dart|*.cs|*.razor|*.cshtml|*.py|*.sh|*.css|*.scss|*.less|*.html)
    case $INPUT in *disable*|*ts-ignore*|*ts-expect-error*|*ts-nocheck*|*biome-ignore*|*ignore:*|*ignore_for_file*|*SuppressMessage*|*noqa*|*type:\ ignore*|*lint-ignore*)
      SUPP='eslint-disable(?:-next-line|-line)?|stylelint-disable(?:-next-line|-line)?|@ts-(?:ignore|expect-error|nocheck)|biome-ignore|deno-lint-ignore(?:-file)?|//\s*ignore(?:_for_file)?:|#pragma\s+warning\s+disable|SuppressMessage|#nullable\s+disable|#\s*noqa|#\s*type:\s*ignore|pylint:\s*disable|shellcheck\s+disable'
      OLDF=$FILE; [ -f "$FILE" ] || OLDF=/dev/null
      # from the first edit (or Write) with more suppressions than it replaced: one it
      # added (a kind the old text lacks), else the last one
      ADDED=$(printf '%s' "$INPUT" | jq -r --arg re "$SUPP" --rawfile old "$OLDF" '
        def n: [scan($re)] | length;
        .tool_input as $t
        | (if $t.content != null then [[$old, $t.content]]
           else [$t, ($t.edits // [])[]] | map(select(.old_string != null) | [.old_string, (.new_string // "")]) end)
        | map(select((.[0] | n) < (.[1] | n)) | ((.[1] | [scan($re)]) - (.[0] | [scan($re)]) | first) // (.[1] | [scan($re)] | last)) | first // empty' 2>/dev/null | tr -d '\r')
      if [ -n "$ADDED" ]; then
        jq -nc --arg f "$NAME" --arg s "$ADDED" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",
          permissionDecisionReason:("Suppression check: this edit adds " + $s + " to " + $f + ". Approve only if the warning is a false positive and the line says why. Otherwise the code should be fixed, not the check.")}}'
        exit 0
      fi ;;
    esac ;;
esac

# 2. Lint, format and analyzer configs.
[ -f "$FILE" ] || exit 0                                  # creating a config is fine
DIR=${FILE%[\\/]*}; DIR=${DIR##*[\\/]}

TS='"(?:strict\w*|alwaysStrict|noImplicit\w*|noUnused\w*|noUnchecked\w*|noFallthroughCasesInSwitch|noPropertyAccessFromIndexSignature|exactOptionalPropertyTypes|useUnknownInCatchVariables|allowUnreachableCode|allowUnusedLabels|skipLibCheck|checkJs|noEmitOnError|extends)"\s*:\s*[^,}\n]*'
MSBUILD='<(?:TreatWarningsAsErrors|WarningsAsErrors|WarningsNotAsErrors|NoWarn|Nullable|AnalysisLevel\w*|AnalysisMode\w*|EnforceCodeStyleInBuild|EnableNETAnalyzers|RunAnalyzers\w*|CodeAnalysisRuleSet|CodeAnalysisTreatWarningsAsErrors|WarningLevel)>[^<]*'
RE=""
case $NAME in
  eslint.config.*|.eslintrc|.eslintrc.*|.eslintignore| \
  .prettierrc|.prettierrc.*|prettier.config.*|.prettierignore| \
  .stylelintrc|.stylelintrc.*|stylelint.config.*|.stylelintignore| \
  biome.json|biome.jsonc|.biome.json|.biome.jsonc| \
  analysis_options.yaml|.editorconfig|.globalconfig|*.globalconfig|*.ruleset| \
  ruff.toml|.ruff.toml|.flake8) ;;
  Directory.Build.props|*.csproj) RE=$MSBUILD ;;
  tsconfig.json|tsconfig.*.json) RE=$TS ;;
  *.json) grep -q '"compilerOptions"' "$FILE" 2>/dev/null && RE=$TS || exit 0 ;;
  *.js|*.mjs|*.cjs|*.ts|*.mts|*.cts)                    # a shared eslint config package
    case $DIR in eslint|eslint-config*) ;; *) exit 0 ;; esac ;;
  *) exit 0 ;;
esac

if [ -n "$RE" ]; then
  # ask only when the set of check settings differs: file vs Write content, or the
  # old vs new text of any one edit
  CHANGED=$(printf '%s' "$INPUT" | jq -r --arg re "$RE" --rawfile old "$FILE" '
    def flags: [scan($re)] | map(gsub("\\s"; "")) | unique;
    .tool_input as $t
    | if $t.content != null then ($old | flags) != ($t.content | flags)
      else [$t, ($t.edits // [])[]] | map(select(.old_string != null))
           | any((.old_string | flags) != ((.new_string // "") | flags))
      end' 2>/dev/null | tr -d '\r')
  [ "$CHANGED" = true ] || exit 0
fi

jq -nc --arg f "$NAME" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",
  permissionDecisionReason:("Config protection: " + $f + " is an existing lint, format or analyzer config, or this edit changes a check setting in it. Approve only if this change is intended. If a check is failing, the code should be fixed, not the check.")}}'
exit 0
