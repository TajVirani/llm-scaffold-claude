#!/usr/bin/env bash
# File: Helper script (not a hook): generate import-boundary tool config from .workflow/rules.md.
# Purpose: Parse the tool-neutral fenced `yaml` blocks under the fixed Ownership and Shared core headings of .workflow/rules.md (module -> owned paths -> allowed dependencies; D15) and emit per-language config through adapters (D20). First adapter: dependency-cruiser for TS/JS. The rules are the source; the config is derived and never hand-edited.
# Triggers/inputs: Path to the target project (.workflow/rules.md). Called by project-setup at setup, by the rules-boundary-config-sync hook after every approved write to .workflow/rules.md, and by sign-off at 5.3 on hosts without that hook (D9).
# Outputs/handoff: Generated config under .workflow/tools/boundaries/ (.workflow/tools/boundaries/dependency-cruiser.cjs), run by the profile's `boundary` toolchain key at 3.5; non-zero exit when the blocks do not parse (the hook fails the write).
# Plan refs: 00.3, 3.5; reference "Processes outside the flow" (Project setup), "Hooks" (Rules -> boundary config sync); assetlist D15, D20, D38.
# Sources: first-party (D15, D20, D38). dependency-cruiser `forbidden` / `options.tsConfig` format from its rules-reference.md and options-reference.md (MIT). Script style after skills/data-structure-audit/scripts/audit_scope.sh.
# Notes: Requires mikefarah yq v4 (D38) and jq.
#
# Usage:
#   generate-boundary-config.sh [--check] [--adapter NAME] [--print-intermediate] [PROJECT_DIR]
#     PROJECT_DIR           target project root (default: current directory); reads PROJECT_DIR/.workflow/rules.md
#     --check               write nothing; exit 1 if any generated file is missing or differs from a fresh render
#     --adapter NAME        render one adapter only (default: all). Known: dependency-cruiser
#     --print-intermediate  print the tool-neutral intermediate JSON to stdout and exit (no files)
# Exit codes: 0 ok / up to date; 1 --check found stale or missing output; 2 usage error or rules.md
#   does not parse or validate; 3 required tool (yq v4, jq) missing.
#
# Intermediate (tool-neutral, sorted, deterministic):
#   { "modules": { "<name>": { "owns": [glob...], "may_depend_on": [name...] } },
#     "shared_core": { "paths": [glob...] },
#     "forbidden": [ { "name": "<rule>", "from": [glob...], "to": [glob...] } ] }
# Adding an adapter for another language: define `adapter_<name>_file` (prints the output path
# relative to PROJECT_DIR) and `adapter_<name>_render` (reads the intermediate JSON on stdin, prints
# the file content), then append <name> to ADAPTERS.

set -euo pipefail

# Workflow paths (D81).
# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

ADAPTERS=(dependency-cruiser)
RULES_REL="$WF_RULES"

die() { # die EXIT_CODE MESSAGE...
  local code="$1"
  shift
  echo "generate-boundary-config: $*" >&2
  exit "$code"
}

# ---------------------------------------------------------------- parsing

require_tools() {
  command -v jq >/dev/null 2>&1 || die 3 "jq not found on PATH"
  command -v yq >/dev/null 2>&1 || die 3 "yq not found on PATH (mikefarah yq v4 required, D38)"
  yq --version 2>&1 | grep -q 'mikefarah' || die 3 "yq on PATH is not mikefarah yq (v4 required, D38)"
  yq --version 2>&1 | grep -Eq 'version v?4\.' || die 3 "yq is not v4 (mikefarah yq v4 required, D38)"
}

# extract_block FILE HEADING -> prints the single fenced yaml block under "## HEADING".
extract_block() {
  local file="$1" heading="$2" rc=0
  awk -v h="$heading" '
    { sub(/\r$/, "") }
    !infence && /^## / {
      t = $0; sub(/[ \t]+$/, "", t)
      insec = (t == "## " h)
      next
    }
    insec && !infence && /^```yaml[ \t]*$/ { infence = 1; count++; next }
    insec && infence && /^```[ \t]*$/ { infence = 0; next }
    insec && infence && count == 1 { print }
    END { if (count != 1) exit (count == 0 ? 10 : 11) }
  ' "$file" || rc=$?
  case "$rc" in
    0) ;;
    10) die 2 "$file: no fenced yaml block under heading \"## $heading\"" ;;
    11) die 2 "$file: more than one fenced yaml block under heading \"## $heading\"" ;;
    *) die 2 "$file: could not read section \"## $heading\"" ;;
  esac
}

