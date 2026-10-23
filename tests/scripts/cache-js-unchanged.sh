#!/usr/bin/env bash
# Suite: JRN-002 "JS/TS project unchanged once keyed": build-architecture.sh on the dependency-cruiser and tsc fixtures of the
#   build-architecture suite, with a profile naming `graph_extractor: dependency-cruiser`; and extractors/dependency-cruiser.sh
#   run directly.
# Covers: architecture, modules and entries output byte-identical to the output of build-architecture.sh at the spec's
#   baseline revision, apart from architecture's new "## Unresolved edges" section reading `None.`; the dependency-cruiser
#   extractor passing depcruise's JSON through, calling it with today's flags, and exit 2 naming depcruise when it fails.
#   The expected outputs below were rendered from these fixtures with build-architecture.sh at the baseline revision
#   (86609a64711682747a07bea99a7ed442cf5a827c) and are kept as literals so the oracle never depends on the script under test.
#   CAP-NEW-selectable-graph-extractor.
# shellcheck disable=SC2016  # literal Markdown backticks in single quotes; check expressions are eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/graph-extractors.sh
source "$TESTS_DIR/fixtures/graph-extractors.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
S="$WORK/scaffold/.agents/skills/regenerate-caches/scripts"
B="$S/build-architecture.sh"
X="$S/extractors/dependency-cruiser.sh"
R="$WORK/repo"
js_project_repo "$R"
write_profile "$R" web dependency-cruiser
git_commit_all "$R" "web profile"
write_cruise_json "$WORK/cruise.json"
write_dts_dir "$WORK/dts"
depcruise_stub "$WORK/depcruise" "$WORK/cruise.json" "$WORK/depcruise.args"
export DEPCRUISE="$WORK/depcruise"
cd "$R" || exit 1

baseline_arch='# Architecture

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

baseline_modules='# Modules

## src/a

- Purpose: <!-- slot: purpose -->
- Files:
  - `src/a/index.ts`
  - `src/a/x.test.ts`
  - `src/a/x.ts`
- Depends on:
  - `src/b`
- Used by:
  - `src/main.ts`
- Public interface:
  - `Alpha` (class)
  - `Mode` (enum)
  - `Opts` (interface)
  - `T` (type)
  - `Z` (re-export from "../b/y.js")
  - `counter` (const)
  - `f` (function)
  - `why` (re-export from "../b/y.js")

## src/b

- Purpose: <!-- slot: purpose -->
- Files:
  - `src/b/y.ts`
- Depends on:
  - `src/b/sub`
- Used by:
  - `src/a`
- Public interface: Not generated: no declaration entry (index or file) for this module.

## src/b/sub

- Purpose: <!-- slot: purpose -->
- Files:
  - `src/b/sub/z.ts`
- Depends on: none
- Used by:
  - `src/b`
- Public interface: Not generated: no declaration entry (index or file) for this module.

## src/main.ts

- Purpose: <!-- slot: purpose -->
- Files:
  - `src/main.ts`
- Depends on:
  - `src/a`
- Used by: none
- Public interface:
  - `default` (default export)'

baseline_entries='{
  "candidates": [
    {
      "file": "src/main.ts",
      "module": "src/main.ts",
      "reaches_files": [
        "src/a/index.ts",
        "src/a/x.ts",
        "src/b/sub/z.ts",
        "src/b/y.ts",
        "src/main.ts"
      ],
      "reaches_modules": [
        "src/a",
        "src/b",
        "src/b/sub",
        "src/main.ts"
      ]
    }
  ]
}'

unresolved_none='

## Unresolved edges

None.'

echo "== JRN-002 build-architecture.sh against the baseline renders"
arch=$("$B" --cache architecture --scope src); rc=$?
eq "JRN-002 architecture exits 0" "$rc" 0
eq "JRN-002 architecture is the baseline plus Unresolved edges reading None." "$arch" "$baseline_arch$unresolved_none"
mods=$("$B" --cache modules --scope src --dts-dir "$WORK/dts"); rc=$?
eq "JRN-002 modules exits 0" "$rc" 0
eq "JRN-002 modules is byte-identical to the baseline" "$mods" "$baseline_modules"
ent=$("$B" --cache entries --scope src); rc=$?
eq "JRN-002 entries exits 0" "$rc" 0
eq "JRN-002 entries is byte-identical to the baseline" "$ent" "$baseline_entries"

echo "== JRN-002 extractors/dependency-cruiser.sh"
rm -f "$WORK/depcruise.args"
graph=$("$X" --root "$R" --scope src); rc=$?
eq "JRN-002 extractor exits 0" "$rc" 0
eq "JRN-002 extractor prints depcruise's JSON unchanged" "$(jq -S . <<<"$graph" 2>/dev/null)" "$(jq -S . "$WORK/cruise.json")"
eq "JRN-002 extractor calls depcruise with today's flags" "$(cat "$WORK/depcruise.args" 2>/dev/null)" '--no-config
--exclude
(^|/)node_modules/
-T
json
src'
out=$(DEPCRUISE=/nonexistent/depcruise "$X" --root "$R" --scope src 2>&1); rc=$?
eq "JRN-002 extractor exits 2 when depcruise fails" "$rc" 2
check "JRN-002 extractor names depcruise when it fails" 'printf "%s" "$out" | grep -q depcruise' "$out"
t "JRN-002 extractor with no arguments is a usage error" 2 "$X"

shellcheck_files "shellcheck: build-architecture.sh, extractors/dependency-cruiser.sh" "$B" "$X"
finish
