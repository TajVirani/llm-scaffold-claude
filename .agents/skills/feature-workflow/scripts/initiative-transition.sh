#!/usr/bin/env bash
# File: Helper script (not a hook): the single writer for initiative status, slice and question records, the merge PR URL and the
#   initiative step marker.
# Purpose: Write `status`, `merge_pr` and the `slices[]` records' `status`/`spec` into .workflow/initiatives/NNN-slug/initiative.md
#   frontmatter, and the `questions[]` records' `state`/`launched`/`settled` into questions.md beside it (YAML, via yq). Also writes
#   the gitignored step marker .workflow/initiatives/NNN-slug/.step that the write guards read. Every frontmatter write is made on a
#   copy, checked against the template's validator, then moved into place, so a refused write leaves the file untouched.
# Usage:
#   initiative-transition.sh status       <initiative-dir> <exploring|planned|done> [--step <6.x>] [--cwd <dir>]
#       Initiative status, checked against the status table below. Writes .step only when --step is given.
#   initiative-transition.sh step         <initiative-dir> <6.x> [--cwd <dir>]
#       Sets .step before a guarded write. Works before initiative.md exists (the folder must exist), so the step that copies the
#       template can be set first.
#   initiative-transition.sh set-slice    <initiative-dir> S<n> [--status <planned|emitted|done>] [--spec <NNN-slug>] [--cwd <dir>]
#       One slice record's status, and the spec it was emitted as. --spec is given only together with --status emitted.
#   initiative-transition.sh set-question <initiative-dir> IQ<n> --state <open|researching|settled> [--settled <text>]
#                                         [--launched <task_type>|clear] [--cwd <dir>]
#       One question record's state. `researching` records `launched: {task_type, at}`; `open` and `settled` clear it.
#   initiative-transition.sh set-pr       <initiative-dir> <url>|null [--cwd <dir>]
#       merge_pr: the URL of the PR/MR that merges the initiative branch, or null to clear it.
#   <initiative-dir> is `.workflow/initiatives/NNN-slug` (relative to the project root, or an absolute path ending in it).
# Worktrees: initiative.md, questions.md and .step are read and written in the MAIN checkout, found with
#   `git rev-parse --git-common-dir` from --cwd (default: $PWD). Gitignored .step exists only there.
#
# Initiative status transitions:
#   from                     to          condition
#   (no status) | exploring  exploring   none; the template copied at conversion already reads exploring
#   exploring                planned     every slice is emitted or done, and no question is open or researching
#   planned                  exploring   none (the stakeholder reopens the initiative)
#   planned                  done        every slice is done
#   done                     (none)      terminal: every later call, of any subcommand, exits 2
#   Every other pair exits 2 with the reason on stderr.
#
# Slice transitions (set-slice --status):
#   planned -> emitted   needs --spec, and every question the slice lists must be settled
#   emitted -> done
#   Every other pair exits 2. A planned slice never names a spec, and an emitted or done slice keeps the one it was emitted as.
#
# Question transitions (set-question --state):
#   open        -> researching   kind research only; needs --launched <task_type>; writes launched: {task_type, at}
#   open        -> settled       needs --settled <text>
#   researching -> settled       needs --settled <text>; clears launched
#   researching -> open          clears launched (a launch that never reported back)
#   Every other pair exits 2.
#
# .step format (YAML, written only here; same shape as the spec marker):
#   step: "<6.x>"
#   updated_at: "<UTC ISO-8601, e.g. 2026-10-21T12:00:00Z>"
#
# Exit: 0 done; 1 usage or environment error (missing yq, not a git repo, missing folder or file, unknown slice or question
#   id, malformed value); 2 illegal transition or a result the template validator rejects, with the reason on stderr.
# Called by: the large-path module, at each step that changes initiative state; open-task-pr.sh --record (set-pr).
# Notes: Never calls status-transition.sh and is never called by it. Requires git and mikefarah yq v4.
# Sources: first-party; validators from feature-workflow/assets/initiative.md and assets/questions.md. Pattern:
#   scripts/status-transition.sh.

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=initiative-transition.sh
INITIATIVE_STATUSES="exploring planned done"
SLICE_STATUSES="planned emitted done"
QUESTION_STATES="open researching settled"
LAUNCH_TASK_TYPES="research fact-lookup retrieval library-evaluation"

