#!/usr/bin/env bash
# File: Shared script (host-neutral, not a hook): run a work profile's toolchain against one task's diff (3.5).
# Purpose: Execute the commands in the profile's Toolchain YAML block (command keys lint, typecheck, format, boundary, test, e2e, plus the optional test_scoped) against the task diff in the task's worktree, and save the output as evidence.
# Triggers/inputs: Args = --spec-dir .workflow/specs/NNN-slug, --task-id <id>, --cwd <task worktree>. Reads work_type from tasks.md, .workflow/profiles/<work-type>.md Toolchain block (via mikefarah yq v4), boundary config under .workflow/tools/boundaries/.
# Outputs/handoff: Tool output saved to .workflow/specs/NNN-slug/artifacts/<task-id>/toolchain.txt; exit 0 = clean (orchestrator launches profile-mini-review), non-zero = failures printed for the implementer, so the stop is blocked until they are fixed.
# Called by: post-implementation-audit.sh (Claude, SubagentStop adapter); the orchestrator directly on Codex or other hosts without that event.
# Steps: 3.5, 3.6; 3.9 (gate run with --exclude-unfinished).
# Sources: first-party.
#
# CLI: run-toolchain.sh --spec-dir <.workflow/specs/NNN-slug> --task-id <id> [--cwd <dir>] [--work-type <name> | --profile <path>]
#                       [--e2e] [--skip <key>]... [--exclude-unfinished] [--tail <N>] [-h]
#   --spec-dir   feature directory; relative paths resolve against the main checkout. Required.
#   --task-id    task id (T1, ...); names the evidence directory. Required.
#   --cwd        directory the commands run in (the task worktree); default: current directory.
#   --work-type  profile name. Without it and without --profile, work_type is read from <spec-dir>/tasks.md for the task id.
#   --profile    explicit profile path (overrides --work-type). Otherwise .workflow/profiles/<work-type>.md is looked up in --cwd, then the main checkout.
#   --e2e        also run the e2e key (last, after the other five). Without it e2e is skipped: 3.5 does not run the browser suite, evidence-capture does (3.10).
#   --skip       skip one command key (repeatable; valid: lint, typecheck, format, boundary, test, e2e; anything else exits 2). The key appears in
#                results as status skipped, reason "skipped by caller". Used for Phase 1 stop audits, which skip `test` because new tests are red by design.
#   --exclude-unfinished  scope `test` for a gate run whose --task-id is not a task record (e.g. the 3.9 harness gate, `--task-id gate-3.9-w2`):
#                exclude the Phase 1 tests of every task whose status is not done (see Test scoping). A task-record --task-id scopes automatically.
#   --tail       lines of output kept per failing command in the digest (default 40).
# Test scoping (Phase 1 tests are red by design until the task that owns them is merged):
#   Each tasks.md record may list `tests: [<selector>...]`, the Phase 1 tests it turns green (paths, ids or name patterns the profile's runner
#   understands; assigned at 2.5). When --task-id names a record, the excluded set is the `tests` of every OTHER record whose status is not
#   done (pending, in-progress, blocked, split-out); with --exclude-unfinished it is the `tests` of every record not done. So the gate judges
#   this task's own tests, the tests of merged (done) tasks and every pre-existing test (regressions since impl_base_revision) together.
#   - Excluded set empty (the last task, the final 3.9 run, no record lists tests): `test` runs unchanged, the whole suite must pass.
#   - Excluded set non-empty and the profile has a `test_scoped` key: that command runs in place of `test` (result key stays `test`), with
#       WF_EXCLUDE_TESTS       space-separated excluded selectors      WF_EXCLUDE_TESTS_FILE  same, one per line
#       WF_TASK_TESTS          this task's own selectors (may be "")  WF_TASK_TESTS_FILE     same, one per line
#       WF_TASK_ID, WF_IMPL_BASE (spec.md impl_base_revision, "" when unset)
#     e.g. vitest: test_scoped: "npx vitest run --coverage $(for t in $WF_EXCLUDE_TESTS; do printf -- '--exclude %s ' \"$t\"; done)"
#   - Excluded set non-empty and no `test_scoped` key: `test` runs; a failure is reported as status "unscoped" (not a failure, a warning in
#     `warnings`), because red tests owned by other tasks cannot be told apart from real failures. Add `test_scoped` to the profile.
#   toolchain.json results for test carry `scoped` (true|false) and `excluded` (count) when scoping applied.
# Commands: keys lint, typecheck, format, boundary, test (then e2e) from the profile's Toolchain yaml block, run in that order with `bash -c` in --cwd.
#   `test` is the harness command that 3.5 runs and the 3.9 gate reuses.
#   Empty or absent keys are skipped. All commands run even after a failure so one block reply lists every failure. Other keys are ignored,
#   (test_scoped only replaces test, see Test scoping), including the non-command keys `serve` and `serve_ready` (review-targets uses them at 4.3) and `config` / `rule_set`: never run.
# Evidence (main checkout, never the worktree, so it survives worktree removal): <spec-dir>/artifacts/<task-id>/toolchain.txt (combined output, one section per key),
#   toolchain.json (the summary below) and toolchain-digest.txt (failure digest; present only on failure).
# stdout: one JSON object {status: pass|fail, task_id, work_type, profile, cwd, evidence_dir, ran, results:[{key, command, status: pass|fail|skipped|unscoped, exit_code, reason?, scoped?, excluded?}], digest, warnings?}.
#   digest is "" on pass; on failure it is bounded text suitable as a SubagentStop block reason. The digest is also printed to stderr on failure.
# Exit: 0 all run commands passed; 1 at least one failed; 2 usage or config error (message on stderr, no JSON).
# Requires: bash, jq, mikefarah yq v4, git (optional; without a repo the main checkout is --cwd).

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

