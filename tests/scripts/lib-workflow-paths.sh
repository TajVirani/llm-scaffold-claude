#!/usr/bin/env bash
# Suite: .agents/lib/workflow-paths.sh, the shared folder helpers wf_main_root, wf_project_root and wf_norm_folder (JRN-006).
# Covers: wf_main_root from the main checkout, a sub-folder, a worktree and a folder outside git; wf_project_root from the
#   main checkout, a sub-folder, an agent worktree and an isolation worktree (the checkout they sit in), a spec worktree (itself),
#   an agent worktree inside a spec worktree (the spec worktree), a plain folder or a separate repository whose path only looks
#   like an agent worktree (their own top level) and a folder outside git (1, with a reason); WF_SPEC_WORKTREES; wf_norm_folder for each
#   spec and initiative input form (relative, dot-relative with a trailing slash, absolute under the main checkout or a
#   worktree, bare NNN-slug, absolute path elsewhere), a folder of the other kind, slugs the folder rule refuses, and an
#   unknown kind; each refusal returns 1 with a reason naming the argument and prints no folder. The helpers run sourced
#   under `set -euo pipefail` from a copy of .agents/, the way the scripts use them.
#   JRN-001: wf_enc and wf_agent_worktree_name give the bytes the hooks' old codex_enc gave (recorded below) for work types and
#   agent types, under LC_ALL=C and a UTF-8 locale; task, phase_1 and integration names from each spec dir form; malformed
#   spec folders, an unknown kind, a task id that is not T<digits> and an empty work type return 1 with a reason naming the
#   argument and print no name; a missing argument returns 1 under set -u; neither hook keeps a codex_enc copy.
#   JRN-004 (spec 007): WF_SPECS_DONE is .workflow/specs/done, built from WF_SPECS; wf_norm_folder spec maps each form of a
#   spec in the Done folder (relative, dot-relative, absolute under the main checkout or a worktree) to
#   .workflow/specs/done/NNN-slug, takes any digit count and the usual slug class there, and refuses the Done folder itself,
#   a nested or non-spec child of it, a backlog child and an absolute path elsewhere; wf_norm_folder initiative takes no done/.
#   JRN-012 (spec 00014): wf_norm_folder spec accepts a Done folder spec renamed with the old_ prefix (relative and absolute
#   forms, any digit count) and still refuses old_ outside the Done folder and malformed old_ names (no number, a non-digit
#   number, old- or OLD_, the prefix twice, no slug).
# shellcheck disable=SC2016  # the bash -c programs are single-quoted on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/workflow-folders.sh
source "$TESTS_DIR/fixtures/workflow-folders.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
LIB="$WORK/scaffold/.agents/lib/workflow-paths.sh"
folder_fixture_repo "$WORK/p"
mkdir -p "$FOLDER_REPO/sub/dir"

# lib_call FUNCTION ARGS... : run a workflow-paths.sh function in a clean bash with the strict options the scripts use.
lib_call() { bash -c 'set -euo pipefail; . "$1"; shift; "$@"' _ "$LIB" "$@"; }
# stdout_and_status FUNCTION ARGS... : prints "<status>|<stdout>"; stderr is dropped.
stdout_and_status() {
  local out rc
  out=$(lib_call "$@" 2>/dev/null)
  rc=$?
  printf '%s|%s\n' "$rc" "$out"
}
# refusal FUNCTION ARGS... : prints "<status>|<stdout and stderr>".
refusal() {
  local out rc
  out=$(lib_call "$@" 2>&1)
  rc=$?
  printf '%s|%s\n' "$rc" "$out"
}

echo "== sourcing"
eq "JRN-006 sourcing workflow-paths.sh prints nothing" "$(bash -c 'set -euo pipefail; . "$1"' _ "$LIB" 2>&1)" ""

echo "== wf_main_root"
eq "JRN-006 wf_main_root from the main checkout prints its root" "$(stdout_and_status wf_main_root "$FOLDER_REPO")" "0|$FOLDER_REPO"
eq "JRN-006 wf_main_root from a sub-folder prints the main checkout root" \
  "$(stdout_and_status wf_main_root "$FOLDER_REPO/sub/dir")" "0|$FOLDER_REPO"