yaml_to_json() { # yaml_to_json LABEL  (YAML on stdin)
  local label="$1" out
  out="$(yq -o=json '.' 2>&1)" || die 2 "$label: block is not valid YAML: $out"
  printf '%s\n' "$out"
}

# build_intermediate RULES_FILE -> validated, sorted intermediate JSON on stdout.
build_intermediate() {
  local file="$1" own_json core_json
  [ -f "$file" ] || die 2 "$file not found"
  # bash 3.2 (macOS) has no inherit_errexit: propagate substitution failures explicitly.
  local own_yaml core_yaml
  own_yaml="$(extract_block "$file" "Ownership")" || exit $?
  own_json="$(printf '%s\n' "$own_yaml" | yaml_to_json "Ownership")" || exit $?
  core_yaml="$(extract_block "$file" "Shared core")" || exit $?
  core_json="$(printf '%s\n' "$core_yaml" | yaml_to_json "Shared core")" || exit $?

  jq -S -n --argjson own "$own_json" --argjson core "$core_json" '
    def fail($m): error($m);
    def strarr($what):
      if type != "array" or any(.[]; type != "string" or length == 0)
      then fail($what + " must be a list of non-empty strings") else . end;
    def glob_ok($what):
      if test("[\\[\\]{}!]") then fail($what + ": unsupported glob character in \"" + . + "\" (use * ** ?)") else . end;

    ($own | if type == "object" and (.modules | type) == "object" then .modules
            else fail("Ownership block must define `modules:` as a map") end) as $mods
    | ($core | if type == "object" and (.shared_core | type) == "object" and (.shared_core.paths | type) == "array"
               then .shared_core.paths
               else fail("Shared core block must define `shared_core.paths:` as a list") end) as $corepaths
    | ($corepaths | strarr("shared_core.paths") | map(glob_ok("shared_core.paths")) | unique) as $core_sorted
    | ($mods | keys) as $names
    | ($mods | to_entries | map(
        .key as $k
        | (if ($k | test("^[A-Za-z0-9._-]+$")) then . else fail("module name \"" + $k + "\" must match [A-Za-z0-9._-]+") end)
        | (.value | if type == "object" then . else fail("module " + $k + " must be a map with owns and may_depend_on") end) as $v
        | ($v.owns // null | if . == null or (type == "array" and length == 0)
              then fail("module " + $k + ": owns must be a non-empty list of globs") else . end
            | strarr("module " + $k + " owns") | map(glob_ok("module " + $k + " owns")) | unique) as $owns
        | (($v.may_depend_on // []) | strarr("module " + $k + " may_depend_on") | unique) as $deps
        | ($deps | map(select(. as $d | $names | index($d) | not))) as $unknown
        | (if ($unknown | length) > 0 then fail("module " + $k + " may_depend_on unknown module(s): " + ($unknown | join(", "))) else . end)
        | (if ($deps | index($k)) then fail("module " + $k + " lists itself in may_depend_on") else . end)
        | { key: $k, value: { owns: $owns, may_depend_on: $deps } }
      ) | from_entries) as $m
    | {
        modules: $m,
        shared_core: { paths: $core_sorted },
        forbidden: (
          ( [ $names[] as $a | $names[] as $b
              | select($a != $b and ($m[$a].may_depend_on | index($b) | not))
              | { name: ($a + "-not-to-" + $b), from: $m[$a].owns, to: $m[$b].owns } ] )
          + ( if ($core_sorted | length) == 0 then []
              else [ $names[] as $b | { name: ("shared-core-not-to-" + $b), from: $core_sorted, to: $m[$b].owns } ] end )
          | sort_by(.name)
        )
      }
  ' 2>&1 || true
}

# ---------------------------------------------------------------- adapters

# --- dependency-cruiser (TS/JS) ---
adapter_dependency-cruiser_file() { echo "$WF_BOUNDARIES/dependency-cruiser.cjs"; }

adapter_dependency-cruiser_render() { # intermediate JSON on stdin -> .cjs on stdout
  local body
  body="$(jq --arg rules "$WF_RULES" '
    # glob -> anchored regex: ** -> .*, **/ -> (.*/|), * -> [^/]*, ? -> [^/], other regex metacharacters escaped
    def g2r:
      ltrimstr("./")
      | gsub("\\*\\*/"; "\u0001") | gsub("\\*\\*"; "\u0002") | gsub("\\*"; "\u0003") | gsub("\\?"; "\u0004")
      | gsub("(?<c>[.+^$(){}|\\\\])"; "\\" + .c)
      | gsub("\u0001"; "(.*/|)") | gsub("\u0002"; ".*") | gsub("\u0003"; "[^/]*") | gsub("\u0004"; "[^/]")
      | "^" + . + "$";
    def paths: map(g2r) | if length == 1 then .[0] else . end;
    {
      forbidden: (.forbidden | map({
        name: .name,
        comment: ("Generated from " + $rules + ": " + (
          if (.name | startswith("shared-core-not-to-")) then "shared core may not depend on module " + (.name | ltrimstr("shared-core-not-to-"))
          else (.name | split("-not-to-") | "module " + .[0] + " may not depend on module " + .[1]) end)),
        severity: "error",
        from: { path: (.from | paths) },
        to: { path: (.to | paths) }
      })),
      options: { tsConfig: { fileName: "tsconfig.json" } }
    }')"
  printf '%s\n' \
    "// GENERATED — do not edit; source $WF_RULES" \
    '// Regenerate with: .agents/skills/project-setup/scripts/generate-boundary-config.sh' \
    "// Run from the project root: depcruise --config $WF_BOUNDARIES/dependency-cruiser.cjs <src>" \
    "module.exports = $body;"
}

# ---------------------------------------------------------------- main

main() {
  local check=0 print_inter=0 only="" project="" a
  while [ $# -gt 0 ]; do
    case "$1" in
      --check) check=1 ;;
      --print-intermediate) print_inter=1 ;;
      --adapter)
        [ $# -ge 2 ] || die 2 "--adapter needs a name"
        only="$2"
        shift
        ;;
      -h | --help)
        sed -n '/^# Usage:/,/^# Adding an adapter/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
      -*) die 2 "unknown option: $1" ;;
      *)
        [ -z "$project" ] || die 2 "more than one PROJECT_DIR given"
        project="$1"
        ;;
    esac
    shift
  done
  project="${project:-.}"
  [ -d "$project" ] || die 2 "project directory not found: $project"

  local selected=()
  for a in "${ADAPTERS[@]}"; do
    if [ -z "$only" ] || [ "$only" = "$a" ]; then selected+=("$a"); fi
  done
  [ "${#selected[@]}" -gt 0 ] || die 2 "unknown adapter: $only (known: ${ADAPTERS[*]})"

  require_tools

  local inter
  inter="$(build_intermediate "$project/$RULES_REL")" || exit $?
  # build_intermediate folds jq errors into its output; a valid result is a JSON object.
  if ! printf '%s' "$inter" | jq -e 'type == "object" and has("forbidden")' >/dev/null 2>&1; then
    die 2 "$project/$RULES_REL: invalid rules: ${inter#jq: error (at <unknown>): }"
  fi

  if [ "$print_inter" -eq 1 ]; then
    printf '%s\n' "$inter"
    exit 0
  fi

  local stale=0 rel out content
  for a in "${selected[@]}"; do
    rel="$("adapter_${a}_file")"
    out="$project/$rel"
    content="$(printf '%s' "$inter" | "adapter_${a}_render")" || exit $?
    if [ "$check" -eq 1 ]; then
      if [ ! -f "$out" ] || [ "$(cat "$out")" != "$content" ]; then
        echo "generate-boundary-config: $rel is out of date; regenerate from $RULES_REL" >&2
        stale=1
      fi
    else
      mkdir -p "$(dirname "$out")"
      if [ ! -f "$out" ] || [ "$(cat "$out")" != "$content" ]; then
        printf '%s\n' "$content" >"$out.tmp.$$"
        mv "$out.tmp.$$" "$out"
        echo "generate-boundary-config: wrote $rel"
      else
        echo "generate-boundary-config: $rel unchanged"
      fi
    fi
  done
  [ "$stale" -eq 0 ] || exit 1
}

main "$@"
