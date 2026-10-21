#!/bin/bash
# Config protection: pipes PreToolUse Write/Edit/MultiEdit JSON into the hook and
# checks that an edit to an EXISTING lint, format or analyzer config asks, while
# creating one, or editing anything else, passes.
# Needs bash + jq.
#   bash claude/plugins/ranger-claude/tests/config-protection.test.sh
SCRIPTS="$(cd "$(dirname "$0")/../scripts" && pwd)"
T=$(mktemp -d "${TMPDIR:-/tmp}/ranger-config.XXXXXX")
trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0

P="$T/a project"
mkdir -p "$P/src" "$P/web"
mkdir -p "$P/tooling/eslint" "$P/tooling/tsconfig" "$P/api"
for f in eslint.config.js .eslintrc.json .eslintignore .prettierrc prettier.config.mjs .prettierignore \
         .stylelintrc.json .stylelintignore web/stylelint.config.mjs biome.json biome.jsonc .biome.json \
         analysis_options.yaml .editorconfig .globalconfig team.globalconfig rules.ruleset \
         ruff.toml .ruff.toml .flake8 tooling/eslint/index.js tooling/eslint/package.json \
         src/app.ts src/data.json package.json README.md; do
  echo '{}' > "$P/$f"
done
printf '{\n  "compilerOptions": {\n    "strict": true\n  }\n}\n' > "$P/tooling/tsconfig/base.json"
printf '{\n  "extends": "../tooling/tsconfig/base.json",\n  "include": ["src"]\n}\n' > "$P/web/tsconfig.json"
printf '<Project>\n  <PropertyGroup>\n    <TargetFramework>net10.0</TargetFramework>\n    <Nullable>enable</Nullable>\n    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>\n  </PropertyGroup>\n</Project>\n' > "$P/Directory.Build.props"
cp "$P/Directory.Build.props" "$P/api/Api.csproj"
printf '{\n  "compilerOptions": {\n    "strict": true,\n    "paths": {}\n  },\n  "include": ["src"]\n}\n' > "$P/tsconfig.json"
cp "$P/tsconfig.json" "$P/tsconfig.app.json"

# decide <tool> <input fields as a jq object>: allow (no output) | ask | deny | badjson
decide() {
  local out
  out=$(cd "$T" && jq -nc --arg d "$P" --arg t "$1" \
    "{session_id:\"test\",cwd:\$d,hook_event_name:\"PreToolUse\",tool_name:\$t,tool_input:($2)}" \
    | bash "$SCRIPTS/config-protection.sh" 2>/dev/null)
  [ -z "$out" ] && { echo allow; return; }
  printf '%s' "$out" | jq -er '.hookSpecificOutput.permissionDecision' 2>/dev/null || echo badjson
}
expect() { # expect <label> <want> <tool> <input>
  local got; got=$(decide "$3" "$4")
  if [ "$got" = "$2" ]; then PASS=$((PASS + 1))
  else FAIL=$((FAIL + 1)); printf 'FAIL  %-50s want %-5s got %s\n' "$1" "$2" "$got"; fi
}
edit()  { printf '{file_path:%s,old_string:%s,new_string:%s}' "$(jq -Rn --arg v "$1" '$v')" "$(jq -Rn --arg v "$2" '$v')" "$(jq -Rn --arg v "$3" '$v')"; }
write() { printf '{file_path:%s,content:%s}' "$(jq -Rn --arg v "$1" '$v')" "$(jq -Rn --arg v "$2" '$v')"; }

# ── existing lint / format / analyzer configs: ask ──
expect "Edit eslint.config.js"                    ask Edit  "$(edit "$P/eslint.config.js" a b)"
expect "Edit .eslintrc.json"                      ask Edit  "$(edit "$P/.eslintrc.json" a b)"
expect "Write .prettierrc"                        ask Write "$(write "$P/.prettierrc" '{}')"
expect "Edit .prettierignore"                     ask Edit  "$(edit "$P/.prettierignore" a b)"
expect "Edit biome.json"                          ask Edit  "$(edit "$P/biome.json" a b)"
expect "Edit analysis_options.yaml"               ask Edit  "$(edit "$P/analysis_options.yaml" a b)"
expect "Edit .editorconfig"                       ask Edit  "$(edit "$P/.editorconfig" a b)"
expect "Edit *.globalconfig"                      ask Edit  "$(edit "$P/team.globalconfig" a b)"
expect "Edit ruff.toml"                           ask Edit  "$(edit "$P/ruff.toml" a b)"
for f in .eslintignore prettier.config.mjs .stylelintrc.json .stylelintignore biome.jsonc .biome.json \
         .globalconfig rules.ruleset .ruff.toml .flake8; do
  expect "Edit $f"                                ask Edit  "$(edit "$P/$f" a b)"
done
expect "shared eslint package: index.js"          ask Edit  "$(edit "$P/tooling/eslint/index.js" a b)"
expect "Edit nested stylelint.config.mjs"         ask Edit  "$(edit "$P/web/stylelint.config.mjs" a b)"
expect "relative path, resolved against cwd"      ask Edit  "$(edit "eslint.config.js" a b)"
expect "MultiEdit analysis_options.yaml"          ask MultiEdit "{file_path:\"$P/analysis_options.yaml\",edits:[{old_string:\"a\",new_string:\"b\"}]}"

