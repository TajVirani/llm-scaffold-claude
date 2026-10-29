#!/usr/bin/env bash
# Suite: .agents/lib/workflow-paths.sh, the shared folder helpers wf_main_root and wf_norm_folder (JRN-006).
# Covers: wf_main_root from the main checkout, a sub-folder, a worktree and a folder outside git; wf_norm_folder for each
#   spec and initiative input form (relative, dot-relative with a trailing slash, absolute under the main checkout or a
#   worktree, bare NNN-slug, absolute path elsewhere), a folder of the other kind, slugs the folder rule refuses, and an
#   unknown kind; each refusal returns 1 with a reason naming the argument and prints no folder. The helpers run sourced
#   under `set -euo pipefail` from a copy of .agents/, the way the scripts use them.
#   JRN-001: wf_enc and wf_agent_worktree_name give the bytes the hooks' old codex_enc gave (recorded below) for work types and
#   agent types, under LC_ALL=C and a UTF-8 locale; task, phase_1 and integration names; malformed spec folders and an unknown
#   kind return 1 and print no name; neither hook keeps a codex_enc copy.
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
for arg in .workflow/specs/01-short .workflow/specs/work-backlog .workflow/specs/001-alpha/tasks .workflow/specs/001-; do
  eq "JRN-006 wf_norm_folder spec refuses $arg" "$(stdout_and_status wf_norm_folder spec "$arg")" "1|"
done
eq "JRN-006 wf_norm_folder accepts a slug with dots, dashes and underscores" \
  "$(stdout_and_status wf_norm_folder spec .workflow/specs/1234-a.b_c-d)" "0|.workflow/specs/1234-a.b_c-d"
check "JRN-006 wf_norm_folder refuses an unknown folder kind" '[[ "$(stdout_and_status wf_norm_folder backlog "$FOLDER_SPEC")" != 0\|* ]]'

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
for bad in .workflow/specs/demo .workflow/specs/x07-demo .workflow/specs/007demo ""; do
  result=$(refusal wf_agent_worktree_name "$bad" task T3)
  check "JRN-001 wf_agent_worktree_name refuses the malformed spec folder '$bad' with status 1 and a reason" \
    '[[ "${result%%|*}" == 1 && -n "${result#*|}" ]]' "$result"
  eq "JRN-001 wf_agent_worktree_name prints no name for the malformed spec folder '$bad'" \
    "$(stdout_and_status wf_agent_worktree_name "$bad" task T3)" "1|"
done
eq "JRN-001 wf_agent_worktree_name refuses an unknown kind with status 1 and no name" \
  "$(stdout_and_status wf_agent_worktree_name .workflow/specs/007-demo review T3)" "1|"
check "JRN-001 neither hook keeps its own codex_enc copy" \
  '! grep -q "codex_enc()" "$WORK/scaffold/.agents/hooks/codex-pre-spawn.sh" "$WORK/scaffold/.agents/hooks/post-implementation-audit.sh"' \
  "$(grep -n "codex_enc()" "$WORK/scaffold/.agents/hooks/codex-pre-spawn.sh" "$WORK/scaffold/.agents/hooks/post-implementation-audit.sh")"

shellcheck_files "shellcheck: lib/workflow-paths.sh" "$LIB"
finish
