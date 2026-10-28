#!/usr/bin/env bash
# Suite: .agents/lib/workflow-paths.sh, the shared folder helpers wf_main_root and wf_norm_folder (JRN-006).
# Covers: wf_main_root from the main checkout, a sub-folder, a worktree and a folder outside git; wf_norm_folder for each
#   spec and initiative input form (relative, dot-relative with a trailing slash, absolute under the main checkout or a
#   worktree, bare NNN-slug, absolute path elsewhere), a folder of the other kind, slugs the folder rule refuses, and an
#   unknown kind; each refusal returns 1 with a reason naming the argument and prints no folder. The helpers run sourced
#   under `set -euo pipefail` from a copy of .agents/, the way the scripts use them.
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

shellcheck_files "shellcheck: lib/workflow-paths.sh" "$LIB"
finish