# die MSG [CODE] : print "<prog>: MSG" to stderr and exit CODE (default 1)
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-1}"; }
# illegal MSG : refuse a transition with exit 2
illegal() { die "illegal transition: $1" 2; }

# usage : print the command forms and exit 1
usage() {
  cat >&2 <<'EOF'
usage:
  initiative-transition.sh status       <initiative-dir> <exploring|planned|done> [--step <6.x>] [--cwd <dir>]
  initiative-transition.sh step         <initiative-dir> <6.x> [--cwd <dir>]
  initiative-transition.sh set-slice    <initiative-dir> S<n> [--status <planned|emitted|done>] [--spec <NNN-slug>] [--cwd <dir>]
  initiative-transition.sh set-question <initiative-dir> IQ<n> --state <open|researching|settled> [--settled <text>] [--launched <task_type>|clear] [--cwd <dir>]
  initiative-transition.sh set-pr       <initiative-dir> <url>|null [--cwd <dir>]
EOF
  exit 1
}

# in_list WORD "LIST" : succeed when WORD is one of the space-separated LIST
in_list() {
  local w
  # shellcheck disable=SC2086 # split the list on purpose
  for w in $2; do [[ "$w" == "$1" ]] && return 0; done
  return 1
}

# valid_large_node ID : succeed when ID is a large-path step id (6.<n>)
valid_large_node() { [[ "$1" =~ ^6\.[0-9]+$ ]]; }

# require_yq : exit 1 unless mikefarah yq v4 is on PATH
require_yq() {
  command -v yq >/dev/null 2>&1 || die "yq not found on PATH; install mikefarah yq v4 (the Python yq has different flags)"
  yq --version 2>/dev/null | grep -q 'mikefarah' || die "yq on PATH is not mikefarah yq v4 (the Python yq has different flags): $(yq --version 2>&1 | head -1)"
}

# main_root DIR : print the main checkout root for DIR, inside the repo or one of its worktrees
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

