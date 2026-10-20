#!/usr/bin/env bash
# Suite: generate-boundary-config.sh (project-setup/scripts).
# Covers: generation and idempotence, --check (up to date / stale / missing, writes nothing), --print-intermediate,
#   deterministic ordering, forbidden-pair derivation, glob -> regex conversion, malformed rules.md cases (exit 2),
#   usage errors, missing yq/jq (exit 3), CRLF input, the shipped rules.md template.
# shellcheck disable=SC2016  # jq programs and printf fixtures use single quotes on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
SETUP="$WORK/scaffold/.agents/skills/project-setup"
GEN="$SETUP/scripts/generate-boundary-config.sh"
CFG=.workflow/tools/boundaries/dependency-cruiser.cjs

# proj NAME RULES_TEXT : fresh project dir with .workflow/rules.md; prints its path.
proj() {
  mkdir -p "$WORK/$1/.workflow"
  printf '%s' "$2" > "$WORK/$1/.workflow/rules.md"
  echo "$WORK/$1"
}
# cjs_json FILE : the JSON object assigned to module.exports.
cjs_json() { sed -e '1,/^module.exports = /s/^module.exports = //' -e '/^\/\//d' -e 's/;$//' "$1"; }

GOOD='# Rules

## Ownership

Prose.

```yaml
# comment
modules:
  ui:
    owns: ["src/ui/**", "src/app.ts"]
    may_depend_on: [billing]
  billing:
    owns: ["src/billing/**"]
    may_depend_on: [ledger]
  ledger:
    owns: ["src/ledger/**/*.ts"]
    may_depend_on: []
```

## Shared core

```yaml
shared_core:
  paths: ["src/shared/**"]
```

## Cross-cutting policy

- x
'
P=$(proj good "$GOOD")

echo "== generation and idempotence"
out=$("$GEN" "$P" 2>&1); rc=$?
eq "first run rc" "$rc" 0
check "first run reports write" 'grep -q "wrote $CFG" <<<"$out"' "$out"
check "config file created" '[ -f "$P/$CFG" ]'
sum1=$(cksum < "$P/$CFG")
out=$("$GEN" "$P" 2>&1); rc=$?
eq "second run rc" "$rc" 0
check "second run unchanged" 'grep -q "$CFG unchanged" <<<"$out"' "$out"
eq "file byte-identical after rerun" "$(cksum < "$P/$CFG")" "$sum1"
check "no temp files left" '[ -z "$(find "$P/tools" -name "*.tmp.*")" ]'
check "header marks file generated" 'head -1 "$P/$CFG" | grep -q "GENERATED"'
check "default PROJECT_DIR is cwd" '(cd "$P" && "$GEN" >/dev/null 2>&1 && "$GEN" --check >/dev/null 2>&1)'
t "--adapter dependency-cruiser accepted" 0 "$GEN" --adapter dependency-cruiser "$P"

echo "== --check"
t "--check up to date" 0 "$GEN" --check "$P"
printf '// hand edit\n' >> "$P/$CFG"
t "--check stale file" 1 "$GEN" --check "$P"
check "--check did not rewrite stale file" 'tail -1 "$P/$CFG" | grep -q "hand edit"'
"$GEN" "$P" >/dev/null 2>&1
eq "regeneration repairs stale file" "$(cksum < "$P/$CFG")" "$sum1"
rm "${P:?}/${CFG:?}"
t "--check missing file" 1 "$GEN" --check "$P"
check "--check writes nothing" '[ ! -e "$P/$CFG" ]'
out=$("$GEN" --check "$P" 2>&1)
check "--check names the file" 'grep -q "out of date" <<<"$out"' "$out"
"$GEN" "$P" >/dev/null 2>&1

echo "== intermediate JSON"
inter=$("$GEN" --print-intermediate "$P" 2>&1); rc=$?
eq "print-intermediate rc" "$rc" 0
eq "modules sorted" "$(jq -r '.modules|keys|join(",")' <<<"$inter")" "billing,ledger,ui"
eq "owns kept" "$(jq -c '.modules.ui.owns' <<<"$inter")" '["src/app.ts","src/ui/**"]'
eq "shared core paths" "$(jq -c '.shared_core.paths' <<<"$inter")" '["src/shared/**"]'
eq "forbidden pairs: allowed deps omitted" "$(jq -r '[.forbidden[].name|select(.=="ui-not-to-billing" or .=="billing-not-to-ledger")]|length' <<<"$inter")" 0
eq "forbidden pairs: ui may not use ledger" "$(jq -r '[.forbidden[].name|select(.=="ui-not-to-ledger")]|length' <<<"$inter")" 1
eq "forbidden pairs: shared core rule per module" "$(jq -r '[.forbidden[].name|select(startswith("shared-core-not-to-"))]|length' <<<"$inter")" 3
eq "forbidden total (module pairs 4 + core 3)" "$(jq '.forbidden|length' <<<"$inter")" 7
eq "forbidden sorted by name" "$(jq -c '[.forbidden[].name]' <<<"$inter")" "$(jq -c '[.forbidden[].name]|sort' <<<"$inter")"
P2=$(proj print-only "$GOOD")
"$GEN" --print-intermediate "$P2" >/dev/null 2>&1
check "print-intermediate writes no files" '[ ! -e "$P2/tools" ]'

