#!/usr/bin/env bash
# File: Helper script (not a hook): derive the generated parts of the Tier B caches from the file graph the project's graph extractors print.
# Purpose: Deterministic, sorted output for a given scope and commit, so a cache can be checked against its stamp. `--cache architecture` prints the whole
#   .workflow/cache/architecture.md body; `--cache modules` prints the modules.md skeleton with one `<!-- slot: purpose -->`
#   per module for the cache-regeneration agent to fill; `--cache entries` prints the flows.md entry-point candidates
#   (files nothing in scope imports, minus test files: the JS/TS test and declaration names and the work profiles' Toolchain
#   `test_patterns`, matched as the step that counts a change's files against its size limit matches them) with what each reaches, as JSON, for the agent to choose from (entry points are discovered each run; there is no config).
#   Body shapes: assets/cache-frontmatter.md "Body shape per cache type". The architecture body ends with "## Unresolved edges":
#   one sorted bullet `- \`<file>:<line>\` \`<source text>\`` (`<file>` alone without a line) per dependency of an in-scope file
#   marked couldNotResolve, the source text taken from its `module`; or `None.`.
# Graph extractors: each work profile (.workflow/profiles/*.md, TEMPLATE.md skipped) names one in its Toolchain yaml block,
#   `graph_extractor: <name>`, where <name> is `none` (a profile with no code) or a script scripts/extractors/<name>.sh
#   (shipped: bash, dependency-cruiser). Every extractor the profiles name runs once as
#   `extractors/<name>.sh --root <root> --scope PATH...` and prints dependency-cruiser-shaped JSON (modules[].source,
#   modules[].dependencies[].resolved) for the files it claims; the graphs are merged, and a file claimed by two extractors is
#   an error. A profile without the key is an error (a breaking change: add the key to every profile).
# Called by: the cache-regeneration agent (.agents/agents/cache-regeneration.md), launched at 0.2.8 or by regenerate-caches.
# Steps: 00.5-00.7, 0.2.8.
# Sources: first-party, including the canonicalisation (dependency-cruiser-shaped JSON -> jq `unique` -> Mermaid, self-edges
#   dropped, id collisions fatal). dependency-cruiser CLI flags (--config, -T json) and JSON shape (modules[].source,
#   dependencies[].resolved, summary.violations) from its doc/cli.md and doc/output-format.md (MIT; tool use only).
#   Declarations via TypeScript --declaration --emitDeclarationOnly (Apache-2.0; tool use only). Script style after
#   .agents/skills/regenerate-caches/scripts/publish-cache.sh.
#
# Usage:
#   build-architecture.sh --cache architecture|modules|entries --scope PATH [--scope PATH]... [options]
#   build-architecture.sh --print-generator [--extractor NAME] [--root DIR]
#     --scope PATH          repo-relative file or directory, no globs, no '..' (repeatable, at least one; '.' = whole repo);
#                           any path under .workflow/tools/boundaries/ is ignored with a stderr warning (stamp-only, never source)
#     --module PATH         module root (repeatable). Default: the owns paths of .workflow/rules.md Ownership plus
#                           shared_core.paths (trailing /** or /* removed; entries still holding a glob skipped), read
#                           through project-setup/scripts/generate-boundary-config.sh --print-intermediate. A file maps
#                           to its longest module root; a file under none maps to <scope>/<first segment>.
#     --out FILE            write here instead of stdout (refused under .workflow/cache/; use .workflow/.cache-staging/<type>.md)
#     --root DIR            repo root override. Default: the MAIN checkout (git --git-common-dir), as publish-cache.sh
#     --allow-dirty         skip the clean-tree check (output then is not tied to HEAD; for tests only)
#     --extractor NAME      run this graph extractor instead of the ones the profiles name; every profile still needs the key
#     --print-generator     print the names of the extractors that would run, sorted and comma-joined (`none` left out), for
#                           publish-cache.sh --generator; needs no --cache or --scope
#     --from-json FILE      use this dependency-cruiser-shaped graph JSON instead of running extractors; profiles are not read for
#                           graph_extractor (entries still reads their test_patterns)
#     --violations-json FILE  architecture only: boundary-check JSON instead of running depcruise --config
#     --dts-dir DIR         modules only: declarations already emitted with --rootDir <root> instead of running tsc
# Tools: each extractor checks its own tools (the dependency-cruiser extractor: $DEPCRUISE, else
#   <root>/node_modules/.bin/depcruise, else `npx --no-install depcruise`). The boundary check runs depcruise the same way
#   when .workflow/tools/boundaries/dependency-cruiser.cjs exists.
#   tsc is $TSC, else <root>/node_modules/.bin/tsc, else `npx --no-install tsc`. A missing tsc or tsconfig.json is not an
#   error: Public interface then lists the functions the graph JSON `exports` gives for the module's files, sorted and unique,
#   `- \`name\` (function)`, and reads "Not generated: <reason>." for a module none of whose files has an `exports` entry.
# Determinism: every list is byte-sorted (LC_ALL=C); no timestamps or counts in the body; the scope paths must have no
#   uncommitted or untracked changes, so the output is a function of HEAD (stamped by publish-cache.sh).
# Exit: 0 = printed or written; 2 = usage error, dirty scope, a profile without graph_extractor or naming an unknown
#   extractor, no work profiles, an extractor that failed or printed no graph, a file claimed by two extractors,
#   unparseable JSON, node-id collision, a test_patterns that is not a list of strings.
# Requires: git, jq, mikefarah yq v4 (to read .workflow/rules.md and the work profiles); each extractor's own tools.
set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"
export LC_ALL=C

