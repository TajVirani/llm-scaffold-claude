#!/usr/bin/env bash
# Suite: regenerate-caches build-architecture.sh and check-staged-cache.sh.
# Covers: canonical architecture.md (sorted nodes and edges, self-edges dropped, out-of-scope and node_modules files
#   dropped, module roots from .workflow/rules.md, --module override), order-independence of the input JSON, boundary
#   violations, modules.md skeleton (files, depends on, used by, public interface from .d.ts with export * expanded),
#   flows entry candidates, id collisions, dirty-scope refusal, --out guard, input rejections; the staged-body checker
#   for all three shapes and its Mermaid HTML wrapper. No node needed: dependency-cruiser and tsc output are fixtures.
# shellcheck disable=SC2016,SC2034  # literal Markdown backticks in single quotes; check expressions read vars through eval
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
S="$WORK/scaffold/.agents/skills/regenerate-caches/scripts"
B="$S/build-architecture.sh"
C="$S/check-staged-cache.sh"
R="$WORK/repo"
git_init_repo "$R"
cd "$R" || exit 1
mkdir -p src/a src/b/sub lib docs .workflow/.cache-staging
for f in src/main.ts src/a/index.ts src/a/x.ts src/a/x.test.ts src/b/y.ts src/b/sub/z.ts lib/other.ts; do echo "// $f" >"$f"; done
cat >.workflow/rules.md <<'EOF'
# Rules

## Ownership

```yaml
modules:
  alpha:
    owns: ["src/a/**"]
    may_depend_on: [beta]
  beta:
    owns: ["src/b/**"]
    may_depend_on: []
```

## Shared core

```yaml
shared_core:
  paths: ["src/b/sub/**"]
```
EOF
printf '.workflow/.cache-staging/\n' >.gitignore
git_commit_all "$R" init

cat >"$WORK/cruise.json" <<'EOF'
{"modules":[
 {"source":"src/main.ts","dependencies":[{"resolved":"src/a/index.ts"},{"resolved":"fs","coreModule":true}]},
 {"source":"src/a/index.ts","dependencies":[{"resolved":"src/a/x.ts"}]},
 {"source":"src/a/x.ts","dependencies":[{"resolved":"src/b/y.ts"},{"resolved":"src/a/x.ts"},{"resolved":"node_modules/foo/index.js"}]},
 {"source":"src/a/x.test.ts","dependencies":[{"resolved":"src/a/x.ts"}]},
 {"source":"src/b/y.ts","dependencies":[{"resolved":"src/b/sub/z.ts"},{"resolved":"lib/other.ts"}]},
 {"source":"src/b/sub/z.ts","dependencies":[]},
 {"source":"lib/other.ts","dependencies":[]},
 {"source":"node_modules/foo/index.js","dependencies":[]},
 {"source":"fs","coreModule":true,"dependencies":[]}
],"summary":{"violations":[]}}
EOF
jq '.modules |= reverse | .modules[].dependencies |= reverse' "$WORK/cruise.json" >"$WORK/cruise-rev.json"

expected_arch='# Architecture

## Module graph

```mermaid
flowchart LR
  src_a["src/a"]
  src_b["src/b"]
  src_b_sub["src/b/sub"]
  src_main_ts["src/main.ts"]
  src_a --> src_b
  src_b --> src_b_sub
  src_main_ts --> src_a
```

## Edges

- `src/a` → `src/b`
- `src/b` → `src/b/sub`
- `src/main.ts` → `src/a`

## Boundary violations

Not checked: no boundary config at .workflow/tools/boundaries/dependency-cruiser.cjs.'

# ---------------------------------------------------------------- architecture
arch=$("$B" --cache architecture --scope src --from-json "$WORK/cruise.json"); rc=$?
eq arch-rc "$rc" 0
eq arch-golden "$arch" "$expected_arch"
eq arch-order-independent "$("$B" --cache architecture --scope src --from-json "$WORK/cruise-rev.json")" "$arch"
eq arch-scope-dot-slash "$("$B" --cache architecture --scope ./src/ --from-json "$WORK/cruise.json")" "$arch"
one=$("$B" --cache architecture --scope src --module src --from-json "$WORK/cruise.json")
check arch-module-override-one-node '[ "$(printf "%s\n" "$one" | grep -c "^  src\[")" = 1 ] && printf "%s\n" "$one" | grep -qx "None."'
fb=$("$B" --cache architecture --scope src --module src/b --from-json "$WORK/cruise.json")
check arch-fallback-first-segment 'printf "%s\n" "$fb" | grep -q "src_a --> src_b\$" && ! printf "%s\n" "$fb" | grep -q src_b_sub'