eq "JRN-006 wf_main_root from a worktree prints the main checkout root" "$(stdout_and_status wf_main_root "$FOLDER_WT")" "0|$FOLDER_REPO"
eq "JRN-006 wf_main_root outside a git repository returns 1 and prints no root" \
  "$(stdout_and_status wf_main_root "$FOLDER_REPO-elsewhere")" "1|"

echo "== wf_project_root"
SPEC_WT=$FOLDER_REPO/.workflow/.spec-worktrees/002-beta
git -C "$FOLDER_REPO" worktree add -q "$SPEC_WT" -b spec/002-beta
git -C "$SPEC_WT" worktree add -q "$SPEC_WT/.workflow/.worktrees/s002_t1" -b task/002-beta/T01-x
git -C "$FOLDER_REPO" worktree add -q "$FOLDER_REPO/.claude/worktrees/agent-1" -b iso-1
mkdir -p "$FOLDER_REPO/.workflow/.worktrees/plain" "$WORK/lookalike/.workflow/.worktrees"
git_init_repo "$WORK/lookalike/.workflow/.worktrees/solo"
eq "WF_SPEC_WORKTREES is .workflow/.spec-worktrees" "$(bash -c '. "$1"; printf %s "$WF_SPEC_WORKTREES"' _ "$LIB")" ".workflow/.spec-worktrees"
eq "wf_project_root from the main checkout prints its root" "$(stdout_and_status wf_project_root "$FOLDER_REPO")" "0|$FOLDER_REPO"
eq "wf_project_root from a sub-folder prints the checkout root" "$(stdout_and_status wf_project_root "$FOLDER_REPO/sub/dir")" "0|$FOLDER_REPO"
eq "wf_project_root from an agent worktree prints the checkout it sits in" "$(stdout_and_status wf_project_root "$FOLDER_WT")" "0|$FOLDER_REPO"
eq "wf_project_root from an isolation worktree prints the checkout it sits in" \
  "$(stdout_and_status wf_project_root "$FOLDER_REPO/.claude/worktrees/agent-1")" "0|$FOLDER_REPO"
eq "wf_project_root from a spec worktree prints the spec worktree" "$(stdout_and_status wf_project_root "$SPEC_WT/.workflow")" "0|$SPEC_WT"
eq "wf_project_root from an agent worktree inside a spec worktree prints the spec worktree" \
  "$(stdout_and_status wf_project_root "$SPEC_WT/.workflow/.worktrees/s002_t1")" "0|$SPEC_WT"
eq "wf_main_root from an agent worktree inside a spec worktree prints the main checkout" \
  "$(stdout_and_status wf_main_root "$SPEC_WT/.workflow/.worktrees/s002_t1")" "0|$FOLDER_REPO"
eq "wf_project_root from a plain folder named like an agent worktree prints the checkout root" \
  "$(stdout_and_status wf_project_root "$FOLDER_REPO/.workflow/.worktrees/plain")" "0|$FOLDER_REPO"
eq "wf_project_root from a repository whose path only looks like an agent worktree prints that repository" \
  "$(stdout_and_status wf_project_root "$WORK/lookalike/.workflow/.worktrees/solo")" "0|$WORK/lookalike/.workflow/.worktrees/solo"
eq "wf_project_root outside a git repository returns 1 and names the folder" \
  "$(refusal wf_project_root "$FOLDER_REPO-elsewhere")" "1|not inside a git repository: $FOLDER_REPO-elsewhere"

echo "== wf_norm_folder"
for kind in spec initiative; do
  case $kind in
    spec) folder=$FOLDER_SPEC other=$FOLDER_INITIATIVE ;;
    initiative) folder=$FOLDER_INITIATIVE other=$FOLDER_SPEC ;;
  esac
  while IFS='|' read -r form _ arg; do
    case $form in
      outside-repo | from-worktree) ;;
      bare | absolute-elsewhere)
        result=$(refusal wf_norm_folder "$kind" "$arg")
        check "JRN-006 wf_norm_folder $kind refuses the $form form with status 1 and a reason naming it" \
          '[[ "${result%%|*}" == 1 && "${result#*|}" == *"$arg"* ]]' "$result"
        eq "JRN-006 wf_norm_folder $kind prints no folder for the $form form" "$(stdout_and_status wf_norm_folder "$kind" "$arg")" "1|"
        ;;
      *)
        eq "JRN-006 wf_norm_folder $kind maps the $form form to $folder" \
          "$(stdout_and_status wf_norm_folder "$kind" "$arg")" "0|$folder"
        ;;
    esac
  done < <(folder_inputs "$kind")
  result=$(refusal wf_norm_folder "$kind" "$other")
  check "JRN-006 wf_norm_folder $kind refuses a folder of the other kind" \
    '[[ "${result%%|*}" == 1 && "${result#*|}" == *"$other"* ]]' "$result"