die() { echo "build-architecture: $*" >&2; exit 2; }

resolve_root() { # main checkout, same rule as publish-cache.sh
  local common
  common="$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || return 1
  if [[ "$(basename "$common")" == ".git" ]]; then dirname "$common"; else git rev-parse --show-toplevel; fi
}

HERE="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cache=""
root=""
out=""
from_json=""
viol_json=""
dts_dir=""
allow_dirty=0
extractor_override=""
print_generator=0
scopes=()
mods=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --extractor) [[ $# -ge 2 ]] || die "--extractor needs a value"; extractor_override="$2"; shift 2 ;;
    --print-generator) print_generator=1; shift ;;
    --cache) [[ $# -ge 2 ]] || die "--cache needs a value"; cache="$2"; shift 2 ;;
    --scope) [[ $# -ge 2 ]] || die "--scope needs a value"; scopes+=("$2"); shift 2 ;;
    --module) [[ $# -ge 2 ]] || die "--module needs a value"; mods+=("$2"); shift 2 ;;
    --out) [[ $# -ge 2 ]] || die "--out needs a value"; out="$2"; shift 2 ;;
    --root) [[ $# -ge 2 ]] || die "--root needs a value"; root="$2"; shift 2 ;;
    --from-json) [[ $# -ge 2 ]] || die "--from-json needs a value"; from_json="$2"; shift 2 ;;
    --violations-json) [[ $# -ge 2 ]] || die "--violations-json needs a value"; viol_json="$2"; shift 2 ;;
    --dts-dir) [[ $# -ge 2 ]] || die "--dts-dir needs a value"; dts_dir="$2"; shift 2 ;;
    --allow-dirty) allow_dirty=1; shift ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

if [[ $print_generator -eq 0 ]]; then
  case "$cache" in architecture|modules|entries) ;; *) die "--cache must be architecture, modules or entries" ;; esac
  [[ ${#scopes[@]} -gt 0 ]] || die "at least one --scope is required"
fi
command -v git >/dev/null 2>&1 || die "git not found on PATH"
command -v jq >/dev/null 2>&1 || die "jq not found on PATH"

norm_path() { # strip ./ prefix and trailing /, reject absolute, '..' and globs
  local p="$1"
  [[ "$p" == "." ]] && { echo "."; return 0; }
  p="${p#./}"; p="${p%/}"
  [[ -n "$p" && "$p" != /* && "$p" != *..* && "$p" != *[\*\?\[]* ]] \
    || die "path must be repo-relative with no '..' and no globs: $1"
  echo "$p"
}

[[ -n "$root" ]] || root="$(resolve_root)" || die "not in a git repository (use --root)"
root="$(cd "$root" && pwd -P)" || die "root not found: $root"
cd "$root"

# ---------------------------------------------------------------- graph extractors
EXTRACTORS_DIR="$HERE/extractors"

# known_extractors : prints the names of the extractor scripts, comma-separated.
known_extractors() {
  local path names=""
  for path in "$EXTRACTORS_DIR"/*.sh; do
    [[ -f "$path" ]] || continue
    names="${names:+$names, }$(basename "$path" .sh)"
  done
  echo "$names"
}

# require_extractor NAME WHERE : dies unless NAME is an extractor script; WHERE says who named it.
require_extractor() {
  local name="$1" where="$2"
  [[ "$name" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ && -x "$EXTRACTORS_DIR/$name.sh" ]] \
    || die "unknown graph extractor '$name' named by $where (use none or one of: $(known_extractors))"
}

# toolchain_block PROFILE : prints the yaml inside the profile's "## Toolchain" fence; nothing when it has none.
toolchain_block() {
  awk '
    /^## /{ if (intool) exit; intool = ($0 ~ /^## Toolchain[[:space:]]*$/); next }
    intool && !infence && /^```ya?ml[[:space:]]*$/ { infence=1; next }
    intool && infence && /^```[[:space:]]*$/ { exit }
    intool && infence { print }
  ' "$1"
}

# profile_extractors : prints the extractor names the work profiles select, sorted and unique, `none` left out. Dies when
#   a profile has no graph_extractor or names an unknown extractor, and when there are no profiles and no --extractor.
profile_extractors() {
  local path rel block tag value names="" missing="" found=0
  command -v yq >/dev/null 2>&1 || die "yq (mikefarah v4) not found on PATH; it reads graph_extractor from $WF_PROFILES/*.md"
  for path in "$root/$WF_PROFILES"/*.md; do
    [[ -f "$path" && "$(basename "$path")" != TEMPLATE.md ]] || continue
    found=1
    rel="$WF_PROFILES/$(basename "$path")"
    block="$(toolchain_block "$path")"
    tag="$(printf '%s\n' "$block" | yq '.graph_extractor | tag' 2>/dev/null)" \
      || die "the Toolchain yaml block does not parse in $rel"
    if [[ "$tag" == "!!null" ]]; then
      missing="$missing
  $rel"
      continue
    fi
    [[ "$tag" == "!!str" ]] || die "graph_extractor in $rel must be one name: none or one of: $(known_extractors)"
    value="$(printf '%s\n' "$block" | yq '.graph_extractor')"
    [[ "$value" == none ]] && continue
    require_extractor "$value" "$rel"
    names="$names$value
"
  done
  [[ -z "$missing" ]] || die "breaking change: the file graph now comes from the graph extractor each work profile names, and these profiles name none:$missing
Add this line to the Toolchain yaml block of each one:
  graph_extractor: <name>
where <name> is none for a profile with no code, or one of: $(known_extractors)."
  [[ $found -eq 1 || -n "$extractor_override" ]] \
    || die "no work profiles under $WF_PROFILES/: each profile names its graph extractor with graph_extractor (or pass --extractor NAME or --from-json FILE)"
  printf '%s' "$names" | sort -u
}

# selected_extractors : prints the extractors this run uses, one per line: --extractor when given, else the profiles' choice.
#   Every profile must carry graph_extractor either way.
selected_extractors() {
  local from_profiles
  from_profiles="$(profile_extractors)" || exit 2
  if [[ -n "$extractor_override" ]]; then
    require_extractor "$extractor_override" "--extractor"
    echo "$extractor_override"
  elif [[ -n "$from_profiles" ]]; then
    printf '%s\n' "$from_profiles"
  fi
}

if [[ $print_generator -eq 1 ]]; then
  generator="$(selected_extractors)" || exit 2
  printf '%s\n' "$generator" | paste -sd, -
  exit 0
fi

ns=()
for s in "${scopes[@]}"; do
  s="$(norm_path "$s")"
  if [[ "$s" == "$WF_BOUNDARIES" || "$s" == "$WF_BOUNDARIES"/* ]]; then
    echo "build-architecture.sh: ignoring --scope $s ($WF_BOUNDARIES/ is stamp-only, never analysed as source)" >&2
    continue
  fi
  [[ -e "$s" ]] || die "scope path does not exist: $s"
  ns+=("$s")
done
[[ ${#ns[@]} -gt 0 ]] || die "no --scope left after ignoring $WF_BOUNDARIES/ paths"
scopes=("${ns[@]}")
scope_json="$(printf '%s\n' "${scopes[@]}" | jq -R . | jq -s 'unique')"

if [[ -n "$out" ]]; then
  out_dir="$(dirname "$out")"
  mkdir -p "$out_dir"
  out_abs="$(cd "$out_dir" && pwd -P)/$(basename "$out")"
  [[ "$out_abs" != "$root/$WF_CACHE/"* ]] || die "--out must not be under $WF_CACHE/: write to $WF_CACHE_STAGING/ and publish with publish-cache.sh"
fi

if [[ $allow_dirty -eq 0 ]]; then
  dirty="$(git status --porcelain --untracked-files=all -- "${scopes[@]}")"
  [[ -z "$dirty" ]] || die "scope has uncommitted or untracked changes; commit or stash them so the cache matches HEAD:
$dirty"
fi

# ---------------------------------------------------------------- module roots
if [[ ${#mods[@]} -eq 0 && -f "$root/$WF_RULES" ]]; then
  gbc="$HERE/../../project-setup/scripts/generate-boundary-config.sh"
  [[ -x "$gbc" ]] || die "cannot read $WF_RULES: $gbc not found (pass --module)"
  inter="$("$gbc" --print-intermediate "$root")" || die "$WF_RULES Ownership or Shared core does not parse (see generate-boundary-config.sh)"
  while IFS= read -r m; do
    [[ -n "$m" ]] && mods+=("$m")
  done < <(jq -r '[.modules[].owns[], .shared_core.paths[]]
      | map(sub("/\\*\\*$"; "") | sub("/\\*$"; "") | sub("/$"; ""))
      | map(select(test("[*?\\[\\]{}!]") | not)) | unique | .[]' <<<"$inter")
fi
nm=()
for m in ${mods[@]+"${mods[@]}"}; do nm+=("$(norm_path "$m")"); done
mods_json="$(printf '%s\n' ${nm[@]+"${nm[@]}"} | jq -R . | jq -s 'map(select(length > 0)) | unique')"

# ---------------------------------------------------------------- tools
tmpd="$(mktemp -d "${TMPDIR:-/tmp}/build-architecture.XXXXXX")"
trap 'rm -rf "$tmpd"' EXIT

tool_cmd() { # tool_cmd ENVVAR_VALUE NAME -> sets the global array `cmd`; returns 1 when nothing is found
  local env_val="$1" name="$2"
  if [[ -n "$env_val" ]]; then cmd=("$env_val")
  elif [[ -x "$root/node_modules/.bin/$name" ]]; then cmd=("$root/node_modules/.bin/$name")
  elif command -v npx >/dev/null 2>&1; then cmd=(npx --no-install "$name")
  else return 1
  fi
}
cmd=()

# run_extractors NAME... : writes the merged graph of the named extractors to $merged_graph_json. Dies when an extractor fails or
#   prints no .modules array of objects with a string .source, and when two extractors claim the same file, since the merge would then hold the file twice.
run_extractors() {
  local name rc s scope_args=() outputs=() claimed
  for s in "${scopes[@]}"; do scope_args+=(--scope "$s"); done
  for name in "$@"; do
    rc=0
    "$EXTRACTORS_DIR/$name.sh" --root "$root" "${scope_args[@]}" >"$tmpd/graph-$name.json" || rc=$?
    [[ $rc -eq 0 ]] || die "graph extractor $name failed (exit $rc)"
    jq -e '.modules | type == "array"' "$tmpd/graph-$name.json" >/dev/null 2>&1 \
      || die "graph extractor $name printed no JSON with a .modules array"
    jq -e 'all(.modules[]; type == "object" and (.source | type == "string"))' "$tmpd/graph-$name.json" >/dev/null \
      || die "graph extractor $name printed a .modules entry that is not an object with a string .source"
    outputs+=("$tmpd/graph-$name.json")
  done
  if [[ ${#outputs[@]} -eq 0 ]]; then echo '{"modules":[]}' >"$merged_graph_json"; return 0; fi
  claimed="$(jq -rs '
      [range(0; length) as $i | .[$i].modules[].source | {file: ., by: $ARGS.positional[$i]}] | unique
      | group_by(.file) | map(select(length > 1) | "  \(.[0].file) (\(map(.by) | join(", ")))") | .[]' \
    "${outputs[@]}" --args "$@")"
  [[ -z "$claimed" ]] || die "files claimed by more than one graph extractor:
$claimed"
  jq -s '{modules: (map(.modules) | add), exports: (map(.exports // {}) | add)}' "${outputs[@]}" >"$merged_graph_json"
}

merged_graph_json="$tmpd/merged-graph.json"
if [[ -n "$from_json" ]]; then
  graph_origin="--from-json $from_json"
  cp "$from_json" "$merged_graph_json" || die "cannot read --from-json $from_json"
  jq -e '.modules | type == "array"' "$merged_graph_json" >/dev/null 2>&1 || die "--from-json $from_json is not JSON with a .modules array"
else
  selected="$(selected_extractors)" || exit 2
  extractors=()
  while IFS= read -r name; do
    [[ -n "$name" ]] && extractors+=("$name")
  done <<<"$selected"
  graph_origin="graph extractors: ${extractors[*]-none}"
  # bash 3.2 treats an empty array as unset under set -u, so the expansion is guarded.
  run_extractors ${extractors[@]+"${extractors[@]}"}
fi

# graph.json: files in scope, file edges, file -> node, collapsed node edges, unresolved-edge bullets; ids checked for collisions
graph="$tmpd/graph.json"
jq -S --argjson scopes "$scope_json" --argjson mods "$mods_json" '
  def under($p): $p == "." or . == $p or startswith($p + "/");
  def node:
    . as $f
    | ([$mods[] | select(. as $m | $f | under($m))] | max_by(length)) as $m
    | if $m != null then $m
      else ([$scopes[] | select(. as $s | $f | under($s))] | max_by(length)) as $s
      | if $s == null or $s == $f then $f
        else (if $s == "." then $f else ($f | ltrimstr($s + "/")) end | split("/")) as $parts
        | if ($parts | length) == 1 then $f elif $s == "." then $parts[0] else $s + "/" + $parts[0] end
        end
      end;
  def id: gsub("[^A-Za-z0-9]"; "_");
  ([.modules[].source
     | select(test("(^|/)node_modules/") | not)
     | select(. as $f | any($scopes[]; . as $s | $f | under($s)))] | unique) as $files
  | (reduce $files[] as $f ({}; .[$f] = true)) as $in
  | ([.modules[] | select($in[.source]) | .source as $f
      | .dependencies[]? | select(.resolved != null and $in[.resolved] and .resolved != $f) | [$f, .resolved]]
     | unique) as $fedges
  | (reduce $files[] as $f ({}; .[$f] = ($f | node))) as $nodeof
  | ([$files[] | $nodeof[.]] | unique) as $nodes
  | ([$fedges[] | [$nodeof[.[0]], $nodeof[.[1]]] | select(.[0] != .[1])] | unique) as $edges
  | ([.modules[] | select($in[.source]) | .source as $f
      | .dependencies[]? | select(.couldNotResolve == true)
      | "- `\($f)\(if .line != null then ":\(.line)" else "" end)` `\(.module // "")`"]
     | unique) as $unresolved
  | ([$nodes[] | {id: id, name: .}] | group_by(.id) | map(select(length > 1) | map(.name))) as $coll
  | ((.exports // {}) | with_entries(select($in[.key]))) as $exports
  | {files: $files, file_edges: $fedges, node_of: $nodeof, nodes: $nodes, edges: $edges, unresolved: $unresolved,
     exports: $exports, collisions: $coll}
' "$merged_graph_json" >"$graph" || die "could not canonicalise the graph JSON ($graph_origin)"

coll="$(jq -r '.collisions[] | join(" and ")' "$graph")"
[[ -z "$coll" ]] || die "Mermaid node-id collision (rename or pass --module to separate): $coll"
[[ "$(jq '.files | length' "$graph")" -gt 0 ]] || die "no source files under the scope in the graph ($graph_origin)"

# ---------------------------------------------------------------- renderers
render_architecture() {
  echo "# Architecture"
  echo
  echo "## Module graph"
  echo
  echo '```mermaid'
  jq -r 'def id: gsub("[^A-Za-z0-9]"; "_");
    "flowchart LR",
    (.nodes[] | "  \(id)[\"\(gsub("\""; "#quot;"))\"]"),
    (.edges[] | "  \(.[0] | id) --> \(.[1] | id)")' "$graph"
  echo '```'
  echo
  echo "## Edges"
  echo
  if [[ "$(jq '.edges | length' "$graph")" -eq 0 ]]; then echo "None."
  else jq -r '.edges[] | "- `\(.[0])` → `\(.[1])`"' "$graph"; fi
  echo
  echo "## Boundary violations"
  echo
  render_boundary_violations
  echo
  echo "## Unresolved edges"
  echo
  if [[ "$(jq '.unresolved | length' "$graph")" -eq 0 ]]; then echo "None."
  else jq -r '.unresolved[]' "$graph"; fi
}

# render_boundary_violations : prints the body of the Boundary violations section.
render_boundary_violations() {
  local vfile="" vlines
  if [[ -n "$viol_json" ]]; then
    vfile="$viol_json"
  elif [[ -f "$root/$WF_BOUNDARIES/dependency-cruiser.cjs" ]]; then
    vfile="$tmpd/violations.json"
    tool_cmd "${DEPCRUISE:-}" depcruise || die "depcruise not found (install dependency-cruiser, or set DEPCRUISE)"
    # violations make depcruise exit non-zero; only unparseable output is an error
    "${cmd[@]}" --config "$WF_BOUNDARIES/dependency-cruiser.cjs" -T json "${scopes[@]}" >"$vfile" 2>/dev/null || true
  fi
  if [[ -z "$vfile" ]]; then
    echo "Not checked: no boundary config at $WF_BOUNDARIES/dependency-cruiser.cjs."
    return 0
  fi
  vlines="$(jq -r '.summary.violations // error("no .summary.violations")
      | map("- `\(.rule.name)`: `\(.from)` → `\(.to)`") | unique | .[]' "$vfile" 2>/dev/null)" \
    || die "boundary check output is not dependency-cruiser JSON with .summary.violations"
  if [[ -z "$vlines" ]]; then echo "None."; else printf '%s\n' "$vlines"; fi
}

# exports_of DTS_FILE -> "name<TAB>kind" lines for top-level exports of a .d.ts
exports_of() {
  awk '
    function emit(n, k) { gsub(/^[ \t]+|[ \t]+$/, "", n); if (n != "") print n "\t" k }
    /^export \* as / { from = $0; sub(/.* from /, "", from); sub(/;$/, "", from); emit($4, "namespace re-export from " from); next }
    /^export \* from / { from = $0; sub(/^export \* from /, "", from); sub(/;$/, "", from); emit("*", "re-export from " from); next }
    /^export (type )?[{]/ {
      line = $0; from = ""
      if (line ~ /[}] from /) { from = line; sub(/.*[}] from /, "", from); sub(/;$/, "", from) }
      body = line; sub(/^export (type )?[{]/, "", body); sub(/[}].*/, "", body)
      kind = (from == "") ? "re-export" : "re-export from " from
      n = split(body, items, ",")
      for (i = 1; i <= n; i++) {
        it = items[i]; sub(/^[ \t]*type[ \t]+/, "", it)
        if (it ~ / as /) sub(/.* as /, "", it)
        emit(it, kind)
      }
      next
    }
    /^export default / { emit("default", "default export"); next }
    /^export (declare )?(abstract )?(const enum|enum|function|class|const|let|var|namespace|module|interface|type) / {
      rest = $0; sub(/^export /, "", rest); sub(/^declare /, "", rest); sub(/^abstract /, "", rest)
      kind = rest; name = rest
      if (kind ~ /^const enum /) { kind = "enum"; sub(/^const enum /, "", name) }
      else { sub(/ .*/, "", kind); sub(/^[a-z]+ /, "", name) }
      if (kind == "let" || kind == "var") kind = "const"
      if (kind == "module") kind = "namespace"
      sub(/[^A-Za-z0-9_$].*/, "", name)
      emit(name, kind)
    }
  ' "$1" | sort -u
}

# expand_exports DTS_FILE [DEPTH] -> exports_of, with each relative `export * from` replaced by the target's exports
# (up to 5 levels); a target that cannot be found (a package, or not emitted) keeps its `*` line.
expand_exports() {
  local f="$1" depth="${2:-0}" name kind spec base cand found
  while IFS="$(printf '\t')" read -r name kind; do
    if [[ "$name" == "*" && "$kind" == 're-export from ".'* && "$depth" -lt 5 ]]; then
      spec="${kind#re-export from \"}"; spec="${spec%\"}"
      base="$(dirname "$f")/$spec"
      found=""
      for cand in "${base%.*}.d.ts" "${base%.*}.d.mts" "${base%.*}.d.cts" "$base.d.ts" "$base/index.d.ts"; do
        if [[ -f "$cand" ]]; then found="$cand"; break; fi
      done
      if [[ -n "$found" ]]; then expand_exports "$found" $((depth + 1)); continue; fi
    fi
    printf '%s\t%s\n' "$name" "$kind"
  done < <(exports_of "$f")
}

dts_for() { # dts_for NODE -> path of the entry declaration under $dts_dir, or empty
  local n="$1" base
  if [[ -d "$root/$n" ]]; then
    for base in index.d.ts index.d.mts index.d.cts; do
      [[ -f "$dts_dir/$n/$base" ]] && { echo "$dts_dir/$n/$base"; return 0; }
    done
  else
    base="$n"
    case "$base" in
      *.d.ts|*.d.mts|*.d.cts) [[ -f "$dts_dir/$base" ]] && { echo "$dts_dir/$base"; return 0; } ;;
      *.mts) base="${base%.mts}.d.mts" ;;
      *.cts) base="${base%.cts}.d.cts" ;;
      *.tsx) base="${base%.tsx}.d.ts" ;;
      *.ts) base="${base%.ts}.d.ts" ;;
      *.jsx) base="${base%.jsx}.d.ts" ;;
      *.js) base="${base%.js}.d.ts" ;;
    esac
    [[ -f "$dts_dir/$base" ]] && { echo "$dts_dir/$base"; return 0; }
  fi
  return 0
}

# render_function_interface MODULE NOT_GENERATED : prints the module's Public interface line from the graph's exports, the
#   sorted union of its files' functions; NOT_GENERATED when none of its files has an exports entry.
render_function_interface() {
  local functions
  functions="$(jq -r --arg n "$1" '
      .exports as $exports
      | [.node_of | to_entries[] | select(.value == $n) | .key | select($exports[.] != null)] as $files
      | if ($files | length) == 0 then "not generated"
        else [$files[] | $exports[.][]] | unique | .[] | "  - `\(.)` (function)" end' "$graph")"
  if [[ "$functions" == "not generated" ]]; then echo "- Public interface: $2"
  elif [[ -z "$functions" ]]; then echo "- Public interface: none exported"
  else echo "- Public interface:"; printf '%s\n' "$functions"; fi
}

render_modules() {
  local no_dts="" n f lines
  if [[ -z "$dts_dir" ]]; then
    if [[ ! -f "$root/tsconfig.json" ]]; then
      no_dts="Not generated: no tsconfig.json."
    else
      if ! tool_cmd "${TSC:-}" tsc; then
        no_dts="Not generated: tsc not found."
      else
        dts_dir="$tmpd/dts"
        # type errors do not stop emit (--noEmitOnError false); a failed emit leaves files missing
        "${cmd[@]}" -p tsconfig.json --declaration --emitDeclarationOnly --noEmit false --declarationMap false \
          --noEmitOnError false --outDir "$dts_dir" --rootDir . >/dev/null 2>&1 || true
        [[ -d "$dts_dir" ]] || no_dts="Not generated: tsc emitted no declarations."
      fi
    fi
  fi
  echo "# Modules"
  while IFS= read -r n; do
    echo
    echo "## $n"
    echo
    echo "- Purpose: <!-- slot: purpose -->"
    echo "- Files:"
    jq -r --arg n "$n" '.node_of | to_entries | map(select(.value == $n) | .key) | sort | .[] | "  - `\(.)`"' "$graph"
    lines="$(jq -r --arg n "$n" '[.edges[] | select(.[0] == $n) | .[1]] | unique | .[] | "  - `\(.)`"' "$graph")"
    if [[ -z "$lines" ]]; then echo "- Depends on: none"; else echo "- Depends on:"; printf '%s\n' "$lines"; fi
    lines="$(jq -r --arg n "$n" '[.edges[] | select(.[1] == $n) | .[0]] | unique | .[] | "  - `\(.)`"' "$graph")"
    if [[ -z "$lines" ]]; then echo "- Used by: none"; else echo "- Used by:"; printf '%s\n' "$lines"; fi
    if [[ -n "$no_dts" ]]; then
      render_function_interface "$n" "$no_dts"
    else
      f="$(dts_for "$n")"
      if [[ -z "$f" ]]; then
        echo "- Public interface: Not generated: no declaration entry (index or file) for this module."
      else
        lines="$(expand_exports "$f" | sort -u | awk -F '\t' '{ printf "  - `%s` (%s)\n", $1, $2 }')"
        if [[ -z "$lines" ]]; then echo "- Public interface: none exported"; else echo "- Public interface:"; printf '%s\n' "$lines"; fi
      fi
    fi
  done < <(jq -r '.nodes[]' "$graph")
}

# Same defaults and matching as the step that counts a change's files against its size limit, so a file that step counts as a test is never an entry candidate.
DEFAULT_TEST_PATTERNS='*.test.*
*.spec.*
__tests__/
tests/
test/
e2e/
*_test.go
test_*.py
*_test.py'

# test_patterns : prints the test_patterns of every work profile, one per line, sorted and unique; a profile without the key
#   or with [] contributes the defaults, as do no profiles at all. Dies when a profile's test_patterns is not a list of strings.
test_patterns() {
  local path rel block tag patterns all=""
  for path in "$root/$WF_PROFILES"/*.md; do
    [[ -f "$path" && "$(basename "$path")" != TEMPLATE.md ]] || continue
    rel="$WF_PROFILES/$(basename "$path")"
    command -v yq >/dev/null 2>&1 || die "yq (mikefarah v4) not found on PATH; it reads test_patterns from $rel"
    block="$(toolchain_block "$path")"
    tag="$(printf '%s\n' "$block" | yq '.test_patterns | tag' 2>/dev/null)" \
      || die "the Toolchain yaml block does not parse in $rel"
    patterns=""
    if [[ "$tag" != "!!null" ]]; then
      [[ "$tag" == "!!seq" && "$(printf '%s\n' "$block" | yq '[.test_patterns[] | select(tag != "!!str" or . == "")] | length')" == 0 ]] \
        || die "test_patterns in $rel must be a list of non-empty path patterns"
      patterns="$(printf '%s\n' "$block" | yq '.test_patterns[]')"
    fi
    all="$all${patterns:-$DEFAULT_TEST_PATTERNS}
"
  done
  printf '%s\n' "${all:-$DEFAULT_TEST_PATTERNS}" | sed '/^$/d' | sort -u
}

# is_test_file PATH PATTERNS : succeeds when PATH matches a pattern: `dir/` a folder of that name at any depth, a pattern
#   holding another / the whole path, any other pattern the file name (shell globs).
is_test_file() {
  local path="$1" pattern
  while IFS= read -r pattern; do
    if [[ "$pattern" == */ ]]; then
      [[ "/$path" == *"/${pattern%/}/"* ]] && return 0
    elif [[ "$pattern" == */* ]]; then
      # shellcheck disable=SC2053 # the pattern is a glob on purpose
      [[ "$path" == $pattern ]] && return 0
    else
      # shellcheck disable=SC2053 # the pattern is a glob on purpose
      [[ "${path##*/}" == $pattern ]] && return 0
    fi
  done <<<"$2"
  return 1
}

render_entries() {
  local patterns file test_files=""
  patterns="$(test_patterns)" || exit 2
  while IFS= read -r file; do
    if is_test_file "$file" "$patterns"; then test_files="$test_files$file
"; fi
  done < <(jq -r '.files[]' "$graph")
  jq -S --argjson test_files "$(printf '%s' "$test_files" | jq -R . | jq -s .)" '
    (reduce $test_files[] as $f ({}; .[$f] = true)) as $is_test
    | (reduce .file_edges[] as $e ({}; .[$e[0]] += [$e[1]])) as $adj
    | (reduce .file_edges[] as $e ({}; .[$e[1]] = true)) as $imported
    | .node_of as $nodeof
    | def reach:
        def go($seen; $front):
          if ($front | length) == 0 then $seen
          else ([$front[] | ($adj[.] // [])[]] | unique | map(select($seen[.] | not))) as $new
          | go(reduce $new[] as $x ($seen; .[$x] = true); $new) end;
        go({(.): true}; [.]) | keys;
    {candidates: [
      .files[]
      | select($imported[.] | not)
      | select($is_test[.] | not)
      | select(test("(^|/)(__tests__|__mocks__)/|\\.(test|spec)\\.[cm]?[jt]sx?$|\\.d\\.[cm]?ts$") | not)
      | . as $f | (reach) as $r
      | {file: $f, module: $nodeof[$f], reaches_files: $r, reaches_modules: ([$r[] | $nodeof[.]] | unique)}
    ]}' "$graph"
}

if [[ -n "$out" ]]; then
  tmp_out="$tmpd/out"
  "render_$cache" >"$tmp_out"
  mv -f "$tmp_out" "$out_abs"
  echo "${out}"
else
  "render_$cache"
fi
