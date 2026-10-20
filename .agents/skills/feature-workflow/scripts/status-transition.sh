#!/usr/bin/env bash
# File: Helper script (not a hook): the single writer for workflow status and the current-step marker.
# Purpose: Write `status` (and `blocked_condition` while blocked) into .workflow/specs/NNN-slug/spec.md frontmatter, or `status`/`work_type` into one task record of the tasks.md frontmatter `tasks:` array (YAML, via yq; D15). One writer, one place. Also writes the gitignored step marker .workflow/specs/NNN-slug/.step that the write guards read through check-write.sh (D16).
# Usage:
#   status-transition.sh status <spec-dir> <new-status> [--step <node-id>] [--blocked <condition>] [--cwd <dir>]
#       Spec status. Validates the transition against the table below, writes the frontmatter, then writes .step.
#   status-transition.sh set-task <spec-dir> <task-id> [--status <status>] [--work-type <wt>] [--capability <id>] [--pr <url>|null] [--step <node-id>] [--cwd <dir>]
#       The single writer for task records in tasks.md frontmatter (D45): task status (validated against the task table below),
#       work_type (set once at 3.1; changing an existing value is refused) and capability (only with --step 5.3, rewriting a
#       provisional CAP-NEW-<slug> to the assigned CAP-###; D44, D52) and pr (the task PR/MR url the orchestrator opened at 3.16,
#       or null to clear it; any step; D85). The other D85 record fields (file, branch, predicted_files, size, mode, parallel_with,
#       tests) are fixed at 2.5 / 0.3.20 and have no flag. The result must pass the tasks.md schema
#       validator from feature-workflow/assets/tasks.md, or nothing is written. Writes .step only when --step is given.
#   status-transition.sh set-spec <spec-dir> [--spec-branch <spec/NNN-slug>] [--impl-base <sha>] [--step <node-id>] [--cwd <dir>]
#       Writes the D85 spec.md frontmatter keys. spec_branch: must equal spec/<NNN-slug> of <spec-dir> and name an existing local
#       branch; set at 1.1 (full path) or 0.3.20 (light path); an existing different value is refused. impl_base_revision: a commit
#       (resolved to its full SHA) that must contain baseline_revision when that is set; set at 3.1 only; once set it is not
#       overwritten (exit 2) unless the value is identical. --step names the node (required: 1.1 | 0.3.20 for --spec-branch,
#       3.1 for --impl-base) and is written to .step. Refused (exit 2) while the spec is done.
#   status-transition.sh step <spec-dir> <node-id> [--cwd <dir>]
#       Step-only mode: set .step before a guarded write (spec.md: 0.1.4, 0.1.6, 0.3.17, 0.3.19, 0.3.20, 0.5.1, 1.1, 2.5, 3.1, 3.14, 4.6, 4.8, 5.1, 5.3, 5.9, 00.29;
#       tasks.md: 2.5, 0.3.20; .workflow/specs/work-backlog/: 00.26, 5.9, 0.1.4; glossaries: 0.2.3, 0.3.15, 0.4.3, 5.3; other Tier A: 0.3.7, 5.3, 5.7; new profile: 00.19 — see check-write.sh).
#       Any node id of the form N(.N)* is accepted, including 00.21-00.29, 2.6, 3.15, 3.16 and 5.9. `step <dir> 0.1.4` works before
#       spec.md exists (the folder must exist), so 0.1.4 can create spec.md with Write.
#       While blocked, step mode keeps blocked_from, so the D56 protocol can write at 00.26 / 00.29 and still resume at 00.28.
#   <spec-dir> is `.workflow/specs/NNN-slug` (relative to the project root, or an absolute path ending in it).
# Worktrees (D18): spec.md, tasks.md and .step are always read and written in the MAIN checkout, found with
#   `git rev-parse --git-common-dir` from --cwd (default: $PWD). Gitignored .step exists only there.
#
# Spec status transitions (PLAN/decision-flow-reference.md "Status", the status edges of PLAN/decision-flow.mermaid, and D47, D49, D56, D58):
#   from                                      to             --step (node that sets it)   why
#   (no status) | draft                       draft          0.1.4 (default)              spec.md created from the template at 0.1.4
#   ready-for-dev                             draft          2.2 | 2.3 (required)         Phase 2 loops back to 0.3.8 (D49)
#   in-review                                 draft          4.5 | 4.6 | 5.6 (required)   review or sign-off loops back to 0.3.8 (D49)
#   draft                                     ready-for-dev  0.6 | 0.3.20 (required)      exit gate, or light-path pass
#   ready-for-dev | in-progress               in-progress    3.1 (default)                orchestrator starts; re-run of 3.1 on resume
#   in-progress | in-review                   in-review      3.11 | 3.14 (required)       journeys pass, or light path without suites (D29);
#                                                                                         in-review again after a 4.7 rework loop
#   in-review                                 done           5.7 (default)                retrospective recorded
#   draft | ready-for-dev | in-progress |     blocked        any node (default: the       any halt; --blocked <condition> required; the prior
#     in-review                                              current .step)               status is kept in .step as blocked_from. At 4.7 the
#                                                                                         caller blocks only with high-severity findings open (D48).
#                                                                                         At 00.21 (discovered work or a crossed size budget, D56,
#                                                                                         D58) the condition must read "discovered work: <slug>"
#                                                                                         or "size budget: <what>"
#   blocked (any blocked_from)                draft          00.24 | 00.29 (required)     discovered-work blocker sent to discovery (00.24), or a
#                                                                                         budget re-scope (00.29): back to 0.3.8 (D56, D58).
#                                                                                         00.24 needs blocked_condition "discovered work: ...",
#                                                                                         00.29 needs "size budget: ..."; otherwise exit 2
#   blocked (blocked_from in-review)          in-review      5.1 | 00.28 (required)       a spec blocked at 4.7 is unblocked at sign-off (D47);
#                                                                                         00.28 resumes review after the D56 protocol, since
#                                                                                         discovered work found during review can be resolved
#   blocked (blocked_from draft |             <blocked_from> any node (default: the       leaving blocked returns to the status held before it;
#     ready-for-dev | in-progress)                           current .step)               00.28 after the D56 protocol (D56)
#   blocked (no blocked_from in .step,        draft | ready-for-dev | in-progress (any node), or in-review (5.1 or 00.28 only); a warning is printed
#     e.g. a fresh clone)
#   done                                      (none)                                      terminal
#   Every other pair is illegal: exit 2 with the reason on stderr. Entering blocked adds blocked_condition; leaving removes it.
#   Not allowed (no plan edge): ready-for-dev -> ready-for-dev, in-review -> ready-for-dev (both loops now pass through draft, D49);
#   in-progress -> draft (Phase 3 reaches discovery only through blocked -> draft at 00.24, D56).
#   baseline_revision is captured with a spec.md Write at step 1.1 (full path) or 3.1 (light path) (D53; see check-write.sh).
#
# Task status transitions (tasks.md `tasks[].status`; template feature-workflow/assets/tasks.md):
#   pending -> in-progress; in-progress -> in-progress (relaunch after a failed gate); in-progress -> done;
#   pending | in-progress -> blocked; blocked -> pending | in-progress; done -> in-progress only with --step 4.7 (rework after review),
#   3.9 or 3.11 (a merged task that fails the harness or journey gate is reopened, D59); done -> blocked only with --step 3.9 or 3.11 (D59).
#   Tasks become done after the wave merge at 3.16 (set-task ... --status done --step 3.16; --step stays optional).
#   pending -> split-out only with --step 00.29: the task's work moved to a work-backlog item at a budget split (D68). split-out is terminal.
#   set-task works while the spec is blocked (running tasks finish their gates mid-wave, D56); --step then keeps blocked_from in .step.
#   Exception: `--status done --step 3.16` (the wave merge) is refused (exit 2) while the spec is blocked; merges wait until 00.28 (D69).
#   Task records carry no blocked_condition key, so --blocked is refused in set-task mode.
#
# .step format (YAML, written only here; read by check-write.sh):
#   step: "<node-id>"
#   updated_at: "<UTC ISO-8601, e.g. 2026-10-15T12:00:00Z>"
#   blocked_from: "<status>"      # present only while spec status is blocked
#
# Exit codes: 0 done; 1 usage or environment error (missing yq, not a git repo, missing file, schema failure); 2 illegal transition (deny), matching check-write.sh and resolve-launch.sh.
# Called by: the phase modules (discovery, verification-setup, task-breakdown, implementation-orchestrator, review-triage, sign-off), domain-modeling and retrospective before guarded writes.
# Plan refs: 0.1.4, 0.3.20, 0.6, 3.1, 3.9, 3.11, 3.14, 3.16, 4.7, 5.7, 00.21, 00.24, 00.28, 00.29 (in-review at 3.11, or 3.14 on a light path without suites, D29); reference "Helper scripts" (Status transition), "Status", "Discovered work"; assetlist D7, D15, D16, D18, D38, D44, D45, D47-D49, D52, D53, D56, D58, D59, D68.
# Notes: Runs via Bash, so the Write/Edit guard hooks do not intercept it; spec-single-writer-guard rejects status edits made by Write/Edit. The deny rule Edit(.workflow/specs/*/.step) stops file tools forging the marker (D36). The marker is accident prevention, not security (D16). install.sh / project-setup add `.workflow/specs/*/.step` to the target's .gitignore. Requires git and mikefarah yq v4 (--front-matter=process edits frontmatter in place; D38).
# Sources: first-party; PLAN/decision-flow-reference.md "Status", "Per-feature files", "Helper scripts", "Discovered work"; PLAN/decision-flow.mermaid status edges; assetlist D7, D15, D16, D18, D29, D36, D38, D44, D45, D47-D49, D52, D53, D56, D58, D59, D68; tasks.md validator from feature-workflow/assets/tasks.md. Pattern: skills/data-structure-audit/scripts/audit_scope.sh (sub-commands, git anchoring).

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=status-transition.sh
SPEC_STATUSES="draft ready-for-dev in-progress in-review done blocked"
TASK_STATUSES="pending in-progress done blocked split-out"