done
for arg in .workflow/specs/x01-short .workflow/specs/work-backlog .workflow/specs/001-alpha/tasks .workflow/specs/001-; do
  eq "JRN-006 wf_norm_folder spec refuses $arg" "$(stdout_and_status wf_norm_folder spec "$arg")" "1|"
done
for arg in .workflow/specs/01-short .workflow/specs/00010-five; do
  eq "JRN-006 wf_norm_folder spec accepts any digit count: $arg" "$(stdout_and_status wf_norm_folder spec "$arg")" "0|$arg"
done
eq "JRN-006 wf_norm_folder accepts a slug with dots, dashes and underscores" \
  "$(stdout_and_status wf_norm_folder spec .workflow/specs/1234-a.b_c-d)" "0|.workflow/specs/1234-a.b_c-d"
check "JRN-006 wf_norm_folder refuses an unknown folder kind" '[[ "$(stdout_and_status wf_norm_folder backlog "$FOLDER_SPEC")" != 0\|* ]]'

echo "== the Done folder: WF_SPECS_DONE and wf_norm_folder (JRN-004, spec 007)"
eq "JRN-004 WF_SPECS_DONE is .workflow/specs/done" \
  "$(bash -c 'set -euo pipefail; . "$1"; printf "%s" "$WF_SPECS_DONE"' _ "$LIB" 2>&1)" .workflow/specs/done
eq "JRN-004 WF_SPECS_DONE is the done folder of WF_SPECS" \
  "$(bash -c 'set -euo pipefail; . "$1"; [ "$WF_SPECS_DONE" = "$WF_SPECS/done" ] && echo same' _ "$LIB" 2>&1)" same
DONE_FOLDER=.workflow/specs/done/001-alpha
while IFS='|' read -r form cwd arg; do
  eq "JRN-004 wf_norm_folder spec maps the $form form of a Done folder spec to $DONE_FOLDER" \
    "$(cd "$cwd" && stdout_and_status wf_norm_folder spec "$arg")" "0|$DONE_FOLDER"
done <<EOF
relative|$FOLDER_REPO|$DONE_FOLDER
dot-relative|$FOLDER_REPO|./$DONE_FOLDER/
absolute-main|$FOLDER_REPO|$FOLDER_REPO/$DONE_FOLDER
absolute-worktree|$FOLDER_REPO|$FOLDER_WT/$DONE_FOLDER
EOF
for arg in .workflow/specs/done/00010-five .workflow/specs/done/1-one .workflow/specs/done/1234-a.b_c-D; do
  eq "JRN-004 wf_norm_folder spec accepts a Done folder spec of any digit count and slug: $arg" \
    "$(stdout_and_status wf_norm_folder spec "$arg")" "0|$arg"
done
for arg in .workflow/specs/done .workflow/specs/done/ .workflow/specs/done/work-backlog .workflow/specs/done/done \
  .workflow/specs/done/done/001-alpha .workflow/specs/done/001-alpha/tasks .workflow/specs/done/x01-short \
  .workflow/specs/work-backlog/001-alpha; do
  result=$(refusal wf_norm_folder spec "$arg")
  check "JRN-004 wf_norm_folder spec refuses $arg with status 1 and a reason naming it" \
    '[[ "${result%%|*}" == 1 && "${result#*|}" == *"$arg"* ]]' "$result"
done
ELSEWHERE=$FOLDER_REPO-elsewhere/done/001-alpha
result=$(refusal wf_norm_folder spec "$ELSEWHERE")
check "JRN-004 wf_norm_folder spec refuses an absolute done/ path outside the specs folder with status 1 and a reason naming it" \
  '[[ "${result%%|*}" == 1 && "${result#*|}" == *"$ELSEWHERE"* ]]' "$result"
eq "JRN-004 wf_norm_folder initiative refuses a done/ child (initiatives are not moved)" \
  "$(stdout_and_status wf_norm_folder initiative .workflow/initiatives/done/001-ini)" "1|"