echo "== determinism"
REORDER='## Ownership

```yaml
modules:
  ledger:
    owns: ["src/ledger/**/*.ts"]
  billing:
    may_depend_on: [ledger]
    owns: ["src/billing/**"]
  ui:
    may_depend_on: [billing]
    owns: ["src/app.ts", "src/ui/**"]
```

## Shared core

```yaml
shared_core:
  paths: ["src/shared/**"]
```
'
P3=$(proj reorder "$REORDER")
"$GEN" "$P3" >/dev/null 2>&1
eq "key/list order in rules.md does not change output" "$(cksum < "$P3/$CFG")" "$sum1"

echo "== glob conversion"
json=$(cjs_json "$P/$CFG")
check "config body is valid JSON" 'jq -e . <<<"$json" >/dev/null' "$json"
eq "options.tsConfig" "$(jq -r '.options.tsConfig.fileName' <<<"$json")" tsconfig.json
rule() { jq -c --arg n "$1" '.forbidden[]|select(.name==$n)' <<<"$json"; }
eq "** -> .*" "$(rule billing-not-to-ui | jq -r '.from.path')" '^src/billing/.*$'
eq "literal dot escaped, array when several owns" "$(rule billing-not-to-ui | jq -c '.to.path')" '["^src/app\\.ts$","^src/ui/.*$"]'
eq "**/ and * and escaped dot" "$(rule ledger-not-to-billing | jq -r '.from.path')" '^src/ledger/(.*/|)[^/]*\.ts$'
eq "severity error" "$(rule ledger-not-to-billing | jq -r .severity)" error
check "comment names the rule" 'rule ledger-not-to-billing | jq -r .comment | grep -q "module ledger may not depend on module billing"'
eq "shared core comment" "$(rule shared-core-not-to-ui | jq -r .comment)" "Generated from .workflow/rules.md: shared core may not depend on module ui"
eq "shared core from path" "$(rule shared-core-not-to-ui | jq -r '.from.path')" '^src/shared/.*$'
QMARK='## Ownership

```yaml
modules:
  a: {owns: ["lib/a?.c", "./pkg/a+b/**"], may_depend_on: []}
  b: {owns: ["lib/b/**"], may_depend_on: []}
```

## Shared core

```yaml
shared_core: {paths: []}
```
'
P4=$(proj qmark "$QMARK")
"$GEN" "$P4" >/dev/null 2>&1
json=$(cjs_json "$P4/$CFG")
eq "? -> [^/], ./ stripped, + escaped" "$(rule b-not-to-a | jq -c '.to.path')" '["^pkg/a\\+b/.*$","^lib/a[^/]\\.c$"]'
eq "empty shared core emits no core rules" "$(jq '[.forbidden[].name|select(startswith("shared-core"))]|length' <<<"$json")" 0

echo "== malformed rules.md"
SC_OK='
## Shared core