die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-1}"; }
illegal() { die "illegal transition: $1" 2; }

usage() {
  cat >&2 <<'EOF'
usage:
  status-transition.sh status <spec-dir> <new-status> [--step <node-id>] [--blocked <condition>] [--cwd <dir>]
  status-transition.sh set-task <spec-dir> <task-id> [--status <status>] [--work-type <wt>] [--capability <id>] [--pr <url>|null] [--step <node-id>] [--cwd <dir>]
  status-transition.sh set-spec <spec-dir> [--spec-branch <spec/NNN-slug>] [--impl-base <sha>] --step <node-id> [--cwd <dir>]
  status-transition.sh step   <spec-dir> <node-id> [--cwd <dir>]
EOF
  exit 1
}

# in_list <word> "<space-separated list>"
in_list() {
  local w
  # shellcheck disable=SC2086 # split the list on purpose
  for w in $2; do [[ "$w" == "$1" ]] && return 0; done
  return 1
}

valid_node() { [[ "$1" =~ ^[0-9]+(\.[0-9]+)*$ ]]; }

require_yq() {
  command -v yq >/dev/null 2>&1 || die "yq not found on PATH; install mikefarah yq v4 (D38)"
  yq --version 2>/dev/null | grep -q 'mikefarah' || die "yq on PATH is not mikefarah yq v4 (D38): $(yq --version 2>&1 | head -1)"
}