echo "== wf_enc and wf_agent_worktree_name (JRN-001)"
# The two hooks' codex_enc copy, run on these inputs before the shared encoder replaced it: "<input>|<output>".
RECORDED_CODEX_ENC="shell-scripts|shell_scripts
test-harness|test_harness
Web.UI|web_ui
fact-lookup|fact_lookup
e2e-browser|e2e_browser
profile-mini-review|profile_mini_review"
# A UTF-8 locale changes how tr counts a multi-byte character, so the encoder must give the same bytes under one.
UTF8_LOCALE=$(locale -a 2>/dev/null | grep -Ei '^(en_US|C)\.utf-?8$' | head -n 1)
[ -n "$UTF8_LOCALE" ] || UTF8_LOCALE=$(locale -a 2>/dev/null | grep -Ei '\.utf-?8$' | head -n 1)
# in_locale LOCALE FUNCTION ARGS... : stdout_and_status with LC_ALL set to LOCALE.
in_locale() {
  local loc=$1
  shift
  LC_ALL=$loc stdout_and_status "$@"
}

for loc in C "$UTF8_LOCALE"; do
  if [ -z "$loc" ]; then
    skip "JRN-001 encoder under a UTF-8 locale" "no UTF-8 locale installed"
    continue
  fi
  while IFS='|' read -r input recorded; do
    eq "JRN-001 wf_enc '$input' under $loc matches the recorded codex_enc output" "$(in_locale "$loc" wf_enc "$input")" "0|$recorded"
    eq "JRN-001 wf_agent_worktree_name phase_1 '$input' under $loc is the Codex task_name" \
      "$(in_locale "$loc" wf_agent_worktree_name .workflow/specs/007-demo phase_1 "$input")" "0|s007_phase_1_$recorded"
    eq "JRN-001 wf_agent_worktree_name integration '$input' under $loc is the Codex task_name" \
      "$(in_locale "$loc" wf_agent_worktree_name .workflow/specs/007-demo integration "$input")" "0|s007_integration_$recorded"
  done <<<"$RECORDED_CODEX_ENC"
  eq "JRN-001 wf_enc turns each byte of a multi-byte character into _ under $loc" "$(in_locale "$loc" wf_enc 'Wéb')" "0|w__b"
done
eq "JRN-001 wf_enc prints no trailing newline" "$(lib_call wf_enc shell-scripts 2>/dev/null | wc -c | tr -d ' ')" 13
eq "JRN-001 wf_agent_worktree_name task T3 is s007_t3" "$(stdout_and_status wf_agent_worktree_name .workflow/specs/007-demo task T3)" "0|s007_t3"
eq "JRN-001 wf_agent_worktree_name task T12 is s007_t12" "$(stdout_and_status wf_agent_worktree_name .workflow/specs/007-demo task T12)" "0|s007_t12"
eq "JRN-001 wf_agent_worktree_name keeps a four-digit spec number" \
  "$(stdout_and_status wf_agent_worktree_name .workflow/specs/1234-wide task T1)" "0|s1234_t1"
eq "JRN-001 wf_agent_worktree_name keeps a five-digit spec number" \
  "$(stdout_and_status wf_agent_worktree_name .workflow/specs/00010-five task T1)" "0|s00010_t1"
eq "JRN-001 wf_agent_worktree_name accepts a two-digit spec number" \
  "$(stdout_and_status wf_agent_worktree_name .workflow/specs/12-foo task T1)" "0|s12_t1"
for bad in .workflow/specs/demo .workflow/specs/x07-demo .workflow/specs/007demo ""; do
  result=$(refusal wf_agent_worktree_name "$bad" task T3)
  check "JRN-001 wf_agent_worktree_name refuses the malformed spec folder '$bad' with status 1 and a reason" \
    '[[ "${result%%|*}" == 1 && -n "${result#*|}" ]]' "$result"
  eq "JRN-001 wf_agent_worktree_name prints no name for the malformed spec folder '$bad'" \
    "$(stdout_and_status wf_agent_worktree_name "$bad" task T3)" "1|"
done
eq "JRN-001 wf_agent_worktree_name refuses an unknown kind with status 1 and no name" \
  "$(stdout_and_status wf_agent_worktree_name .workflow/specs/007-demo review T3)" "1|"