```yaml
shared_core: {paths: []}
```
'
bad() { # bad NAME RULES_TEXT PATTERN
  local d out rc
  d=$(proj "bad-$1" "$2")
  out=$("$GEN" "$d" 2>&1); rc=$?
  if [ "$rc" = 2 ] && grep -qE -- "$3" <<<"$out"; then ok "malformed: $1"; else ko "malformed: $1" "rc=$rc out=$out"; fi
  [ ! -e "$d/tools" ] || ko "malformed: $1 wrote output" "$(find "$d/tools")"
}
bad no-block $'## Ownership\nno block here\n'"$SC_OK" 'no fenced yaml block under heading "## Ownership"'
bad bad-yaml $'## Ownership\n\n```yaml\nmodules: [unclosed\n```\n'"$SC_OK" 'Ownership: block is not valid YAML'
bad unknown-dep $'## Ownership\n\n```yaml\nmodules:\n  a: {owns: ["x/**"], may_depend_on: [ghost]}\n```\n'"$SC_OK" 'unknown module\(s\): ghost'
bad two-blocks $'## Ownership\n\n```yaml\nmodules: {}\n```\n\n```yaml\nmodules: {}\n```\n'"$SC_OK" 'more than one fenced yaml block'
bad empty-owns $'## Ownership\n\n```yaml\nmodules:\n  a: {owns: [], may_depend_on: []}\n```\n'"$SC_OK" 'owns must be a non-empty list'
bad missing-owns $'## Ownership\n\n```yaml\nmodules:\n  a: {may_depend_on: []}\n```\n'"$SC_OK" 'owns must be a non-empty list'
bad brace-glob $'## Ownership\n\n```yaml\nmodules:\n  a: {owns: ["x/{a,b}"], may_depend_on: []}\n```\n'"$SC_OK" 'unsupported glob character'
bad bang-glob $'## Ownership\n\n```yaml\nmodules:\n  a: {owns: ["!x/**"], may_depend_on: []}\n```\n'"$SC_OK" 'unsupported glob character'
bad self-dep $'## Ownership\n\n```yaml\nmodules:\n  a: {owns: ["x/**"], may_depend_on: [a]}\n```\n'"$SC_OK" 'lists itself'
bad bad-name $'## Ownership\n\n```yaml\nmodules:\n  "a b": {owns: ["x/**"], may_depend_on: []}\n```\n'"$SC_OK" 'must match'
bad non-string-owns $'## Ownership\n\n```yaml\nmodules:\n  a: {owns: [1], may_depend_on: []}\n```\n'"$SC_OK" 'list of non-empty strings'
bad modules-not-map $'## Ownership\n\n```yaml\nmodules: [a, b]\n```\n'"$SC_OK" 'must define `modules:` as a map'
bad module-not-map $'## Ownership\n\n```yaml\nmodules:\n  a: nope\n```\n'"$SC_OK" 'must be a map'
bad core-missing-paths $'## Ownership\n\n```yaml\nmodules: {}\n```\n\n## Shared core\n\n```yaml\nshared_core: {}\n```\n' 'shared_core.paths'
bad core-bad-glob $'## Ownership\n\n```yaml\nmodules: {}\n```\n\n## Shared core\n\n```yaml\nshared_core: {paths: ["a/[x]"]}\n```\n' 'unsupported glob character'
bad no-core-section $'## Ownership\n\n```yaml\nmodules: {}\n```\n' 'no fenced yaml block under heading "## Shared core"'
bad block-outside-heading $'```yaml\nmodules: {}\n```\n## Ownership\nx\n'"$SC_OK" 'no fenced yaml block under heading "## Ownership"'
t "missing rules.md" 2 "$GEN" "$WORK/scaffold"
t "--check on malformed rules" 2 "$GEN" --check "$WORK/bad-bad-yaml"

echo "== tolerated input"
CRLF=$(printf '%s' "$GOOD" | sed 's/$/\r/')
P5=$(proj crlf "$CRLF")
"$GEN" "$P5" >/dev/null 2>&1
eq "CRLF rules.md renders the same config" "$(cksum < "$P5/$CFG")" "$sum1"
P6=$(proj template "$(cat "$SETUP/assets/docs/rules.md")")
t "shipped rules.md template parses (no modules)" 0 "$GEN" "$P6"
eq "template yields no forbidden rules" "$(cjs_json "$P6/$CFG" | jq '.forbidden|length')" 0
P7=$(proj extra-sections "$(printf '## Other\n\n```yaml\nmodules: {x: 1}\n```\n\n%s' "$GOOD")")
t "yaml blocks under other headings ignored" 0 "$GEN" --print-intermediate "$P7"

echo "== usage and environment"
t "unknown option" 2 "$GEN" --bogus "$P"
t "unknown adapter" 2 "$GEN" --adapter nope "$P"
t "--adapter needs a name" 2 "$GEN" --adapter
t "two project dirs" 2 "$GEN" "$P" "$P2"
t "missing project dir" 2 "$GEN" "$WORK/does-not-exist"
t "--help" 0 "$GEN" --help
check "--help prints usage" '"$GEN" --help | grep -q -- "--check"'
BIN=$WORK/bin-noyq
mkdir -p "$BIN"
for b in bash jq cat sed awk grep mkdir mv dirname rm cksum; do ln -sf "$(command -v "$b")" "$BIN/$b"; done
out=$(PATH="$BIN" "$BIN/bash" "$GEN" "$P" 2>&1); rc=$?
check "missing yq -> exit 3" '[ "$rc" = 3 ] && grep -q "yq not found" <<<"$out"' "rc=$rc $out"
BIN2=$WORK/bin-nojq
mkdir -p "$BIN2"
for b in bash cat sed awk grep mkdir mv dirname rm; do ln -sf "$(command -v "$b")" "$BIN2/$b"; done
ln -sf "$(command -v yq)" "$BIN2/yq"
out=$(PATH="$BIN2" "$BIN2/bash" "$GEN" "$P" 2>&1); rc=$?
check "missing jq -> exit 3" '[ "$rc" = 3 ] && grep -q "jq not found" <<<"$out"' "rc=$rc $out"

shellcheck_files "shellcheck: generate-boundary-config.sh" "$GEN"
finish
