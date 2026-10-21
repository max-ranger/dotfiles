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
# Inline suppressions (eslint-disable, @ts-ignore, // ignore:) are out of scope.
# Idea from affaan-m/ECC's config-protection hook, rewritten for these stacks.
INPUT=$(cat)
{ IFS= read -r FILE; IFS= read -r CWD; } < <(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // "", .cwd // ""' 2>/dev/null | tr -d '\r')
[ -z "$FILE" ] && exit 0
[ -z "$CWD" ] && CWD=$PWD
case $FILE in /*|[A-Za-z]:[\\/]*) ;; *) FILE="$CWD/$FILE" ;; esac
[ -f "$FILE" ] || exit 0                                  # creating a config is fine
NAME=${FILE##*[\\/]}
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