cat >"$WORK/viol.json" <<'EOF'
{"modules":[],"summary":{"violations":[
 {"rule":{"name":"beta-not-to-alpha"},"from":"src/b/y.ts","to":"src/a/x.ts"},
 {"rule":{"name":"alpha-not-to-main"},"from":"src/a/x.ts","to":"src/main.ts"},
 {"rule":{"name":"beta-not-to-alpha"},"from":"src/b/y.ts","to":"src/a/x.ts"}]}}
EOF
v=$("$B" --cache architecture --scope src --from-json "$WORK/cruise.json" --violations-json "$WORK/viol.json" | sed -n '/^## Boundary violations/,$p' | sed '1,2d')
eq viol-sorted-unique "$v" '- `alpha-not-to-main`: `src/a/x.ts` → `src/main.ts`
- `beta-not-to-alpha`: `src/b/y.ts` → `src/a/x.ts`'
v=$("$B" --cache architecture --scope src --from-json "$WORK/cruise.json" --violations-json "$WORK/cruise.json" | tail -1)
eq viol-none "$v" "None."
echo '{"modules":[]}' >"$WORK/noviol.json"
t viol-bad-json 2 "$B" --cache architecture --scope src --from-json "$WORK/cruise.json" --violations-json "$WORK/noviol.json"

# ---------------------------------------------------------------- modules
D="$WORK/dts"
mkdir -p "$D/src/a"
cat >"$D/src/a/index.d.ts" <<'EOF'
import { y } from "../b/y.js";
export * from "./x.js";
export { y as why, type Z } from "../b/y.js";
export declare class Alpha {
    run(): void;
}
export interface Opts {
    n: number;
}
export declare const enum Mode {
    A = 0
}
EOF
cat >"$D/src/a/x.d.ts" <<'EOF'
export declare function f(): void;
export type T = 1;
export declare let counter: number;
EOF
printf 'declare const _default: 1;\nexport default _default;\n' >"$D/src/main.d.ts"
mods=$("$B" --cache modules --scope src --from-json "$WORK/cruise.json" --dts-dir "$D"); rc=$?
eq mod-rc "$rc" 0
eq mod-headings "$(printf '%s\n' "$mods" | grep '^## ' | tr '\n' '|')" "## src/a|## src/b|## src/b/sub|## src/main.ts|"
eq mod-slots "$(printf '%s\n' "$mods" | grep -c '^- Purpose: <!-- slot: purpose -->$')" 4
sec_a=$(printf '%s\n' "$mods" | awk '/^## src\/a$/ {on=1; next} /^## / {on=0} on')
eq mod-a-files "$(printf '%s\n' "$sec_a" | grep -c '^  - `src/a/')" 3
eq mod-a-interface "$(printf '%s\n' "$sec_a" | sed -n '/^- Public interface:/,$p' | sed '/^$/d')" '- Public interface:
  - `Alpha` (class)
  - `Mode` (enum)
  - `Opts` (interface)
  - `T` (type)
  - `Z` (re-export from "../b/y.js")
  - `counter` (const)
  - `f` (function)
  - `why` (re-export from "../b/y.js")'
check mod-a-deps 'printf "%s\n" "$sec_a" | grep -A1 "^- Depends on:" | grep -q "src/b\`\$"'
check mod-a-usedby 'printf "%s\n" "$sec_a" | grep -A1 "^- Used by:" | grep -q "src/main.ts"'
check mod-main-default 'printf "%s\n" "$mods" | grep -q "^  - \`default\` (default export)"'
check mod-b-no-entry 'printf "%s\n" "$mods" | awk "/^## src\/b\$/{on=1;next} /^## /{on=0} on" | grep -q "^- Public interface: Not generated: no declaration entry"'
check mod-sub-depends-none 'printf "%s\n" "$mods" | awk "/^## src\/b\/sub\$/{on=1;next} /^## /{on=0} on" | grep -q "^- Depends on: none"'
nots=$("$B" --cache modules --scope src --from-json "$WORK/cruise.json")
eq mod-no-tsconfig "$(printf '%s\n' "$nots" | grep -c '^- Public interface: Not generated: no tsconfig.json.$')" 4
eq mod-deterministic "$("$B" --cache modules --scope src --from-json "$WORK/cruise-rev.json" --dts-dir "$D")" "$mods"

# ---------------------------------------------------------------- entries
ent=$("$B" --cache entries --scope src --from-json "$WORK/cruise.json"); rc=$?
eq ent-rc "$rc" 0
eq ent-candidates "$(jq -r '[.candidates[].file] | join(",")' <<<"$ent")" "src/main.ts"
eq ent-reaches-modules "$(jq -r '.candidates[0].reaches_modules | join(",")' <<<"$ent")" "src/a,src/b,src/b/sub,src/main.ts"
eq ent-reaches-files "$(jq -r '.candidates[0].reaches_files | length' <<<"$ent")" 5