for spec_form in ./.workflow/specs/007-demo .workflow/specs/007-demo/ "$FOLDER_REPO/.workflow/specs/007-demo" 007-demo; do
  eq "JRN-001 wf_agent_worktree_name reads the spec number from the spec dir form '$spec_form'" \
    "$(stdout_and_status wf_agent_worktree_name "$spec_form" task T3)" "0|s007_t3"
done
for bad_task in T t3 3 T3a T-1 ""; do
  eq "JRN-001 wf_agent_worktree_name refuses the task id '$bad_task' with status 1 and no name" \
    "$(stdout_and_status wf_agent_worktree_name .workflow/specs/007-demo task "$bad_task")" "1|"
done
result=$(refusal wf_agent_worktree_name .workflow/specs/007-demo task T3a)
check "JRN-001 wf_agent_worktree_name names the bad task id in its reason" '[[ "${result#*|}" == *T3a* ]]' "$result"
result=$(refusal wf_agent_worktree_name .workflow/specs/x07-demo task T3)
check "JRN-001 wf_agent_worktree_name names the bad spec dir in its reason" '[[ "${result#*|}" == *x07-demo* ]]' "$result"
result=$(refusal wf_agent_worktree_name .workflow/specs/007-demo review T3)
check "JRN-001 wf_agent_worktree_name names the unknown kind in its reason" '[[ "${result#*|}" == *review* ]]' "$result"
eq "JRN-001 wf_agent_worktree_name refuses an empty work type with status 1 and no name" \
  "$(stdout_and_status wf_agent_worktree_name .workflow/specs/007-demo phase_1 "")" "1|"
eq "JRN-001 wf_agent_worktree_name prints no trailing newline" \
  "$(lib_call wf_agent_worktree_name .workflow/specs/007-demo task T3 2>/dev/null | wc -c | tr -d ' ')" 7
eq "JRN-001 wf_enc with no argument returns 1 under set -u instead of exiting the caller" \
  "$(bash -c 'set -euo pipefail; . "$1"; wf_enc || echo "status $?"' _ "$LIB" 2>/dev/null)" "status 1"
eq "JRN-001 wf_agent_worktree_name leaves BASH_REMATCH as the caller set it" \
  "$(bash -c 'set -euo pipefail; . "$1"; [[ keep =~ (k)eep ]]; wf_agent_worktree_name .workflow/specs/007-demo task T3 >/dev/null; printf %s "${BASH_REMATCH[1]}"' _ "$LIB")" "k"
check "JRN-001 neither hook keeps its own codex_enc copy" \
  '! grep -q "codex_enc()" "$WORK/scaffold/.agents/hooks/codex-pre-spawn.sh" "$WORK/scaffold/.agents/hooks/post-implementation-audit.sh"' \
  "$(grep -n "codex_enc()" "$WORK/scaffold/.agents/hooks/codex-pre-spawn.sh" "$WORK/scaffold/.agents/hooks/post-implementation-audit.sh")"

echo "== JRN-012 (spec 00014): the old_ prefix in the Done folder"
OLD_DONE=.workflow/specs/done/old_012-alpha
while IFS='|' read -r form arg; do
  eq "JRN-012 (spec 00014) wf_norm_folder spec maps the $form form of an old_ Done folder spec to its folder" \
    "$(stdout_and_status wf_norm_folder spec "$arg")" "0|${arg#"$FOLDER_REPO/"}"
done <<EOF
relative|$OLD_DONE
absolute-main|$FOLDER_REPO/$OLD_DONE
five-digit|.workflow/specs/done/old_00010-wide
EOF
for arg in .workflow/specs/old_012-alpha .workflow/specs/done/old_ .workflow/specs/done/old_x01-short \
  .workflow/specs/done/old-012-alpha .workflow/specs/done/OLD_012-alpha .workflow/specs/done/old_old_012-alpha \
  .workflow/specs/done/old_012-; do
  check "JRN-012 (spec 00014) wf_norm_folder spec refuses $arg while it accepts $OLD_DONE" \
    '[[ $(stdout_and_status wf_norm_folder spec "$OLD_DONE") == "0|$OLD_DONE" && $(stdout_and_status wf_norm_folder spec "$arg") == "1|" ]]' \
    "$(refusal wf_norm_folder spec "$OLD_DONE"); $(refusal wf_norm_folder spec "$arg")"
done

shellcheck_files "shellcheck: lib/workflow-paths.sh" "$LIB"
finish