# ── tsconfig: only a change to a strictness flag asks ──
expect "tsconfig: strict flag in old_string"      ask   Edit "$(edit "$P/tsconfig.json" '"strict": true' '"strict": false')"
expect "tsconfig.app: skipLibCheck added"         ask   Edit "$(edit "$P/tsconfig.app.json" '"paths": {}' '"paths": {}, "skipLibCheck": true')"
expect "tsconfig: MultiEdit, one edit strict"     ask   MultiEdit "{file_path:\"$P/tsconfig.json\",edits:[{old_string:\"src\",new_string:\"app\"},{old_string:\"x\",new_string:\"\\\"noImplicitAny\\\": false\"}]}"
expect "tsconfig: Write drops strict"             ask   Write "$(write "$P/tsconfig.json" '{"compilerOptions":{"paths":{}},"include":["src"]}')"
expect "tsconfig: paths edit"                     allow Edit "$(edit "$P/tsconfig.json" '"paths": {}' '"paths": {"@/*": ["src/*"]}')"
expect "tsconfig: Write keeps strict, new include" allow Write "$(write "$P/tsconfig.json" "$(printf '{\n  "compilerOptions": {\n    "strict": true,\n    "paths": {}\n  },\n  "include": ["src", "test"]\n}\n')")"

expect "tsconfig: Write reformats, same flags"    allow Write "$(write "$P/tsconfig.json" '{"compilerOptions":{"strict":true,"paths":{}},"include":["src","test"]}')"
expect "tsconfig: flag unchanged, only context"  allow Edit "$(edit "$P/tsconfig.json" "$(printf '"strict": true,\n    "paths": {}')" "$(printf '"strict": true,\n    "paths": {"@/*": ["src/*"]}')")"
expect "tsconfig: extends swapped"                ask   Edit "$(edit "$P/web/tsconfig.json" '"extends": "../tooling/tsconfig/base.json"' '"extends": "@vue/tsconfig/tsconfig.json"')"
expect "shared tsconfig base.json: strict off"    ask   Edit "$(edit "$P/tooling/tsconfig/base.json" '"strict": true' '"strict": false')"
expect "shared tsconfig base.json: new key"       allow Edit "$(edit "$P/tooling/tsconfig/base.json" '"compilerOptions": {' '"compilerOptions": {"target": "ES2022",')"

# ── MSBuild: only a change to an analyzer or warning setting asks ──
expect "Directory.Build.props: TargetFramework"   allow Edit "$(edit "$P/Directory.Build.props" '<TargetFramework>net10.0</TargetFramework>' '<TargetFramework>net11.0</TargetFramework>')"
expect "Directory.Build.props: NoWarn added"      ask   Edit "$(edit "$P/Directory.Build.props" '<Nullable>enable</Nullable>' '<Nullable>enable</Nullable><NoWarn>CA1062</NoWarn>')"
expect "csproj: Nullable disabled"                ask   Edit "$(edit "$P/api/Api.csproj" '<Nullable>enable</Nullable>' '<Nullable>disable</Nullable>')"
expect "csproj: Write drops TreatWarningsAsErrors" ask  Write "$(write "$P/api/Api.csproj" '<Project><PropertyGroup><TargetFramework>net10.0</TargetFramework><Nullable>enable</Nullable></PropertyGroup></Project>')"
expect "csproj: package reference added"          allow Edit "$(edit "$P/api/Api.csproj" '</Project>' '<ItemGroup><PackageReference Include="X" /></ItemGroup></Project>')"

# ── everything else passes ──
expect "creating a new eslint config"             allow Write "$(write "$P/new/eslint.config.js" 'export default []')"
expect "creating a new tsconfig"                  allow Write "$(write "$P/new/tsconfig.json" '{"compilerOptions":{"strict":false}}')"
expect "source file"                              allow Edit  "$(edit "$P/src/app.ts" a b)"
expect "package.json"                             allow Edit  "$(edit "$P/package.json" a b)"
expect "shared eslint package: package.json"      allow Edit  "$(edit "$P/tooling/eslint/package.json" a b)"
expect "plain JSON data file"                     allow Edit  "$(edit "$P/src/data.json" a b)"
expect "README.md"                                allow Edit  "$(edit "$P/README.md" a b)"
expect "a file named like a config, in src"       allow Edit  "$(edit "$P/src/app.ts" '.eslintrc' 'x')"
expect "no file_path"                             allow Edit  "{old_string:\"a\",new_string:\"b\"}"

# the reason names the file
reason=$(cd "$P" && jq -nc --arg f "$P/.editorconfig" '{session_id:"test",tool_name:"Edit",tool_input:{file_path:$f,old_string:"a",new_string:"b"}}' \
  | bash "$SCRIPTS/config-protection.sh" | jq -r '.hookSpecificOutput.permissionDecisionReason')
if printf '%s' "$reason" | grep -q '\.editorconfig'; then PASS=$((PASS + 1)); else FAIL=$((FAIL + 1)); echo "FAIL  reason does not name the file: $reason"; fi

echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