die() { echo "run-toolchain.sh: $*" >&2; exit 2; }

spec_dir="" task_id="" cwd="." work_type="" profile="" want_e2e=0 tail_n=40 skips=" " excl_unfinished=0
while [ $# -gt 0 ]; do
  case "$1" in
    --spec-dir) [ $# -ge 2 ] || die "--spec-dir needs a value"; spec_dir=$2; shift 2 ;;
    --task-id) [ $# -ge 2 ] || die "--task-id needs a value"; task_id=$2; shift 2 ;;
    --cwd) [ $# -ge 2 ] || die "--cwd needs a value"; cwd=$2; shift 2 ;;
    --work-type) [ $# -ge 2 ] || die "--work-type needs a value"; work_type=$2; shift 2 ;;
    --profile) [ $# -ge 2 ] || die "--profile needs a value"; profile=$2; shift 2 ;;
    --e2e) want_e2e=1; shift ;;
    --skip)
      [ $# -ge 2 ] || die "--skip needs a value"
      case "$2" in lint|typecheck|format|boundary|test|e2e) ;; *) die "--skip: unknown key '$2' (valid: lint, typecheck, format, boundary, test, e2e)" ;; esac
      skips="$skips$2 "; shift 2 ;;
    --tail) [ $# -ge 2 ] || die "--tail needs a value"; tail_n=$2; shift 2 ;;
    --exclude-unfinished) excl_unfinished=1; shift ;;
    -h|--help) sed -n '2,/^set -euo/p' "$0" | sed '$d'; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

[ -n "$spec_dir" ] || die "missing --spec-dir"
[ -n "$task_id" ] || die "missing --task-id"
case "$tail_n" in ''|*[!0-9]*) die "--tail must be a non-negative integer" ;; esac
command -v jq >/dev/null 2>&1 || die "jq not found"
command -v yq >/dev/null 2>&1 || die "yq not found (mikefarah yq v4 required)"
yq --version 2>&1 | grep -q 'mikefarah' || die "yq is not mikefarah yq v4"
[ -d "$cwd" ] || die "--cwd is not a directory: $cwd"
cwd=$(cd "$cwd" && pwd)

# Main checkout: gitignored state and evidence live there, not in a worktree.
main_root=$cwd
if common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  main_root=$(dirname "$common")
fi

