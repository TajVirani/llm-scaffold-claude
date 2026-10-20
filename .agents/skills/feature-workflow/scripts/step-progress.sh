#!/usr/bin/env bash
# File: Helper script (not a hook): print the phase progress line that leads every orchestrator update to the user (D84).
# Purpose: Turn a node id into "Phase 1 of 6 · step 23 of 47 — Discovery: Compute the frontier (0.3.8)". Display only:
#   it reads references/steps.tsv and never writes spec.md, tasks.md or .step. Phase numbers are 1-based; a step's number is its
#   position in its phase's run order, so a repeated step (a questioning round, a wave, a fix loop) keeps its number.
# Usage:
#   step-progress.sh <step-id> [--path full|light] [--at <step-id>]
#   step-progress.sh --spec-dir .workflow/specs/NNN-slug [<step-id>] [--path full|light] [--at <step-id>]
#     <step-id>   the node id; with --spec-dir it defaults to `step` in <spec-dir>/.step
#     --path      which path to count; default: `light_path` in <spec-dir>/spec.md (true = light), else full. The light path runs
#                 Phases 0, 3, 4 and 5 (0.1-0.3.20, then 3.1 on), so it shows "of 4"; before 0.3.20 sizes it, the count is full.
#     --at        for a cross-cutting 00.x id: the linear step it was entered from (discovered work's origin node, 3.1 for 00.19).
#                 The line shows that step, then the 00.x step after it.
#     Run from the project root (main checkout), where .step lives.
# stdout: one line; nothing for an intake id (0.0.x: no progress line before a spec exists).
# Exit codes: 0 printed (or intake); 2 unknown id, an id not on the chosen path, a side artifact id (0.3.21, 3.12), or a 00.x id
#   without --at; 1 usage or environment error (missing steps.tsv, spec.md or .step, missing yq).
# Called by: the feature-workflow orchestrator before each phase or step update it writes to the user (SKILL.md "Progress line").
# Plan refs: assetlist D84; reference "How to read the diagram" (node ids), "Sizing" (light path).
# Notes: bash 3.2 compatible; yq (mikefarah v4) only for --spec-dir.
# Sources: first-party.

set -euo pipefail

PROG=step-progress.sh
HERE=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
STEPS=${STEP_PROGRESS_STEPS:-$HERE/../references/steps.tsv}

die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 1; }
refuse() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }
usage() {
  echo "usage: $PROG <step-id> [--path full|light] [--at <step-id>]" >&2
  echo "       $PROG --spec-dir <spec-dir> [<step-id>] [--path full|light] [--at <step-id>]" >&2
  exit 1
}

ID="" PATH_OPT="" AT="" SPEC_DIR=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --path) [[ $# -ge 2 ]] || usage; PATH_OPT=$2; shift 2 ;;
    --at) [[ $# -ge 2 ]] || usage; AT=$2; shift 2 ;;
    --spec-dir) [[ $# -ge 2 ]] || usage; SPEC_DIR=${2%/}; shift 2 ;;
    -h|--help) usage ;;
    -*) die "unknown option: $1" ;;
    *) [[ -z "$ID" ]] || usage; ID=$1; shift ;;
  esac
done
[[ -f "$STEPS" ]] || die "step list not found: $STEPS"
case "$PATH_OPT" in ""|full|light) ;; *) die "--path must be full or light, not '$PATH_OPT'" ;; esac

if [[ -n "$SPEC_DIR" ]]; then
  command -v yq >/dev/null 2>&1 || die "yq (mikefarah v4) is required for --spec-dir"
  [[ -f "$SPEC_DIR/spec.md" ]] || die "no spec.md in $SPEC_DIR"
  if [[ -z "$PATH_OPT" ]]; then
    lp=$(yq --front-matter=extract '.light_path // false' "$SPEC_DIR/spec.md") || die "cannot read $SPEC_DIR/spec.md"
    if [[ "$lp" == "true" ]]; then PATH_OPT=light; else PATH_OPT=full; fi
  fi
  if [[ -z "$ID" ]]; then
    [[ -f "$SPEC_DIR/.step" ]] || die "no step marker in $SPEC_DIR; pass a step id"
    ID=$(yq '.step // ""' "$SPEC_DIR/.step") || die "cannot read $SPEC_DIR/.step"
    [[ -n "$ID" ]] || die "$SPEC_DIR/.step has no step; pass a step id"
  fi
fi
[[ -n "$ID" ]] || usage
PATH_OPT=${PATH_OPT:-full}

# lookup <id>: prints "<phase>\t<track>\t<title>" or nothing.
lookup() { awk -F'\t' -v id="$1" '!/^#/ && ($1 "") == (id "") { print $2 "\t" $3 "\t" $4; exit }' "$STEPS"; }

# linear <id>: the progress line for a counted step on PATH_OPT.
linear() {
  local row track
  row=$(lookup "$1")
  [[ -n "$row" ]] || refuse "unknown step id '$1' (not in $(basename "$STEPS"))"
  track=$(printf '%s' "$row" | cut -f2)
  case "$track" in
    intake|cross) refuse "'$1' is not a linear step (--at takes a phase step)" ;;
    side) refuse "'$1' is an artifact written alongside other steps, not a step; report the step it is written at" ;;
    both|"$PATH_OPT") ;;
    *) refuse "step $1 is not on the $PATH_OPT path" ;;
  esac
  awk -F'\t' -v id="$1" -v path="$PATH_OPT" '
    /^#/ || $1 == "id" { next }
    $3 == "phase" { name[$2] = $4; next }
    $3 == "both" || $3 == path {
      if (!($2 in seen)) { seen[$2] = 1; order[++np] = $2 }
      n[$2]++
      if (($1 "") == (id "")) { ph = $2; pos = n[$2]; title = $4 }
    }
    END {
      for (i = 1; i <= np; i++) if (order[i] == ph) pi = i
      printf "Phase %d of %d · step %d of %d — %s: %s (%s)", pi, np, pos, n[ph], name[ph], title, id
    }' "$STEPS"
}

row=$(lookup "$ID")
[[ -n "$row" ]] || refuse "unknown step id '$ID' (not in $(basename "$STEPS"))"
track=$(printf '%s' "$row" | cut -f2)
case "$track" in
  intake) exit 0 ;;
  cross)
    [[ -n "$AT" ]] || refuse "'$ID' is a cross-cutting step; pass --at <the linear step it was entered from>"
    line=$(linear "$AT")
    printf '%s · %s (%s)\n' "$line" "$(printf '%s' "$row" | cut -f3)" "$ID"
    ;;
  *)
    [[ -z "$AT" ]] || die "--at is only for a cross-cutting 00.x step"
    line=$(linear "$ID")
    printf '%s\n' "$line"
    ;;
esac
