#!/usr/bin/env bash
# File: Helper script (not a hook): refuse a merge into the spec branch that would change the spec's artifacts/ folder.
# Purpose: Result files, toolchain evidence and audit files under <spec_dir>/artifacts/ are written in the main checkout and
#   committed there by the orchestrator. A task, Phase 1 or integration branch that adds, changes or deletes a file there
#   (a result file written into the worktree copy, say) would overwrite that record on merge. The orchestrator runs this gate
#   before each merge into the spec branch and merges only on exit 0.
# Usage:
#   check-merge-artifacts.sh --spec-dir <dir> --rev <branch or commit> [--cwd <dir>]
#     --spec-dir  `.workflow/specs/NNN-slug` (relative to the project root, or an absolute path ending in it).
#     --rev       the branch about to be merged, or the commit on the light path (a detached worktree has no branch).
#     --cwd       any directory in the project or one of its worktrees (default $PWD); git runs in the main checkout.
# Rule: diff <rev> against its merge-base with the spec branch spec/NNN-slug; any added, modified or deleted path under
#   <spec_dir>/artifacts/ refuses the merge. Files already committed under artifacts/ on the spec branch do not count.
# stdout: nothing on exit 0; on exit 1 one line per offending path, naming it.
# Exit: 0 no change under artifacts/; 1 refused; 2 usage or environment error (bad arguments, not a git repository, unknown
#   revision, a spec dir that is not NNN-slug, no spec branch, no history shared with the spec branch).
# Called by: modules/verification-setup.md (1.2, 1.3 merges), modules/implementation-orchestrator.md (3.2 integration merge,
#   3.16 task merge, light-path fast-forward). Never pipe it into another command inside an && chain: the pipe hides its exit code.
# Notes: Requires git. Read-only. bash 3.2 compatible.
# Sources: first-party. Pattern: commit-workflow-data.sh (main-checkout resolution, spec-dir normalising).

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=check-merge-artifacts.sh
USAGE="usage: check-merge-artifacts.sh --spec-dir <dir> --rev <branch or commit> [--cwd <dir>]"
# die MSG [CODE] : print "<prog>: MSG" to stderr and exit CODE (default 2; 1 for a refused merge).
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-2}"; }
# usage : print the usage line to stderr and exit 2.
usage() { echo "$USAGE" >&2; exit 2; }

# commit_of REV : print the commit sha REV names in the main checkout; status 1 when it names none.
commit_of() {
  git -C "$ROOT" rev-parse -q --verify --end-of-options "$1^{commit}"
}

SPEC_ARG="" REV="" OPT_CWD=$PWD
while [[ $# -gt 0 ]]; do
  case $1 in
    --spec-dir) [[ $# -ge 2 ]] || usage; SPEC_ARG=$2; shift 2 ;;
    --rev) [[ $# -ge 2 ]] || usage; REV=$2; shift 2 ;;
    --cwd) [[ $# -ge 2 ]] || usage; OPT_CWD=$2; shift 2 ;;
    -h|--help) echo "$USAGE"; exit 0 ;;
    *) usage ;;
  esac
done
[[ -n "$SPEC_ARG" && -n "$REV" ]] || usage

ROOT=$(wf_main_root "$OPT_CWD" 2>/dev/null) || die "not inside a git repository: $OPT_CWD"
SPEC_DIR=$(wf_norm_folder spec "$SPEC_ARG" 2>/dev/null) || die "spec dir must be $WF_SPECS/NNN-slug: $SPEC_ARG"
SPEC_BRANCH="spec/${SPEC_DIR#"$WF_SPECS"/}"

spec_tip=$(commit_of "refs/heads/$SPEC_BRANCH") || die "no spec branch $SPEC_BRANCH in $ROOT"
rev_sha=$(commit_of "$REV") || die "unknown revision: $REV"
base=$(git -C "$ROOT" merge-base "$spec_tip" "$rev_sha") || die "$REV shares no history with $SPEC_BRANCH"

# Diffing from the merge-base, not the spec-branch tip, keeps artifacts the spec branch committed after the fork from
# showing up as deletions. Renames are split so a moved file names both its old and new path.
changed=$(git -C "$ROOT" --literal-pathspecs diff --name-only --no-renames "$base" "$rev_sha" -- "$SPEC_DIR/artifacts/") ||
  die "git diff failed for $REV"
[[ -z "$changed" ]] && exit 0

printf '%s\n' "$changed"
die "$REV changes $(grep -c . <<<"$changed") path(s) under $SPEC_DIR/artifacts/; they reach the spec branch only from the main checkout" 1