case "$spec_dir" in
  /*) spec_abs=$spec_dir ;;
  *) spec_abs=$main_root/$spec_dir ;;
esac

# Profile resolution.
if [ -z "$profile" ]; then
  if [ -z "$work_type" ]; then
    tasks_file=$spec_abs/tasks.md
    [ -f "$tasks_file" ] || tasks_file=$cwd/$spec_dir/tasks.md
    [ -f "$tasks_file" ] || die "no --work-type or --profile, and tasks.md not found at $spec_abs/tasks.md"
    work_type=$(TID=$task_id yq --front-matter=extract '.tasks[] | select(.id == strenv(TID)) | .work_type // ""' "$tasks_file" 2>/dev/null | head -n1) \
      || die "cannot read tasks.md frontmatter: $tasks_file"
    [ -n "$work_type" ] || die "task $task_id has no work_type in $tasks_file (or the task does not exist)"
  fi
  for d in "$cwd/$WF_PROFILES" "$main_root/$WF_PROFILES"; do
    if [ -f "$d/$work_type.md" ]; then profile=$d/$work_type.md; break; fi
  done
  [ -n "$profile" ] || die "profile not found: $WF_PROFILES/$work_type.md (looked in $cwd and $main_root)"
fi
[ -f "$profile" ] || die "profile not found: $profile"
[ -n "$work_type" ] || work_type=$(basename "$profile" .md)

# Extract the first fenced yaml block under the "## Toolchain" heading.
block=$(awk '
  /^## /{ if (intool) exit; intool = ($0 ~ /^## Toolchain[[:space:]]*$/); next }
  intool && !infence && /^```ya?ml[[:space:]]*$/ { infence=1; next }
  intool && infence && /^```[[:space:]]*$/ { exit }
  intool && infence { print }
' "$profile")
[ -n "$block" ] || die "no yaml block under '## Toolchain' in $profile"
printf '%s\n' "$block" | yq '.' >/dev/null 2>&1 || die "Toolchain yaml block does not parse in $profile"

# Test scoping: selectors of Phase 1 tests owned by unfinished tasks are excluded from `test`.
excl_list="" own_list="" impl_base=""
scope_tasks=$spec_abs/tasks.md
if [ -f "$scope_tasks" ]; then
  has_rec=$(TID=$task_id yq --front-matter=extract '[.tasks[] | select(.id == strenv(TID))] | length' "$scope_tasks" 2>/dev/null || echo 0)
  if [ "$has_rec" = 1 ] || [ "$excl_unfinished" -eq 1 ]; then
    excl_list=$(TID=$task_id yq --front-matter=extract '.tasks[] | select(.id != strenv(TID) and .status != "done") | (.tests // [])[] | select(tag == "!!str")' "$scope_tasks" 2>/dev/null || true)
    own_list=$(TID=$task_id yq --front-matter=extract '.tasks[] | select(.id == strenv(TID)) | (.tests // [])[] | select(tag == "!!str")' "$scope_tasks" 2>/dev/null || true)
  fi
fi
[ ! -f "$spec_abs/spec.md" ] || impl_base=$(yq --front-matter=extract '.impl_base_revision // "" | select(tag == "!!str")' "$spec_abs/spec.md" 2>/dev/null || true)
n_excl=0
[ -z "$excl_list" ] || n_excl=$(printf '%s\n' "$excl_list" | grep -c .)
warnings='[]'

evidence_dir=$spec_abs/artifacts/$task_id
mkdir -p "$evidence_dir" || die "cannot create $evidence_dir"
: > "$evidence_dir/toolchain.txt"

keys=(lint typecheck format boundary test)   # serve, serve_ready, config, rule_set are never run
[ "$want_e2e" -eq 1 ] && keys+=(e2e)

results='[]' digest="" ran=0 failed=0
for key in "${keys[@]}"; do
  case "$skips" in *" $key "*)
    results=$(jq -c --arg k "$key" '. + [{key:$k, command:"", status:"skipped", exit_code:null, reason:"skipped by caller"}]' <<<"$results")
    continue ;;
  esac
  cmd=$(printf '%s\n' "$block" | K=$key yq '.[strenv(K)] // "" | select(tag == "!!str")' 2>/dev/null || true)
  scoped="" unscoped=0
  if [ "$key" = test ] && [ -n "$cmd" ] && [ "$n_excl" -gt 0 ]; then
    scmd=$(printf '%s\n' "$block" | yq '.test_scoped // "" | select(tag == "!!str")' 2>/dev/null || true)
    if [ -n "$scmd" ]; then cmd=$scmd scoped=true; else scoped=false unscoped=1; fi
  fi
  if [ -z "$cmd" ]; then
    results=$(jq -c --arg k "$key" '. + [{key:$k, command:"", status:"skipped", exit_code:null, reason:"no command"}]' <<<"$results")
    continue
  fi
  log=$(mktemp)
  set +e
  (
    cd "$cwd" || exit 125
    if [ "$key" = test ]; then
      WF_EXCLUDE_TESTS=$(printf '%s' "$excl_list" | tr '\n' ' ') WF_TASK_TESTS=$(printf '%s' "$own_list" | tr '\n' ' ')
      WF_EXCLUDE_TESTS_FILE=$evidence_dir/excluded-tests.txt WF_TASK_TESTS_FILE=$evidence_dir/task-tests.txt
      { [ -z "$excl_list" ] || printf '%s\n' "$excl_list"; } > "$WF_EXCLUDE_TESTS_FILE"
      { [ -z "$own_list" ] || printf '%s\n' "$own_list"; } > "$WF_TASK_TESTS_FILE"
      WF_TASK_ID=$task_id WF_IMPL_BASE=$impl_base
      export WF_EXCLUDE_TESTS WF_TASK_TESTS WF_EXCLUDE_TESTS_FILE WF_TASK_TESTS_FILE WF_TASK_ID WF_IMPL_BASE
    fi
    bash -c "$cmd"
  ) >"$log" 2>&1
  rc=$?
  set -e
  ran=$((ran + 1))
  {
    printf '== %s: %s\n' "$key" "$cmd"
    cat "$log"
    printf '== %s exit %d\n\n' "$key" "$rc"
  } >> "$evidence_dir/toolchain.txt"
  if [ "$rc" -eq 0 ]; then st=pass
  elif [ "$unscoped" -eq 1 ]; then
    st=unscoped
    warnings=$(jq -c --arg m "test failed (exit $rc) but could not be scoped: $n_excl Phase 1 test selector(s) belong to unfinished tasks and the profile has no test_scoped key; not counted as a failure. Add test_scoped to $profile." '. + [$m]' <<<"$warnings")
    printf 'run-toolchain.sh: warning: %s\n' "$(jq -r '.[-1]' <<<"$warnings")" >&2
  else
    st=fail; failed=$((failed + 1))
    digest+=$(printf '[%s] %s exited %d. Last %d lines:\n%s\n\n' "$key" "$cmd" "$rc" "$tail_n" "$(tail -n "$tail_n" "$log" | cut -c1-500)")$'\n'
  fi
  rm -f "$log"
  results=$(jq -c --arg k "$key" --arg c "$cmd" --arg s "$st" --argjson r "$rc" --arg sc "$scoped" --argjson ne "$n_excl" \
    '. + [{key:$k, command:$c, status:$s, exit_code:$r} + (if $sc == "" then {} else {scoped: ($sc == "true"), excluded: $ne} end)]' <<<"$results")
done

if [ "$failed" -gt 0 ]; then
  digest="Toolchain failed for task $task_id ($failed of $ran commands). Fix these in the same context, then stop again.
Full output: $evidence_dir/toolchain.txt

$digest"
  printf '%s' "$digest" > "$evidence_dir/toolchain-digest.txt"
  status=fail
else
  rm -f "$evidence_dir/toolchain-digest.txt"
  status=pass
fi

summary=$(jq -n --arg status "$status" --arg task "$task_id" --arg wt "$work_type" --arg profile "$profile" \
  --arg cwd "$cwd" --arg ev "$evidence_dir" --argjson ran "$ran" --argjson results "$results" --arg digest "$digest" \
  --argjson warnings "$warnings" \
  '{status:$status, task_id:$task, work_type:$wt, profile:$profile, cwd:$cwd, evidence_dir:$ev, ran:$ran, results:$results, digest:$digest}
   + (if ($warnings | length) > 0 then {warnings:$warnings} else {} end)')
printf '%s\n' "$summary" > "$evidence_dir/toolchain.json"
printf '%s\n' "$summary"

if [ "$failed" -gt 0 ]; then
  printf '%s\n' "$digest" >&2
  exit 1
fi
exit 0