# ---------------------------------------------------------------- guards and rejections
t out-staging 0 "$B" --cache architecture --scope src --from-json "$WORK/cruise.json" --out .workflow/.cache-staging/architecture.md
eq out-same-as-stdout "$(cat .workflow/.cache-staging/architecture.md)" "$arch"
t out-under-cache 2 "$B" --cache architecture --scope src --from-json "$WORK/cruise.json" --out .workflow/cache/architecture.md
check out-under-cache-nothing-written '[ ! -e .workflow/cache/architecture.md ]'
echo dirty >>src/a/x.ts
t dirty-refused 2 "$B" --cache architecture --scope src --from-json "$WORK/cruise.json"
t dirty-allowed 0 "$B" --cache architecture --scope src --from-json "$WORK/cruise.json" --allow-dirty
t dirty-outside-scope-ok 0 "$B" --cache architecture --scope lib --module lib --from-json "$WORK/cruise.json"
git checkout -q -- src/a/x.ts
touch src/a/new.ts
t untracked-refused 2 "$B" --cache architecture --scope src --from-json "$WORK/cruise.json"
rm -f src/a/new.ts
eq scope-boundaries-ignored "$("$B" --cache architecture --scope src --scope .workflow/tools/boundaries/x.cjs --from-json "$WORK/cruise.json" 2>/dev/null)" "$arch"
w=$("$B" --cache architecture --scope src --scope .workflow/tools/boundaries --from-json "$WORK/cruise.json" 2>&1 >/dev/null)
case "$w" in *"ignoring --scope .workflow/tools/boundaries"*) ok scope-boundaries-warns ;; *) ko scope-boundaries-warns "$w" ;; esac
t scope-only-boundaries 2 "$B" --cache architecture --scope .workflow/tools/boundaries --from-json "$WORK/cruise.json"
t rej-no-scope 2 "$B" --cache architecture --from-json "$WORK/cruise.json"
t rej-glob 2 "$B" --cache architecture --scope 'src/*' --from-json "$WORK/cruise.json"
t rej-dotdot 2 "$B" --cache architecture --scope ../x --from-json "$WORK/cruise.json"
t rej-missing-scope 2 "$B" --cache architecture --scope nope --from-json "$WORK/cruise.json"
t rej-bad-cache 2 "$B" --cache flowsy --scope src --from-json "$WORK/cruise.json"
echo 'not json' >"$WORK/bad.json"
t rej-bad-json 2 "$B" --cache architecture --scope src --from-json "$WORK/bad.json"
echo '{"modules":[{"source":"lib/other.ts","dependencies":[]}]}' >"$WORK/empty.json"
t rej-no-files 2 "$B" --cache architecture --scope src --from-json "$WORK/empty.json"
DEPCRUISE=/nonexistent/depcruise t rej-depcruise-fails 2 "$B" --cache architecture --scope src
cp .workflow/rules.md "$WORK/rules.bak"
printf '# Rules\n\n## Ownership\n\nno block\n' >.workflow/rules.md
t rej-rules-unparseable 2 "$B" --cache architecture --scope src --from-json "$WORK/cruise.json" --allow-dirty
cp "$WORK/rules.bak" .workflow/rules.md

R2="$WORK/repo2"
git_init_repo "$R2"
mkdir -p "$R2/src/a-b" "$R2/src/a_b"
echo 1 >"$R2/src/a-b/i.ts"
echo 1 >"$R2/src/a_b/i.ts"
git_commit_all "$R2" init
echo '{"modules":[{"source":"src/a-b/i.ts","dependencies":[]},{"source":"src/a_b/i.ts","dependencies":[]}]}' >"$WORK/coll.json"
out=$(cd "$R2" && "$B" --cache architecture --scope src --from-json "$WORK/coll.json" 2>&1); rc=$?
eq collision-rc "$rc" 2
check collision-names 'printf "%s" "$out" | grep -q "src/a-b and src/a_b"'

