#!/usr/bin/env bash
# File: Helper script (not a hook): the dependency-cruiser graph extractor, the JS/TS file graph from one dependency-cruiser run.
# Purpose: Print the graph JSON for the files dependency-cruiser reads under the scopes, as dependency-cruiser prints it
#   (uncollapsed, -T json), for build-architecture.sh to merge with the other extractors' graphs.
# Usage:
#   extractors/dependency-cruiser.sh --root DIR --scope PATH [--scope PATH]...
#     --root DIR    project root; depcruise runs there, and a tsconfig.json there is passed with --ts-config
#     --scope PATH  repo-relative file or directory (repeatable, at least one)
# Tools: depcruise is $DEPCRUISE, else <root>/node_modules/.bin/depcruise, else `npx --no-install depcruise`.
# Output: dependency-cruiser JSON on stdout.
# Exit: 0 = printed (an empty modules list is valid); 2 = usage error, depcruise not found or depcruise failed.
# Sources: first-party. dependency-cruiser CLI flags (--no-config, --ts-config, --exclude, -T json) from its doc/cli.md
#   (MIT; tool use only).
set -euo pipefail

# die MSG : print MSG to stderr and exit 2.
die() { echo "extractors/dependency-cruiser: $*" >&2; exit 2; }

root=""
scopes=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) [[ $# -ge 2 ]] || die "--root needs a value"; root="$2"; shift 2 ;;
    --scope) [[ $# -ge 2 ]] || die "--scope needs a value"; scopes+=("$2"); shift 2 ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
[[ -n "$root" ]] || die "--root is required"
[[ ${#scopes[@]} -gt 0 ]] || die "at least one --scope is required"
cd "$root" || die "root not found: $root"
root="$(pwd -P)"

# depcruise_cmd : sets the global array `cmd` to the depcruise to run; returns 1 when none is found.
depcruise_cmd() {
  if [[ -n "${DEPCRUISE:-}" ]]; then cmd=("$DEPCRUISE")
  elif [[ -x "$root/node_modules/.bin/depcruise" ]]; then cmd=("$root/node_modules/.bin/depcruise")
  elif command -v npx >/dev/null 2>&1; then cmd=(npx --no-install depcruise)
  else return 1
  fi
}
cmd=()

ts_args=()
[[ -f "$root/tsconfig.json" ]] && ts_args=(--ts-config tsconfig.json)

errors="$(mktemp "${TMPDIR:-/tmp}/dependency-cruiser.XXXXXX")"
trap 'rm -f "$errors"' EXIT

depcruise_cmd || die "depcruise not found (install dependency-cruiser, or set DEPCRUISE)"
"${cmd[@]}" --no-config ${ts_args[@]+"${ts_args[@]}"} --exclude '(^|/)node_modules/' -T json "${scopes[@]}" \
  2>"$errors" || die "depcruise failed: $(head -5 "$errors")"