# norm_initiative_dir DIR : print DIR as `<initiatives root>/NNN-slug`, or exit 1
norm_initiative_dir() {
  local d=$1
  d=${d%/}
  d=${d#./}
  if [[ "$d" == /* ]]; then
    [[ "$(dirname "$d")" == */"$WF_INITIATIVES" ]] || die "initiative dir must be $WF_INITIATIVES/NNN-slug: $1"
    d="$WF_INITIATIVES/$(basename "$d")"
  fi
  [[ "$d" == "$WF_INITIATIVES"/* && "${d#"$WF_INITIATIVES"/}" =~ ^[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*$ ]] \
    || die "initiative dir must be $WF_INITIATIVES/NNN-slug: $1"
  printf '%s\n' "$d"
}

# utc_now : print the current UTC time as ISO-8601
utc_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# write_marker FILE STEP : replace the step marker atomically
write_marker() {
  local file=$1 step=$2 tmp
  tmp=$(mktemp "${file}.XXXXXX")
  {
    printf 'step: "%s"\n' "$step"
    printf 'updated_at: "%s"\n' "$(utc_now)"
  } >"$tmp"
  mv -f "$tmp" "$file"
}

# Each validator below is a copy of the one in its template. Keep each identical to its template, because a write must pass
# the template's own rule.
INITIATIVE_VALIDATOR='
    (.status | test("^(exploring|planned|done)$")) and
    ((.origin | tag) == "!!str") and
    ((.created | tag) == "!!str" or (.created | tag) == "!!timestamp") and
    ((.branch | tag) == "!!str") and
    (.merge_pr == null or (.merge_pr | tag) == "!!str") and
    ((.slices | tag) == "!!seq") and
    (.slices | all_c(
      ((.id | tag) == "!!str") and
      ((.title | tag) == "!!str") and
      (.status | test("^(planned|emitted|done)$")) and
      ((.questions | tag) == "!!seq") and
      ((.depends_on | tag) == "!!seq") and
      (.spec == null or (.spec | tag) == "!!str") and
      ((.status == "planned") == (.spec == null))
    )) and
    (([.slices[].id] | unique | length) == (.slices | length)) and
    (([.slices[].depends_on[]] - [.slices[].id]) | length == 0) and
    (.status == "exploring" or (.slices | all_c(.status != "planned"))) and
    (.status != "done" or (.slices | all_c(.status == "done")))
'
QUESTIONS_VALIDATOR='
    ((.questions | tag) == "!!seq") and
    (.questions | all_c(
      ((.id | tag) == "!!str") and
      (.kind | test("^(research|decision)$")) and
      (.state | test("^(open|researching|settled)$")) and
      ((.question | tag) == "!!str") and
      ((.depends_on | tag) == "!!seq") and
      (.state != "researching" or .kind == "research") and
      ((.state == "researching") == (.launched != null)) and
      (.launched == null or (((.launched.task_type | tag) == "!!str") and ((.launched.at | tag) == "!!str" or (.launched.at | tag) == "!!timestamp"))) and
      ((.state == "settled") == (.settled != null)) and
      (.settled == null or (.settled | tag) == "!!str")
    )) and
    (([.questions[].id] | unique | length) == (.questions | length))
'

# write_validated FILE VALIDATOR EXPR : apply the yq EXPR to a copy of FILE and move it into place only when VALIDATOR accepts it
write_validated() {
  local file=$1 validator=$2 expr=$3 tmp
  tmp=$(mktemp "${file}.XXXXXX")
  cp "$file" "$tmp"
  yq --front-matter=process -i "$expr" "$tmp" || { rm -f "$tmp"; die "cannot update $file"; }
  if ! yq --front-matter=extract -e "$validator" "$tmp" >/dev/null 2>&1; then
    rm -f "$tmp"
    die "refusing to write $file: the result fails the validator of its template in feature-workflow/assets" 2
  fi
  mv -f "$tmp" "$file"
}

# ---------------------------------------------------------------- arguments
[[ $# -ge 1 ]] || usage
MODE=$1; shift
case "$MODE" in
  status|step|set-slice|set-question|set-pr) ;;
  -h|--help) usage ;;
  *) die "unknown subcommand '$MODE' (status|step|set-slice|set-question|set-pr)" ;;
esac

POS=()
OPT_CWD=$PWD OPT_STEP="" OPT_STATUS="" OPT_SPEC="" OPT_STATE="" OPT_LAUNCHED=""
HAVE_SETTLED=0 OPT_SETTLED=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd)      [[ $# -ge 2 ]] || usage; OPT_CWD=$2; shift 2 ;;
    --step)     [[ $# -ge 2 ]] || usage; OPT_STEP=$2; shift 2 ;;
    --status)   [[ $# -ge 2 ]] || usage; OPT_STATUS=$2; shift 2 ;;
    --spec)     [[ $# -ge 2 ]] || usage; OPT_SPEC=$2; shift 2 ;;
    --state)    [[ $# -ge 2 ]] || usage; OPT_STATE=$2; shift 2 ;;
    --launched) [[ $# -ge 2 ]] || usage; OPT_LAUNCHED=$2; shift 2 ;;
    --settled)  [[ $# -ge 2 ]] || usage; OPT_SETTLED=$2; HAVE_SETTLED=1; shift 2 ;;
    --*)        die "unknown option: $1" ;;
    *)          POS+=("$1"); shift ;;
  esac
done
[[ ${#POS[@]} -eq 2 ]] || usage
[[ "$MODE" == "status" || -z "$OPT_STEP" ]] || die "--step belongs to the status subcommand; use '$PROG step' to set the marker"
[[ "$MODE" == "set-slice" || -z "$OPT_STATUS$OPT_SPEC" ]] || die "--status and --spec belong to the set-slice subcommand"
[[ "$MODE" == "set-question" || ( -z "$OPT_STATE$OPT_LAUNCHED" && $HAVE_SETTLED -eq 0 ) ]] \
  || die "--state, --settled and --launched belong to the set-question subcommand"
[[ -d "$OPT_CWD" ]] || die "--cwd is not a directory: $OPT_CWD"

ROOT=$(main_root "$OPT_CWD")
INI_DIR=$(norm_initiative_dir "${POS[0]}")
ABS_DIR="$ROOT/$INI_DIR"
INITIATIVE="$ABS_DIR/initiative.md"
QUESTIONS="$ABS_DIR/questions.md"
MARKER="$ABS_DIR/.step"
[[ -d "$ABS_DIR" ]] || die "initiative folder not found in the main checkout: $ABS_DIR"

if [[ ! -f "$INITIATIVE" ]]; then
  # The step that copies the template sets the marker first, so the guards allow that write.
  if [[ "$MODE" == "step" ]]; then
    valid_large_node "${POS[1]}" || illegal "$INI_DIR: '${POS[1]}' is not a large-path step (expected 6.<n>)"
    write_marker "$MARKER" "${POS[1]}"
    printf '%s: %s step %s (initiative.md not created yet)\n' "$PROG" "$INI_DIR" "${POS[1]}"
    exit 0
  fi
  die "initiative.md not found in the main checkout: $INITIATIVE"
fi
require_yq

CUR=$(yq --front-matter=extract '.status // ""' "$INITIATIVE") || die "cannot read frontmatter of $INITIATIVE"
if [[ -n "$CUR" ]] && ! in_list "$CUR" "$INITIATIVE_STATUSES"; then
  die "initiative.md has an unknown status '$CUR' (expected one of: $INITIATIVE_STATUSES)"
fi
[[ "$CUR" != "done" ]] || illegal "$INI_DIR is done; a finished initiative cannot change"

# ---------------------------------------------------------------- step
if [[ "$MODE" == "step" ]]; then
  NODE=${POS[1]}
  valid_large_node "$NODE" || illegal "$INI_DIR: '$NODE' is not a large-path step (expected 6.<n>)"
  write_marker "$MARKER" "$NODE"
  printf '%s: %s step %s\n' "$PROG" "$INI_DIR" "$NODE"
  exit 0
fi

# ---------------------------------------------------------------- set-pr
if [[ "$MODE" == "set-pr" ]]; then
  PR=${POS[1]}
  PCUR=$(yq --front-matter=extract '.merge_pr // ""' "$INITIATIVE")
  if [[ "$PR" == "null" ]]; then
    write_validated "$INITIATIVE" "$INITIATIVE_VALIDATOR" '.merge_pr = null'
  else
    [[ "$PR" =~ ^https?://[^[:space:]]+$ ]] || die "merge_pr must be an http(s) URL of the PR/MR, or null: '$PR'"
    [[ -z "$PCUR" || "$PCUR" == "$PR" ]] || printf '%s: warning: %s merge_pr %s replaced by %s\n' "$PROG" "$INI_DIR" "$PCUR" "$PR" >&2
    export PRV=$PR
    write_validated "$INITIATIVE" "$INITIATIVE_VALIDATOR" '.merge_pr = strenv(PRV)'
  fi
  printf '%s: %s merge_pr %s -> %s\n' "$PROG" "$INI_DIR" "${PCUR:-null}" "$PR"
  exit 0
fi

# ---------------------------------------------------------------- set-question
if [[ "$MODE" == "set-question" ]]; then
  export QID=${POS[1]}
  [[ "$QID" =~ ^IQ[0-9]+$ ]] || die "question id must look like IQ<n>: $QID"
  [[ -n "$OPT_STATE" ]] || die "set-question needs --state <open|researching|settled>"
  in_list "$OPT_STATE" "$QUESTION_STATES" || die "unknown question state '$OPT_STATE' (expected one of: $QUESTION_STATES)"
  [[ -z "$OPT_LAUNCHED" || "$OPT_LAUNCHED" == "clear" ]] || in_list "$OPT_LAUNCHED" "$LAUNCH_TASK_TYPES" \
    || die "unknown launch task type '$OPT_LAUNCHED' (expected one of: $LAUNCH_TASK_TYPES, or clear)"
  [[ -f "$QUESTIONS" ]] || die "questions.md not found in the main checkout: $QUESTIONS"
  count=$(yq --front-matter=extract '[.questions[] | select(.id == strenv(QID))] | length' "$QUESTIONS") \
    || die "cannot read the questions: array in $QUESTIONS"
  [[ "$count" == "1" ]] || die "question $QID appears $count times in $QUESTIONS (expected exactly once)"
  QCUR=$(yq --front-matter=extract '.questions[] | select(.id == strenv(QID)) | .state // ""' "$QUESTIONS")
  QKIND=$(yq --front-matter=extract '.questions[] | select(.id == strenv(QID)) | .kind // ""' "$QUESTIONS")
  # reject_question [REASON] : refuse this question change with exit 2
  reject_question() { illegal "question $QID in $INI_DIR: '${QCUR:-<none>}' -> '$OPT_STATE' is not allowed${1:+: $1} (see the question table at the top of $PROG)"; }

  [[ $HAVE_SETTLED -eq 0 || "$OPT_STATE" == "settled" ]] || reject_question "--settled is given only when the question settles"
  RECORD='.questions[] | select(.id == strenv(QID))'
  case "$QCUR>$OPT_STATE" in
    "open>researching")
      [[ "$QKIND" == "research" ]] || reject_question "only a research question is researched; a $QKIND question is settled by the stakeholder"
      [[ -n "$OPT_LAUNCHED" && "$OPT_LAUNCHED" != "clear" ]] || reject_question "pass --launched <task_type> naming the agent launched"
      export TASK_TYPE=$OPT_LAUNCHED LAUNCHED_AT
      LAUNCHED_AT=$(utc_now)
      EXPR="($RECORD) |= (.state = \"researching\" | .launched = {\"task_type\": strenv(TASK_TYPE), \"at\": strenv(LAUNCHED_AT)})"
      ;;
    "open>settled"|"researching>settled")
      [[ -n "${OPT_SETTLED//[[:space:]]/}" ]] \
        || reject_question "pass --settled with the source of a research answer or the stakeholder's words for a decision"
      [[ -z "$OPT_LAUNCHED" || "$OPT_LAUNCHED" == "clear" ]] || reject_question "a settled question has no launch"
      export SETTLED_TEXT=$OPT_SETTLED
      EXPR="($RECORD) |= (.state = \"settled\" | .launched = null | .settled = strenv(SETTLED_TEXT))"
      ;;
    "researching>open")
      [[ -z "$OPT_LAUNCHED" || "$OPT_LAUNCHED" == "clear" ]] || reject_question "an open question has no launch"
      EXPR="($RECORD) |= (.state = \"open\" | .launched = null)"
      ;;
    *) reject_question "" ;;
  esac
  write_validated "$QUESTIONS" "$QUESTIONS_VALIDATOR" "$EXPR"
  printf '%s: %s question %s: %s -> %s\n' "$PROG" "$INI_DIR" "$QID" "$QCUR" "$OPT_STATE"
  exit 0
fi

# unsettled_questions ID... : print the ids among ID... that are not settled in questions.md, unknown ids included
unsettled_questions() {
  local settled id
  settled=$(yq --front-matter=extract '.questions[] | select(.state == "settled") | .id' "$QUESTIONS" | tr '\n' ' ') \
    || die "cannot read the questions: array in $QUESTIONS"
  for id in "$@"; do in_list "$id" "$settled" || printf '%s ' "$id"; done
}

# ---------------------------------------------------------------- set-slice
if [[ "$MODE" == "set-slice" ]]; then
  export SID=${POS[1]}
  [[ "$SID" =~ ^S[0-9]+$ ]] || die "slice id must look like S<n>: $SID"
  [[ -n "$OPT_STATUS$OPT_SPEC" ]] || die "set-slice needs --status <planned|emitted|done> and/or --spec <NNN-slug>"
  [[ -z "$OPT_STATUS" ]] || in_list "$OPT_STATUS" "$SLICE_STATUSES" || die "unknown slice status '$OPT_STATUS' (expected one of: $SLICE_STATUSES)"
  [[ -z "$OPT_SPEC" || "$OPT_SPEC" =~ ^[0-9]{3,}-[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "--spec must be a spec folder name NNN-slug: '$OPT_SPEC'"
  count=$(yq --front-matter=extract '[.slices[] | select(.id == strenv(SID))] | length' "$INITIATIVE") \
    || die "cannot read the slices: array in $INITIATIVE"
  [[ "$count" == "1" ]] || die "slice $SID appears $count times in $INITIATIVE (expected exactly once)"
  SCUR=$(yq --front-matter=extract '.slices[] | select(.id == strenv(SID)) | .status // ""' "$INITIATIVE")
  # reject_slice [REASON] : refuse this slice change with exit 2
  reject_slice() { illegal "slice $SID in $INI_DIR: '${SCUR:-<none>}' -> '$OPT_STATUS' is not allowed${1:+: $1} (see the slice table at the top of $PROG)"; }

  if [[ -z "$OPT_STATUS" ]]; then
    [[ "$SCUR" == "planned" ]] && illegal "slice $SID in $INI_DIR is planned, so its spec stays null; name the spec when it is emitted (--status emitted --spec)"
    illegal "slice $SID in $INI_DIR is $SCUR; a slice keeps the spec it was emitted as"
  fi

  RECORD='.slices[] | select(.id == strenv(SID))'
  case "$SCUR>$OPT_STATUS" in
    "planned>emitted")
      [[ -n "$OPT_SPEC" ]] || reject_slice "pass --spec naming the spec the slice was emitted as"
      [[ -f "$QUESTIONS" ]] || die "questions.md not found in the main checkout: $QUESTIONS"
      slice_question_ids=$(yq --front-matter=extract '.slices[] | select(.id == strenv(SID)) | .questions[]' "$INITIATIVE") \
        || die "cannot read the questions of $SID in $INITIATIVE"
      # shellcheck disable=SC2086 # one id per word on purpose
      unsettled=$(unsettled_questions $slice_question_ids)
      [[ -z "$unsettled" ]] || reject_slice "its questions are not all settled: ${unsettled% }"
      export SPEC_NAME=$OPT_SPEC
      EXPR="($RECORD) |= (.status = \"emitted\" | .spec = strenv(SPEC_NAME))"
      ;;
    "emitted>done")
      [[ -z "$OPT_SPEC" ]] || reject_slice "a slice keeps the spec it was emitted as"
      EXPR="($RECORD).status = \"done\""
      ;;
    *) reject_slice "${OPT_SPEC:+a spec is named only when a planned slice is emitted}" ;;
  esac
  write_validated "$INITIATIVE" "$INITIATIVE_VALIDATOR" "$EXPR"
  printf '%s: %s slice %s: %s -> %s%s\n' "$PROG" "$INI_DIR" "$SID" "$SCUR" "$OPT_STATUS" "${OPT_SPEC:+ ($OPT_SPEC)}"
  exit 0
fi

# ---------------------------------------------------------------- status
NEW=${POS[1]}
in_list "$NEW" "$INITIATIVE_STATUSES" || die "unknown status '$NEW' (expected one of: $INITIATIVE_STATUSES)"
[[ -z "$OPT_STEP" ]] || valid_large_node "$OPT_STEP" || illegal "$INI_DIR: '$OPT_STEP' is not a large-path step (expected 6.<n>)"
# reject_status [REASON] : refuse this status change with exit 2
reject_status() { illegal "$INI_DIR: '${CUR:-<none>}' -> '$NEW' is not allowed${1:+: $1} (see the status table at the top of $PROG)"; }

case "$CUR>$NEW" in
  ">exploring"|"exploring>exploring"|"planned>exploring") ;;
  "exploring>planned")
    pending_slices=$(yq --front-matter=extract '.slices[] | select(.status == "planned") | .id' "$INITIATIVE" | tr '\n' ' ')
    [[ -z "$pending_slices" ]] || reject_status "slices not yet emitted: ${pending_slices% }"
    [[ -f "$QUESTIONS" ]] || die "questions.md not found in the main checkout: $QUESTIONS"
    open_questions=$(yq --front-matter=extract '.questions[] | select(.state == "open" or .state == "researching") | .id' "$QUESTIONS" | tr '\n' ' ') \
      || die "cannot read the questions: array in $QUESTIONS"
    [[ -z "$open_questions" ]] || reject_status "questions still open or researching: ${open_questions% }"
    ;;
  "planned>done")
    unfinished=$(yq --front-matter=extract '.slices[] | select(.status != "done") | .id' "$INITIATIVE" | tr '\n' ' ')
    [[ -z "$unfinished" ]] || reject_status "slices not yet done: ${unfinished% }"
    ;;
  *) reject_status "" ;;
esac
export NEW_STATUS=$NEW
write_validated "$INITIATIVE" "$INITIATIVE_VALIDATOR" '.status = strenv(NEW_STATUS)'
[[ -z "$OPT_STEP" ]] || write_marker "$MARKER" "$OPT_STEP"
printf '%s: %s %s -> %s%s\n' "$PROG" "$INI_DIR" "${CUR:-<none>}" "$NEW" "${OPT_STEP:+ (step $OPT_STEP)}"