# ---------------------------------------------------------------- check-staged-cache
t chk-arch-ok 0 "$C" architecture .workflow/.cache-staging/architecture.md
printf '%s\n' "$mods" >.workflow/.cache-staging/modules.md
t chk-mod-slot 1 "$C" modules .workflow/.cache-staging/modules.md
sed 's|<!-- slot: purpose -->|Holds code.|' .workflow/.cache-staging/modules.md >"$WORK/m.md" && cp "$WORK/m.md" .workflow/.cache-staging/modules.md
t chk-mod-ok 0 "$C" modules .workflow/.cache-staging/modules.md
printf -- '---\ncache_type: modules\n---\n' | cat - .workflow/.cache-staging/modules.md >"$WORK/fm.md"
t chk-mod-frontmatter-ignored 0 "$C" modules "$WORK/fm.md"
awk 'BEGIN{d=0} /^- Purpose: Holds code\.$/ && !d {print "- Purpose: Holds code. Also more."; d=1; next} {print}' .workflow/.cache-staging/modules.md >"$WORK/m2.md"
t chk-mod-two-sentences 1 "$C" modules "$WORK/m2.md"
awk '/^## src\/main.ts$/ {print "## src/0first"; print ""; print "- Purpose: X."; print "- Files:"; print "- Depends on: none"; print "- Used by: none"; print "- Public interface: none exported"; print ""} {print}' .workflow/.cache-staging/modules.md >"$WORK/m3.md"
t chk-mod-unsorted 1 "$C" modules "$WORK/m3.md"
grep -v '^- Used by' .workflow/.cache-staging/modules.md >"$WORK/m4.md"
t chk-mod-missing-field 1 "$C" modules "$WORK/m4.md"
printf '# Modules\n\n## src/a\n\n- Purpose: Built 2026-10-15T09:30:00Z.\n- Files:\n- Depends on: none\n- Used by: none\n- Public interface: none exported\n' >"$WORK/m5.md"
t chk-mod-timestamp 1 "$C" modules "$WORK/m5.md"

cat >.workflow/.cache-staging/flows.md <<'EOF'
# Flows

## Entry points

- `src/cli/main.ts`
- `src/routes/pay.ts`

## src/cli/main.ts

```mermaid
sequenceDiagram
  participant src_cli as src/cli
  participant src_billing as src/billing
  src_cli->>src_billing: charge()
  alt
    src_billing->>src_cli: Ledger.post()
  end
```

Error branches:
- `src/billing/index.ts` `charge()`: throws `RangeError` when the amount is negative

## src/routes/pay.ts

```mermaid
sequenceDiagram
  participant src_routes as src/routes
  participant src_billing as src/billing
  src_routes->>src_billing: Billing.constructor()
```

Error branches:
- none
EOF
t chk-flows-ok 0 "$C" flows .workflow/.cache-staging/flows.md --html-out "$WORK/flows.html"
eq chk-html-blocks "$(grep -c '<pre class="mermaid">' "$WORK/flows.html")" 2
check chk-html-escaped 'grep -q "src_cli-&gt;&gt;src_billing: charge()" "$WORK/flows.html" && ! grep -q "src_cli->>" "$WORK/flows.html"'
awk '{print} /src_cli->>src_billing: charge\(\)/ {print "  Note over src_cli: hi"}' .workflow/.cache-staging/flows.md >"$WORK/f1.md"
t chk-flows-note 1 "$C" flows "$WORK/f1.md"
awk '{print} /src_routes->>src_billing/ {print "  participant late as src/late"}' .workflow/.cache-staging/flows.md >"$WORK/f2.md"
t chk-flows-late-participant 1 "$C" flows "$WORK/f2.md"
sed 's/charge()/charge(amount)/' .workflow/.cache-staging/flows.md >"$WORK/f3.md"
t chk-flows-args 1 "$C" flows "$WORK/f3.md"
awk '/^- `src\/cli\/main.ts`$/ {hold=$0; next} {print} /^- `src\/routes\/pay.ts`$/ && hold {print hold}' .workflow/.cache-staging/flows.md >"$WORK/f4.md"
t chk-flows-unsorted-list 1 "$C" flows "$WORK/f4.md"
grep -v '^- `src/routes/pay.ts`$' .workflow/.cache-staging/flows.md >"$WORK/f5.md"
t chk-flows-list-mismatch 1 "$C" flows "$WORK/f5.md"
awk '/^Error branches:$/ && !d {d=1; getline; next} {print}' .workflow/.cache-staging/flows.md >"$WORK/f6.md"
t chk-flows-no-error-branches 1 "$C" flows "$WORK/f6.md"
printf '# Flows\n\n## Entry points\n\nNone.\n' >"$WORK/f7.md"
t chk-flows-none-ok 0 "$C" flows "$WORK/f7.md"
printf '# Flows\n\n## Entry points\n\nNone.\n\n## src/x.ts\n' >"$WORK/f8.md"
t chk-flows-none-with-sections 1 "$C" flows "$WORK/f8.md"
printf '# Architecture\n\n## Edges\n\nNone.\n' >"$WORK/a1.md"
t chk-arch-sections 1 "$C" architecture "$WORK/a1.md"
: >"$WORK/empty.md"
t chk-empty 1 "$C" modules "$WORK/empty.md"
t chk-wrong-title 1 "$C" flows .workflow/.cache-staging/architecture.md
t chk-bad-type 2 "$C" bogus .workflow/.cache-staging/flows.md
t chk-missing-file 2 "$C" flows "$WORK/none.md"

shellcheck_files "shellcheck: build-architecture.sh, check-staged-cache.sh" "$B" "$C"
finish