# Main checkout root from any directory inside the repo or one of its worktrees (D18).
main_root() {
  local common
  common=$(git -C "$1" rev-parse --path-format=absolute --git-common-dir 2>/dev/null) \
    || die "not inside a git repository: $1"
  if [[ "$(basename "$common")" == ".git" ]]; then
    dirname "$common"
  else
    git -C "$1" worktree list --porcelain | sed -n '1s/^worktree //p'
  fi
}

# Normalise <spec-dir> to `.workflow/specs/NNN-slug`.
norm_spec_dir() {
  local d=$1
  d=${d%/}
  d=${d#./}
  if [[ "$d" == /* ]]; then
    [[ "$(dirname "$d")" == */"$WF_SPECS" ]] || die "spec dir must be $WF_SPECS/NNN-slug: $1"
    d="$WF_SPECS/$(basename "$d")"
  fi
  [[ "$d" == "$WF_SPECS"/* && "${d#"$WF_SPECS"/}" =~ ^[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*$ ]] \
    || die "spec dir must be $WF_SPECS/NNN-slug: $1"
  printf '%s\n' "$d"
}

utc_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# Read one key of .step (format above); empty when absent.
marker_get() {
  local file=$1 key=$2
  [[ -f "$file" ]] || return 0
  sed -n "s/^${key}:[[:space:]]*\"\{0,1\}\([^\"]*\)\"\{0,1\}[[:space:]]*$/\1/p" "$file" | head -1
}

# write_marker <file> <step> [blocked_from]; atomic replace.
write_marker() {
  local file=$1 step=$2 from=${3:-} tmp
  tmp=$(mktemp "${file}.XXXXXX")
  {
    printf 'step: "%s"\n' "$step"
    printf 'updated_at: "%s"\n' "$(utc_now)"
    [[ -n "$from" ]] && printf 'blocked_from: "%s"\n' "$from"
  } >"$tmp"
  mv -f "$tmp" "$file"
}

# Validator copied verbatim from feature-workflow/assets/tasks.md ("Read and validate with yq"; capability regex per D44); keep the two identical. Applied to the result of every set-task write.
# D85 record fields (file, branch, predicted_files, size, mode, parallel_with, tests, pr) are optional for older task lists, but validated when present.
# yq note: `as $n | ...` binds tighter than `and`, so the whole per-record body is parenthesised after the binding.
# shellcheck disable=SC2016 # yq variables ($n), not shell expansions
TASKS_VALIDATOR='
  (.tasks | tag) == "!!seq" and (.tasks | length) > 0 and
  ([.tasks[].id] | unique | length) == (.tasks | length) and
  ([.tasks[] | select((.id | sub("^T"; "")) as $n | (
      (.id | test("^T[0-9]+$")) and
      (.status | test("^(pending|in-progress|done|blocked|split-out)$")) and
      ((.depends_on | tag) == "!!seq") and
      ((.touches_core | tag) == "!!bool") and
      (.capability | test("^CAP-([0-9]{3,}|NEW-[a-z0-9]+(-[a-z0-9]+)*)$")) and
      ((.work_type | tag) == "!!null" or (.work_type | tag) == "!!str") and
      ([.file == null, ([(.file | tag) == "!!str", ((.file // "") | tostring | test("^tasks/T0*" + $n + "-[A-Za-z0-9][A-Za-z0-9._-]*[.]md$"))] | all)] | any) and
      ([.branch == null, ([(.branch | tag) == "!!str", ((.branch // "") | tostring | test("^task/[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*/T0*" + $n + "-[A-Za-z0-9][A-Za-z0-9._-]*$"))] | all)] | any) and
      ([.predicted_files == null, ([(.predicted_files | tag) == "!!seq", ([.predicted_files[] | select(tag == "!!str" and . != "")] | length) == (.predicted_files | length)] | all)] | any) and
      ([.size == null, ([(.size | tag) == "!!map", (.size.files | tag) == "!!int", ((.size.files // "") | tostring | test("^[0-9]+$")), (.size.est_lines | tag) == "!!int", ((.size.est_lines // "") | tostring | test("^[0-9]+$")), ((.size.points // "") | test("^(S|M|L)$"))] | all)] | any) and
      ([.mode == null, ((.mode | tag) == "!!str" and ((.mode // "") | tostring | test("^(afk|hitl)$")))] | any) and
      ([.parallel_with == null, ([(.parallel_with | tag) == "!!seq", ([.parallel_with[] | select(tag == "!!str") | select(test("^T[0-9]+$"))] | length) == (.parallel_with | length)] | all)] | any) and
      ([.tests == null, ([(.tests | tag) == "!!seq", ([.tests[] | select(tag == "!!str" and . != "")] | length) == (.tests | length)] | all)] | any) and
      ([.pr == null, ((.pr | tag) == "!!str" and ((.pr // "") | tostring | test("^https?://[^[:space:]]+$")))] | any)
    ))] | length) == (.tasks | length)
'

# ---------------------------------------------------------------- arguments
[[ $# -ge 1 ]] || usage
MODE=$1; shift
case "$MODE" in status|step|set-task|set-spec) ;; -h|--help) usage ;; *) die "unknown mode '$MODE' (status|step|set-task|set-spec)";; esac

POS=()
OPT_STEP="" OPT_BLOCKED="" HAVE_BLOCKED=0 OPT_CWD=$PWD
OPT_TSTATUS="" HAVE_WT=0 OPT_WT="" OPT_CAP="" HAVE_PR=0 OPT_PR="" OPT_SBRANCH="" OPT_IBASE=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --step)      [[ $# -ge 2 ]] || usage; OPT_STEP=$2; shift 2 ;;
    --blocked)   [[ $# -ge 2 ]] || usage; OPT_BLOCKED=$2; HAVE_BLOCKED=1; shift 2 ;;
    --cwd)       [[ $# -ge 2 ]] || usage; OPT_CWD=$2; shift 2 ;;
    --status)    [[ $# -ge 2 ]] || usage; OPT_TSTATUS=$2; shift 2 ;;
    --work-type) [[ $# -ge 2 ]] || usage; OPT_WT=$2; HAVE_WT=1; shift 2 ;;
    --capability) [[ $# -ge 2 ]] || usage; OPT_CAP=$2; shift 2 ;;
    --pr)        [[ $# -ge 2 ]] || usage; OPT_PR=$2; HAVE_PR=1; shift 2 ;;
    --spec-branch) [[ $# -ge 2 ]] || usage; OPT_SBRANCH=$2; shift 2 ;;
    --impl-base) [[ $# -ge 2 ]] || usage; OPT_IBASE=$2; shift 2 ;;
    --*)         die "unknown option: $1" ;;
    *)           POS+=("$1"); shift ;;
  esac
done
if [[ "$MODE" == "set-spec" ]]; then [[ ${#POS[@]} -eq 1 ]] || usage; else [[ ${#POS[@]} -eq 2 ]] || usage; fi
[[ -d "$OPT_CWD" ]] || die "--cwd is not a directory: $OPT_CWD"
if [[ "$MODE" != "set-task" && ( -n "$OPT_TSTATUS$OPT_CAP" || $HAVE_WT -eq 1 || $HAVE_PR -eq 1 ) ]]; then
  die "--status, --work-type, --capability and --pr belong to set-task mode"
fi
if [[ "$MODE" != "set-spec" && -n "$OPT_SBRANCH$OPT_IBASE" ]]; then
  die "--spec-branch and --impl-base belong to set-spec mode"
fi

ROOT=$(main_root "$OPT_CWD")
SPEC_DIR=$(norm_spec_dir "${POS[0]}")
ABS_DIR="$ROOT/$SPEC_DIR"
SPEC="$ABS_DIR/spec.md"
TASKS="$ABS_DIR/tasks.md"
MARKER="$ABS_DIR/.step"
if [[ ! -f "$SPEC" ]]; then
  # 0.1.4 creates spec.md with Write, so its step is set before the file exists (the 0.1.3 folder must exist).
  if [[ "$MODE" == "step" && "${POS[1]}" == "0.1.4" && -d "$ABS_DIR" && -z "$OPT_STEP" && $HAVE_BLOCKED -eq 0 ]]; then
    write_marker "$MARKER" "0.1.4"
    printf '%s: %s step 0.1.4 (spec.md not created yet)\n' "$PROG" "$SPEC_DIR"
    exit 0
  fi
  die "spec.md not found in the main checkout: $SPEC"
fi
require_yq

CUR=$(yq --front-matter=extract '.status // ""' "$SPEC") || die "cannot read frontmatter of $SPEC"
[[ "$CUR" == "null" ]] && CUR=""
if [[ -n "$CUR" ]] && ! in_list "$CUR" "$SPEC_STATUSES"; then
  die "spec.md has an unknown status '$CUR' (expected one of: $SPEC_STATUSES)"
fi
MARK_STEP=$(marker_get "$MARKER" step)
MARK_FROM=$(marker_get "$MARKER" blocked_from)

# ---------------------------------------------------------------- step-only mode
if [[ "$MODE" == "step" ]]; then
  NODE=${POS[1]}
  [[ -z "$OPT_STEP" && $HAVE_BLOCKED -eq 0 ]] || die "step mode takes only <spec-dir> <node-id> [--cwd <dir>]"
  valid_node "$NODE" || die "not a plan node id: '$NODE' (expected e.g. 0.3.7)"
  [[ "$CUR" != "done" ]] || illegal "$SPEC_DIR is done; the step marker of a finished feature cannot change"
  from=""
  [[ "$CUR" == "blocked" ]] && from=$MARK_FROM
  write_marker "$MARKER" "$NODE" "$from"
  printf '%s: %s step %s\n' "$PROG" "$SPEC_DIR" "$NODE"
  exit 0
fi

[[ -z "$OPT_STEP" ]] || valid_node "$OPT_STEP" || die "not a plan node id: '$OPT_STEP'"

# ---------------------------------------------------------------- set-task mode (D45)
if [[ "$MODE" == "set-task" ]]; then
  TASK_ID=${POS[1]}
  [[ $HAVE_BLOCKED -eq 0 ]] || die "--blocked applies to spec status only; task records have no blocked_condition"
  [[ -n "$OPT_TSTATUS$OPT_CAP" || $HAVE_WT -eq 1 || $HAVE_PR -eq 1 ]] || die "set-task needs --status, --work-type, --capability and/or --pr"
  [[ "$CUR" != "done" ]] || illegal "$SPEC_DIR is done; its task records cannot change"
  [[ "$TASK_ID" =~ ^T[0-9]+$ ]] || die "task id must look like T<n>: $TASK_ID"
  [[ -f "$TASKS" ]] || die "tasks.md not found in the main checkout: $TASKS"
  export TID=$TASK_ID
  count=$(yq --front-matter=extract '[.tasks[] | select(.id == strenv(TID))] | length' "$TASKS") \
    || die "cannot read the tasks: array in $TASKS"
  [[ "$count" == "1" ]] || die "task $TASK_ID appears $count times in $TASKS (expected exactly once)"
  TCUR=$(yq --front-matter=extract '.tasks[] | select(.id == strenv(TID)) | .status // ""' "$TASKS")
  WCUR=$(yq --front-matter=extract '.tasks[] | select(.id == strenv(TID)) | .work_type // ""' "$TASKS")
  EXPR="."
  MSG=""
  if [[ -n "$OPT_TSTATUS" ]]; then
    in_list "$OPT_TSTATUS" "$TASK_STATUSES" || die "unknown task status '$OPT_TSTATUS' (expected one of: $TASK_STATUSES)"
    case "$TCUR>$OPT_TSTATUS" in
      "pending>in-progress"|"in-progress>in-progress"|"in-progress>done"|\
      "pending>blocked"|"in-progress>blocked"|"blocked>pending"|"blocked>in-progress") ;;
      "done>in-progress")
        in_list "$OPT_STEP" "4.7 3.9 3.11" \
          || illegal "task $TASK_ID in $SPEC_DIR: 'done' -> 'in-progress' is allowed only for rework at 4.7 or a failed gate at 3.9 / 3.11 (pass --step; D59)" ;;
      "pending>split-out")
        [[ "$OPT_STEP" == "00.29" ]] \
          || illegal "task $TASK_ID in $SPEC_DIR: 'pending' -> 'split-out' is allowed only at a budget split (pass --step 00.29; D68)" ;;
      "done>blocked")
        in_list "$OPT_STEP" "3.9 3.11" \
          || illegal "task $TASK_ID in $SPEC_DIR: 'done' -> 'blocked' is allowed only when a merged task fails gate 3.9 or 3.11 (pass --step; D59)" ;;
      *) illegal "task $TASK_ID in $SPEC_DIR: '${TCUR:-<none>}' -> '$OPT_TSTATUS' is not allowed (see the task table at the top of $PROG)" ;;
    esac
    if [[ "$CUR" == "blocked" && "$OPT_TSTATUS" == "done" && "$OPT_STEP" == "3.16" ]]; then
      illegal "task $TASK_ID in $SPEC_DIR: the spec is blocked, so the 3.16 wave merge waits; mark the task done at 3.16 after the spec is unblocked (00.28) (D56, D69)"
    fi
    export NEWV=$OPT_TSTATUS
    EXPR="$EXPR | (.tasks[] | select(.id == strenv(TID)) | .status) = strenv(NEWV)"
    MSG="status $TCUR -> $OPT_TSTATUS"
  fi
  if [[ $HAVE_WT -eq 1 ]]; then
    [[ "$OPT_WT" =~ ^[a-z0-9][a-z0-9._-]*$ ]] || die "work type must name $WF_PROFILES/<work-type>.md (lowercase, digits, . _ -): '$OPT_WT'"
    if [[ -n "$WCUR" && "$WCUR" != "$OPT_WT" ]]; then
      illegal "task $TASK_ID in $SPEC_DIR is already classified as '$WCUR'; a work type is set once at 3.1 and not reclassified"
    fi
    [[ -f "$ROOT/$WF_PROFILES/$OPT_WT.md" ]] \
      || printf '%s: warning: %s/%s.md does not exist yet; pre-launch will deny coding launches until it does (00.19)\n' "$PROG" "$WF_PROFILES" "$OPT_WT" >&2
    export WTV=$OPT_WT
    EXPR="$EXPR | (.tasks[] | select(.id == strenv(TID)) | .work_type) = strenv(WTV)"
    MSG="${MSG:+$MSG, }work_type ${WCUR:-null} -> $OPT_WT"
  fi
  if [[ -n "$OPT_CAP" ]]; then
    [[ "$OPT_CAP" =~ ^CAP-([0-9]{3,}|NEW-[a-z0-9]+(-[a-z0-9]+)*)$ ]] || die "capability must match CAP-### or CAP-NEW-<slug> (D44): '$OPT_CAP'"
    [[ "$OPT_STEP" == "5.3" ]] || illegal "task $TASK_ID in $SPEC_DIR: capability changes only at 5.3, when the provisional id gets its CAP-### (pass --step 5.3; D52)"
    CCUR=$(yq --front-matter=extract '.tasks[] | select(.id == strenv(TID)) | .capability // ""' "$TASKS")
    if [[ "$CCUR" != "$OPT_CAP" ]]; then
      [[ "$CCUR" == CAP-NEW-* && "$OPT_CAP" =~ ^CAP-[0-9]{3,}$ ]] \
        || illegal "task $TASK_ID in $SPEC_DIR: capability '$CCUR' -> '$OPT_CAP'; 5.3 only rewrites a provisional CAP-NEW-<slug> to an assigned CAP-### (D44, D52)"
    fi
    export CAPV=$OPT_CAP
    EXPR="$EXPR | (.tasks[] | select(.id == strenv(TID)) | .capability) = strenv(CAPV)"
    MSG="${MSG:+$MSG, }capability ${CCUR} -> $OPT_CAP"
  fi
  if [[ $HAVE_PR -eq 1 ]]; then
    PCUR=$(yq --front-matter=extract '.tasks[] | select(.id == strenv(TID)) | .pr // ""' "$TASKS")
    if [[ "$OPT_PR" == "null" || -z "$OPT_PR" ]]; then
      EXPR="$EXPR | (.tasks[] | select(.id == strenv(TID)) | .pr) = null"
      MSG="${MSG:+$MSG, }pr ${PCUR:-null} -> null"
    else
      [[ "$OPT_PR" =~ ^https?://[^[:space:]]+$ ]] || die "--pr must be an http(s) URL of the task PR/MR, or null: '$OPT_PR'"
      [[ -z "$PCUR" || "$PCUR" == "$OPT_PR" ]] \
        || printf '%s: warning: task %s pr %s replaced by %s\n' "$PROG" "$TASK_ID" "$PCUR" "$OPT_PR" >&2
      export PRV=$OPT_PR
      EXPR="$EXPR | (.tasks[] | select(.id == strenv(TID)) | .pr) = strenv(PRV)"
      MSG="${MSG:+$MSG, }pr ${PCUR:-null} -> $OPT_PR"
    fi
  fi
  TMP=$(mktemp "${TASKS}.XXXXXX")
  cp "$TASKS" "$TMP"
  yq --front-matter=process -i "$EXPR" "$TMP" || { rm -f "$TMP"; die "cannot update $TASKS"; }
  if ! yq --front-matter=extract -e "$TASKS_VALIDATOR" "$TMP" >/dev/null 2>&1; then
    rm -f "$TMP"
    die "refusing to write $TASKS: the result fails the tasks.md schema validator (feature-workflow/assets/tasks.md)"
  fi
  mv -f "$TMP" "$TASKS"
  if [[ -n "$OPT_STEP" ]]; then
    from=""
    [[ "$CUR" == "blocked" ]] && from=$MARK_FROM
    write_marker "$MARKER" "$OPT_STEP" "$from"
  fi
  printf '%s: %s task %s: %s%s\n' "$PROG" "$SPEC_DIR" "$TASK_ID" "$MSG" "${OPT_STEP:+ (step $OPT_STEP)}"
  exit 0
fi

# ---------------------------------------------------------------- set-spec mode (D85)
if [[ "$MODE" == "set-spec" ]]; then
  [[ $HAVE_BLOCKED -eq 0 ]] || die "--blocked applies to spec status only"
  [[ -n "$OPT_SBRANCH$OPT_IBASE" ]] || die "set-spec needs --spec-branch and/or --impl-base"
  [[ -n "$OPT_STEP" ]] || die "set-spec needs --step (1.1 | 0.3.20 for --spec-branch, 3.1 for --impl-base)"
  [[ "$CUR" != "done" ]] || illegal "$SPEC_DIR is done; its frontmatter cannot change"
  EXPR="." MSG=""
  if [[ -n "$OPT_SBRANCH" ]]; then
    in_list "$OPT_STEP" "1.1 0.3.20" || illegal "$SPEC_DIR: spec_branch is set only at 1.1 (full path) or 0.3.20 (light path), not at $OPT_STEP (D85)"
    want="spec/${SPEC_DIR#"$WF_SPECS"/}"
    [[ "$OPT_SBRANCH" == "$want" ]] || die "spec_branch must be $want for $SPEC_DIR: '$OPT_SBRANCH'"
    git -C "$ROOT" show-ref --verify --quiet "refs/heads/$OPT_SBRANCH" \
      || die "spec_branch $OPT_SBRANCH is not a local branch in $ROOT; create it first (git switch -c $OPT_SBRANCH)"
    SCUR=$(yq --front-matter=extract '.spec_branch // ""' "$SPEC")
    [[ -z "$SCUR" || "$SCUR" == "$OPT_SBRANCH" ]] || illegal "$SPEC_DIR already names spec_branch '$SCUR'"
    export SBV=$OPT_SBRANCH
    EXPR="$EXPR | .spec_branch = strenv(SBV)"
    MSG="spec_branch ${SCUR:-null} -> $OPT_SBRANCH"
  fi
  if [[ -n "$OPT_IBASE" ]]; then
    [[ "$OPT_STEP" == "3.1" ]] || illegal "$SPEC_DIR: impl_base_revision is set only at 3.1, not at $OPT_STEP (D85)"
    [[ "$OPT_IBASE" =~ ^[0-9a-fA-F]{7,40}$ || "$OPT_IBASE" =~ ^[A-Za-z0-9._/@^~-]+$ ]] || die "--impl-base must be a commit: '$OPT_IBASE'"
    SHA=$(git -C "$ROOT" rev-parse --verify --quiet "${OPT_IBASE}^{commit}") || die "--impl-base $OPT_IBASE is not a commit in $ROOT"
    BASEREV=$(yq --front-matter=extract '.baseline_revision // ""' "$SPEC")
    if [[ -n "$BASEREV" && "$BASEREV" != "null" ]]; then
      git -C "$ROOT" merge-base --is-ancestor "$BASEREV" "$SHA" 2>/dev/null \
        || die "impl_base_revision $SHA does not contain baseline_revision $BASEREV; it must be the spec-branch tip after Phase 1"
    fi
    ICUR=$(yq --front-matter=extract '.impl_base_revision // ""' "$SPEC")
    [[ "$ICUR" == "null" ]] && ICUR=""
    [[ -z "$ICUR" || "$ICUR" == "$SHA" ]] || illegal "$SPEC_DIR already has impl_base_revision $ICUR; it is set once at 3.1 and never overwritten"
    export IBV=$SHA
    EXPR="$EXPR | .impl_base_revision = strenv(IBV)"
    MSG="${MSG:+$MSG, }impl_base_revision ${ICUR:-null} -> $SHA"
  fi
  yq --front-matter=process -i "$EXPR" "$SPEC" || die "cannot update $SPEC"
  from=""
  [[ "$CUR" == "blocked" ]] && from=$MARK_FROM
  write_marker "$MARKER" "$OPT_STEP" "$from"
  printf '%s: %s %s (step %s)\n' "$PROG" "$SPEC_DIR" "$MSG" "$OPT_STEP"
  exit 0
fi

NEW=${POS[1]}

# ---------------------------------------------------------------- spec status
in_list "$NEW" "$SPEC_STATUSES" || die "unknown status '$NEW' (expected one of: $SPEC_STATUSES)"
if [[ "$NEW" == "blocked" ]]; then
  [[ $HAVE_BLOCKED -eq 1 && -n "${OPT_BLOCKED//[[:space:]]/}" ]] \
    || die "entering blocked needs --blocked \"<what a human must decide or do>\""
  if [[ "$OPT_STEP" == "00.21" ]]; then
    case "$OPT_BLOCKED" in
      "discovered work: "?*|"size budget: "?*) ;;
      *) die "at 00.21 the condition must read \"discovered work: <slug>\" or \"size budget: <what>\" (D56, D58)" ;;
    esac
  fi
else
  [[ $HAVE_BLOCKED -eq 0 ]] || die "--blocked is only valid when the new status is blocked"
fi

reject() { illegal "$SPEC_DIR: '${CUR:-<none>}' -> '$NEW' is not allowed${1:+: $1} (see the table at the top of $PROG)"; }

# need_step <allowed nodes> <default or empty>: validate or default --step for statuses tied to specific nodes.
need_step() {
  local allowed=$1 default=$2
  if [[ -z "$OPT_STEP" ]]; then
    [[ -n "$default" ]] || die "'$NEW' is set at one of: $allowed; pass --step"
    OPT_STEP=$default
  fi
  in_list "$OPT_STEP" "$allowed" || illegal "$SPEC_DIR: '$NEW' is set only at node(s) $allowed, not at $OPT_STEP"
}

NEW_FROM=""
if [[ "$CUR" == "blocked" ]]; then
  [[ "$NEW" != "blocked" ]] || reject "already blocked"
  [[ "$NEW" != "done" ]] || reject "done is set only from in-review at 5.7"
  if [[ "$NEW" == "draft" && ( "$OPT_STEP" == "00.24" || "$OPT_STEP" == "00.29" ) ]]; then
    # D56/D58: a discovered-work blocker goes to discovery (00.24), or a budget re-scope (00.29), whatever blocked_from is,
    # but only when the blocked_condition was set by that protocol at 00.21.
    BCOND=$(yq --front-matter=extract '.blocked_condition // ""' "$SPEC") || die "cannot read blocked_condition of $SPEC"
    if [[ "$OPT_STEP" == "00.24" ]]; then want="discovered work: "; else want="size budget: "; fi
    [[ "$BCOND" == "$want"* ]] \
      || reject "draft at $OPT_STEP needs a blocked_condition starting with '$want' (set at 00.21), but it is '${BCOND:-<none>}'. 00.24 sends discovered work to discovery and 00.29 re-scopes a crossed size budget (D56, D58)"
  elif [[ -n "$MARK_FROM" ]]; then
    [[ "$NEW" == "$MARK_FROM" ]] \
      || reject "leaving blocked returns to the status held before it ('$MARK_FROM'), or to draft at 00.24 / 00.29 (D56, D58)"
  else
    printf '%s: warning: %s has no blocked_from in .step; accepting %s\n' "$PROG" "$SPEC_DIR" "$NEW" >&2
  fi
  [[ "$NEW" != "in-review" ]] || need_step "5.1 00.28" ""    # D47: an in-review block is lifted at sign-off, or at 00.28 after D56
  [[ -n "$OPT_STEP" ]] || OPT_STEP=$MARK_STEP
  [[ -n "$OPT_STEP" ]] || die "no step marker to resume from; pass --step <node-id>"
else
  case "$CUR>$NEW" in
    ">draft"|"draft>draft")                                   need_step "0.1.4" "0.1.4" ;;
    "ready-for-dev>draft")                                    need_step "2.2 2.3" "" ;;
    "in-review>draft")                                        need_step "4.5 4.6 5.6" "" ;;
    "draft>ready-for-dev")                                    need_step "0.6 0.3.20" "" ;;
    "ready-for-dev>in-progress"|"in-progress>in-progress")    need_step "3.1" "3.1" ;;
    "in-progress>in-review"|"in-review>in-review")            need_step "3.11 3.14" "" ;;
    "in-review>done")                                         need_step "5.7" "5.7" ;;
    "draft>blocked"|"ready-for-dev>blocked"|"in-progress>blocked"|"in-review>blocked")
      NEW_FROM=$CUR
      [[ -n "$OPT_STEP" ]] || OPT_STEP=$MARK_STEP
      [[ -n "$OPT_STEP" ]] || die "no step marker yet; pass --step <node-id> naming where work halted"
      ;;
    "done>"*) reject "done is terminal" ;;
    *) reject "" ;;
  esac
fi

export NEWV=$NEW
if [[ "$NEW" == "blocked" ]]; then
  COND=$OPT_BLOCKED yq --front-matter=process -i \
    '.status = strenv(NEWV) | .blocked_condition = strenv(COND)' "$SPEC"
else
  yq --front-matter=process -i '.status = strenv(NEWV) | del(.blocked_condition)' "$SPEC"
fi
write_marker "$MARKER" "$OPT_STEP" "$NEW_FROM"
printf '%s: %s %s -> %s (step %s)\n' "$PROG" "$SPEC_DIR" "${CUR:-<none>}" "$NEW" "$OPT_STEP"
