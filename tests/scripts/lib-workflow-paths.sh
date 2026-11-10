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
#   WF_ISSUE_TRACKING is .workflow/issue-tracking.yaml. wf_origin_host prints github or gitlab for an origin on that host
#   (ssh, https, self-hosted, from a sub-folder) and nothing, with status 0, for another host, a local path, no origin, an
#   empty or missing argument and a folder outside git. The path rewrite on a fixture project: a rename to a new number, an
#   old_ rename in the Done folder and a move into it, with their backlog lists, in one run: every specs/, ../,
#   work-backlog/NAME.md and NAME.md#B<n> reference rewritten, look-alike names, initiatives and docs/ left
#   alone, links leaving the moved spec one level deeper, the commit holding exactly the moved and rewritten paths (plus
#   a given extra path) with the given message while a change staged earlier stays staged; a rollback before the commit
#   and after a failing commit restores tree, index, HEAD, step marker and created folders; a rollback that cannot
#   restore a file names it in WF_REWRITE_LEFT and keeps its copy; the checkout refusal for the main branch, a detached
#   HEAD, a merge in progress and outside git; a commit on main refused; refused spec paths, moves, a second run and calls
#   before wf_rewrite_begin.
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

echo "== the issue tracker settings file"
eq "WF_ISSUE_TRACKING is .workflow/issue-tracking.yaml, built from WF_DIR" \
  "$(bash -c 'set -euo pipefail; . "$1"; [ "$WF_ISSUE_TRACKING" = "$WF_DIR/issue-tracking.yaml" ] && printf %s "$WF_ISSUE_TRACKING"' _ "$LIB" 2>&1)" \
  .workflow/issue-tracking.yaml

echo "== wf_origin_host"
HOST_REPO=$WORK/host-repo
git_init_repo "$HOST_REPO"
while IFS='|' read -r label url host; do
  git -C "$HOST_REPO" remote remove origin 2>/dev/null
  git -C "$HOST_REPO" remote add origin "$url"
  eq "wf_origin_host prints '$host' for an origin on $label" "$(stdout_and_status wf_origin_host "$HOST_REPO")" "0|$host"
done <<EOF
GitHub over ssh|git@github.com:acme/app.git|github
GitHub over https|https://github.com/acme/app.git|github
GitLab over ssh|git@gitlab.com:acme/app.git|gitlab
a self-hosted GitLab|https://gitlab.acme.test/team/app.git|gitlab
another host|https://bitbucket.org/acme/app.git|
a local path|$WORK/elsewhere.git|
EOF
mkdir -p "$HOST_REPO/sub"
git -C "$HOST_REPO" remote set-url origin git@github.com:acme/app.git
eq "wf_origin_host from a sub-folder reads the checkout's origin remote" \
  "$(stdout_and_status wf_origin_host "$HOST_REPO/sub")" "0|github"
eq "wf_origin_host prints nothing and returns 0 for an empty folder argument, even run inside a checkout with an origin" \
  "$(cd "$HOST_REPO" && refusal wf_origin_host "")" "0|"
git -C "$HOST_REPO" remote remove origin
eq "wf_origin_host prints nothing and returns 0 with no origin remote" "$(refusal wf_origin_host "$HOST_REPO")" "0|"
eq "wf_origin_host prints nothing and returns 0 outside a git repository" "$(refusal wf_origin_host "$WORK/not-a-repo")" "0|"
eq "wf_origin_host prints nothing and returns 0 with no argument under set -u" "$(refusal wf_origin_host)" "0|"

echo "== the path rewrite: wf_rewrite_*"
# rewrite_manifest : the rewrite fixture project, one `=== <path>` line before each file's content.
rewrite_manifest() {
  cat <<'EOF'
=== .gitignore
.workflow/specs/*/.step
=== .workflow/specs/015-delta/spec.md
Glossary: [GLOSSARY.md](../../GLOSSARY.md) · Backlog: [015-delta.md](../work-backlog/015-delta.md)
- Folder: .workflow/specs/015-delta
=== .workflow/specs/015-delta/.step
0.1.6
=== .workflow/specs/work-backlog/015-delta.md
- [open] B1 decision (0.1.4): Pick the format. Evidence: .workflow/specs/015-delta/spec.md
=== .workflow/deferred/delta-shelf.md
origin: 015-delta.md#B1
Shelved from [015-delta](../specs/015-delta/spec.md).
Not specs/015-delta-two, specs/015-delta.md, 015-delta.mdx or old_015-delta.md#B1.
=== .workflow/specs/013-beta/notes.md
See [delta](../015-delta/spec.md), [gamma](../014-gamma/spec.md) and specs/015-delta.
=== .workflow/specs/014-gamma/spec.md
Glossary: [GLOSSARY.md](../../GLOSSARY.md) · Tasks: [tasks.md](tasks.md) · Beta: [notes](../013-beta/notes.md)
Self: [spec](../014-gamma/spec.md) and specs/014-gamma.
=== .workflow/specs/014-gamma/tasks/T1.md
Up: [spec](../spec.md) · Glossary: [GLOSSARY.md](../../../GLOSSARY.md)
=== .workflow/specs/done/012-alpha/spec.md
Backlog: [012-alpha.md](../../work-backlog/012-alpha.md) · Self: .workflow/specs/done/012-alpha
=== .workflow/specs/work-backlog/012-alpha.md
- [promoted] B1 requirement (5.9): Delta follow-up. Evidence: .workflow/specs/done/012-alpha/design.md
=== .workflow/capabilities.md
| CAP-001 | [012-alpha](specs/done/012-alpha/spec.md) | origin: 012-alpha.md#B1 |
| CAP-002 | [014-gamma](specs/014-gamma/spec.md) |
=== .workflow/initiatives/001-ini/initiative.md
specs/015-delta specs/done/012-alpha specs/014-gamma
=== docs/notes.md
.workflow/specs/015-delta .workflow/specs/done/012-alpha
=== README.md
readme
EOF
}

# write_manifest DIR : write each file of the manifest on stdin under DIR.
write_manifest() {
  awk -v dest="$1" '
    /^=== / { file = dest "/" substr($0, 5); dir = file; sub(/\/[^\/]*$/, "", dir); system("mkdir -p \"" dir "\""); next }
    { print >> file; close(file) }
  '
}

# rewrite_fixture DIR : the rewrite fixture as a git repository on branch spec/007-demo, everything but .step committed.
rewrite_fixture() {
  git_init_repo "$1"
  rewrite_manifest | write_manifest "$1"
  git_commit_all "$1" "fixture: rewrite project"
  git -C "$1" switch -q -c spec/007-demo
}

# tree_state DIR : every file under DIR outside .git with its checksum, then the index, HEAD and the staged changes.
tree_state() {
  (cd "$1" && find . -path ./.git -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r f; do
    printf '%s %s\n' "$f" "$(cksum <"$f")"
  done && git ls-files -s && git rev-parse HEAD && git diff --cached --name-status)
}

# rewrite_run DIR PROGRAM : run the bash PROGRAM in DIR with workflow-paths.sh sourced under strict options; sets OUT
#   (stdout and stderr) and RC.
rewrite_run() {
  OUT=$(cd "$1" && bash -c 'set -euo pipefail; . "$1"; eval "$2"' _ "$LIB" "$2" 2>&1)
  RC=$?
}

ADOPT_STEPS='
  wf_rewrite_begin "$PWD"
  refusal=$(wf_rewrite_checkout_refusal "$PWD" main)
  [[ -z $refusal ]]
  wf_rewrite_move .workflow/specs/015-delta .workflow/specs/1234-delta
  wf_rewrite_spec_path .workflow/specs/015-delta .workflow/specs/1234-delta
  wf_rewrite_move .workflow/specs/work-backlog/015-delta.md .workflow/specs/work-backlog/1234-delta.md
  wf_rewrite_move .workflow/specs/done/012-alpha .workflow/specs/done/old_012-alpha
  wf_rewrite_spec_path .workflow/specs/done/012-alpha .workflow/specs/done/old_012-alpha
  wf_rewrite_move .workflow/specs/work-backlog/012-alpha.md .workflow/specs/work-backlog/old_012-alpha.md
  wf_rewrite_move .workflow/specs/014-gamma .workflow/specs/done/014-gamma
  wf_rewrite_spec_path .workflow/specs/014-gamma .workflow/specs/done/014-gamma
'

P=$WORK/rewrite-commit
rewrite_fixture "$P"
printf 'staged elsewhere\n' >>"$P/README.md"
git -C "$P" add README.md
printf 'left unstaged\n' >"$P/docs/draft.md"
TIP=$(git -C "$P" rev-parse HEAD)
rewrite_run "$P" "$ADOPT_STEPS"'
  wf_rewrite_commit main "chore(workflow): rename specs" "Renamed: 015-delta 012-alpha 014-gamma"
  wf_rewrite_pending && echo "still pending" || echo "committed"
  wf_rewrite_end'
eq "a rename to a new number, an old_ rename in the Done folder and a move into it commit in one run" "$RC|$OUT" "0|committed"
eq "the active spec's own files point at its new name and its renamed backlog list" "$(cat "$P/.workflow/specs/1234-delta/spec.md")" \
  "Glossary: [GLOSSARY.md](../../GLOSSARY.md) · Backlog: [015-delta.md](../work-backlog/1234-delta.md)
- Folder: .workflow/specs/1234-delta"
eq "the renamed backlog list names the new spec path" "$(cat "$P/.workflow/specs/work-backlog/1234-delta.md")" \
  "- [open] B1 decision (0.1.4): Pick the format. Evidence: .workflow/specs/1234-delta/spec.md"
eq "an item reference and a climbing link are rewritten, and look-alike names are left alone" \
  "$(cat "$P/.workflow/deferred/delta-shelf.md")" "origin: 1234-delta.md#B1
Shelved from [015-delta](../specs/1234-delta/spec.md).
Not specs/015-delta-two, specs/015-delta.md, 015-delta.mdx or old_015-delta.md#B1."
eq "a sibling spec's ../ links and specs/ paths follow both the rename and the move into the Done folder" \
  "$(cat "$P/.workflow/specs/013-beta/notes.md")" \
  "See [delta](../1234-delta/spec.md), [gamma](../done/014-gamma/spec.md) and specs/1234-delta."
eq "the spec moved a folder deeper gets one more ../ on each link that leaves it, and its own path is rewritten" \
  "$(cat "$P/.workflow/specs/done/014-gamma/spec.md")" \
  "Glossary: [GLOSSARY.md](../../../GLOSSARY.md) · Tasks: [tasks.md](tasks.md) · Beta: [notes](../../013-beta/notes.md)
Self: [spec](../../done/014-gamma/spec.md) and specs/done/014-gamma."
eq "a link inside a subfolder of the moved spec that stays inside it is unchanged, one that leaves it climbs one more" \
  "$(cat "$P/.workflow/specs/done/014-gamma/tasks/T1.md")" "Up: [spec](../spec.md) · Glossary: [GLOSSARY.md](../../../../GLOSSARY.md)"
eq "the old_ Done spec points at its old_ backlog list and its own new path" \
  "$(cat "$P/.workflow/specs/done/old_012-alpha/spec.md")" \
  "Backlog: [012-alpha.md](../../work-backlog/old_012-alpha.md) · Self: .workflow/specs/done/old_012-alpha"
eq "the old_ backlog list names the old_ spec path" "$(cat "$P/.workflow/specs/work-backlog/old_012-alpha.md")" \
  "- [promoted] B1 requirement (5.9): Delta follow-up. Evidence: .workflow/specs/done/old_012-alpha/design.md"
eq "a file outside the specs folder gets every form rewritten" "$(cat "$P/.workflow/capabilities.md")" \
  "| CAP-001 | [012-alpha](specs/done/old_012-alpha/spec.md) | origin: old_012-alpha.md#B1 |
| CAP-002 | [014-gamma](specs/done/014-gamma/spec.md) |"
check "the initiative record and docs/ are left as they were" \
  '[[ -z $(git -C "$P" diff --name-only "$TIP" HEAD -- .workflow/initiatives docs) ]]'
eq "the commit holds exactly the moved and rewritten paths" \
  "$(git -C "$P" diff --name-status --no-renames "$TIP" HEAD | LC_ALL=C sort)" "$(printf '%s\n' \
    "A	.workflow/specs/1234-delta/spec.md" "A	.workflow/specs/done/014-gamma/spec.md" \
    "A	.workflow/specs/done/014-gamma/tasks/T1.md" "A	.workflow/specs/done/old_012-alpha/spec.md" \
    "A	.workflow/specs/work-backlog/1234-delta.md" "A	.workflow/specs/work-backlog/old_012-alpha.md" \
    "D	.workflow/specs/014-gamma/spec.md" "D	.workflow/specs/014-gamma/tasks/T1.md" \
    "D	.workflow/specs/015-delta/spec.md" "D	.workflow/specs/done/012-alpha/spec.md" \
    "D	.workflow/specs/work-backlog/012-alpha.md" "D	.workflow/specs/work-backlog/015-delta.md" \
    "M	.workflow/capabilities.md" "M	.workflow/deferred/delta-shelf.md" "M	.workflow/specs/013-beta/notes.md" | LC_ALL=C sort)"
eq "the commit is one commit on the checked-out branch with the given subject and body" \
  "$(git -C "$P" rev-parse HEAD~1)|$(git -C "$P" branch --show-current)|$(git -C "$P" log -1 --format=%B)" \
  "$TIP|spec/007-demo|chore(workflow): rename specs

Renamed: 015-delta 012-alpha 014-gamma"
eq "a change staged before the run stays staged and out of the commit, and an untracked file elsewhere stays untracked" \
  "$(git -C "$P" status --porcelain)" "M  README.md
?? docs/draft.md"
check "the step marker moves with the renamed spec folder and stays untracked" \
  '[[ $(cat "$P/.workflow/specs/1234-delta/.step") == 0.1.6 && -z $(git -C "$P" ls-files .workflow/specs/1234-delta/.step) ]]'

P=$WORK/rewrite-extra-path
rewrite_fixture "$P"
TIP=$(git -C "$P" rev-parse HEAD)
printf 'renamed elsewhere\n' >"$P/.workflow/deferred/extra.md"
rewrite_run "$P" '
  wf_rewrite_begin "$PWD"
  wf_rewrite_move .workflow/specs/done/012-alpha .workflow/specs/done/old_012-alpha
  wf_rewrite_commit main "chore: move" "" .workflow/deferred/extra.md
  wf_rewrite_end'
eq "a commit with an empty body and an extra path commits the queued paths and that path, subject only" \
  "$RC|$(git -C "$P" diff --name-only --no-renames "$TIP" HEAD | tr '\n' ' ')|$(git -C "$P" log -1 --format=%B)" \
  "0|.workflow/deferred/extra.md .workflow/specs/done/012-alpha/spec.md .workflow/specs/done/old_012-alpha/spec.md |chore: move"

P=$WORK/rewrite-rollback
rewrite_fixture "$P"
BEFORE=$(tree_state "$P")
rewrite_run "$P" "$ADOPT_STEPS"'
  wf_rewrite_set_aside .workflow/specs/1234-delta/.step
  wf_rewrite_move .workflow/deferred/delta-shelf.md .workflow/archive/2026/delta-shelf.md
  wf_rewrite_roll_back
  wf_rewrite_pending && echo "still pending" || echo "nothing pending"
  wf_rewrite_end'
eq "a rollback before the commit returns 0 and leaves nothing pending" "$RC|$OUT" "0|nothing pending"
check "the rollback puts every moved folder, rewritten file, set-aside step marker back and removes the folders it created" \
  '[[ $(tree_state "$P") == "$BEFORE" && ! -e "$P/.workflow/specs/done/014-gamma" && ! -e "$P/.workflow/archive" ]]' "$(diff <(echo "$BEFORE") <(tree_state "$P"))"

P=$WORK/rewrite-commit-fails
rewrite_fixture "$P"
printf '#!/bin/sh\nexit 1\n' >"$P/.git/hooks/pre-commit"
chmod +x "$P/.git/hooks/pre-commit"
BEFORE=$(tree_state "$P")
rewrite_run "$P" "$ADOPT_STEPS"'
  status=0
  wf_rewrite_commit main "chore: rename" "" || status=$?
  echo "commit status $status"
  wf_rewrite_pending && wf_rewrite_roll_back && echo "rolled back"
  wf_rewrite_end'
check "a failing commit returns 1 with its reason and leaves the run pending for the rollback" \
  '[[ $RC == 0 && $OUT == *"git commit failed"* && $OUT == *"commit status 1"* && $OUT == *"rolled back"* ]]' "$OUT"
check "the rollback after a failing commit restores the index, the tree and HEAD" \
  '[[ $(tree_state "$P") == "$BEFORE" ]]' "$(diff <(echo "$BEFORE") <(tree_state "$P"))"

P=$WORK/rewrite-stuck
rewrite_fixture "$P"
rewrite_run "$P" '
  wf_rewrite_begin "$PWD"
  wf_rewrite_move .workflow/specs/014-gamma .workflow/specs/done/014-gamma
  wf_rewrite_spec_path .workflow/specs/014-gamma .workflow/specs/done/014-gamma
  chmod 444 .workflow/specs/013-beta/notes.md
  status=0
  wf_rewrite_roll_back || status=$?
  chmod 644 .workflow/specs/013-beta/notes.md
  printf "status %s\n" "$status"
  printf "left: %s\n" "${WF_REWRITE_LEFT[@]}"
  copy=${WF_REWRITE_LEFT[0]##* copy }
  [[ -f ${copy% over it} ]] && echo "copy kept"
  wf_rewrite_end'
check "a rollback that cannot restore a file returns 1, names it and how to restore it, and keeps the copy" \
  '[[ $OUT == *"status 1"* && $OUT == *"left: $P/.workflow/specs/013-beta/notes.md is rewritten: copy "*" over it"* && $OUT == *"copy kept"* ]]' "$OUT"
check "the rollback that could not restore a file still puts the moved folder back" \
  '[[ -d "$P/.workflow/specs/014-gamma" && ! -e "$P/.workflow/specs/done/014-gamma" ]]' "$OUT"

echo "== the path rewrite refuses"
P=$WORK/rewrite-refusals
rewrite_fixture "$P"
eq "wf_rewrite_checkout_refusal prints nothing on a spec branch" "$(cd "$P" && stdout_and_status wf_rewrite_checkout_refusal "$P" main)" "0|"
git -C "$P" switch -q main
check "wf_rewrite_checkout_refusal names the main branch" \
  '[[ $(cd "$P" && stdout_and_status wf_rewrite_checkout_refusal "$P" main) == "0|"*"main branch main"* ]]'
git -C "$P" switch -q --detach
check "wf_rewrite_checkout_refusal names a detached HEAD" \
  '[[ $(cd "$P" && stdout_and_status wf_rewrite_checkout_refusal "$P" main) == "0|"*"detached HEAD"* ]]'
git -C "$P" switch -q spec/007-demo
git -C "$P" rev-parse HEAD >"$P/.git/MERGE_HEAD"
check "wf_rewrite_checkout_refusal names a merge in progress" \
  '[[ $(cd "$P" && stdout_and_status wf_rewrite_checkout_refusal "$P" main) == "0|"*"merge, cherry-pick or revert is in progress"* ]]'
rm "$P/.git/MERGE_HEAD"
result=$(refusal wf_rewrite_checkout_refusal "$WORK/not-a-repo" main)
check "wf_rewrite_checkout_refusal returns 1 with a reason outside a git repository" \
  '[[ ${result%%|*} == 1 && $result == *"cannot read the checked-out branch in $WORK/not-a-repo"* ]]' "$result"

git -C "$P" switch -q main
BEFORE=$(tree_state "$P")
rewrite_run "$P" '
  wf_rewrite_begin "$PWD"
  wf_rewrite_move .workflow/specs/014-gamma .workflow/specs/done/014-gamma
  wf_rewrite_spec_path .workflow/specs/014-gamma .workflow/specs/done/014-gamma
  status=0
  wf_rewrite_commit main "chore: move" "" || status=$?
  echo "commit status $status"
  wf_rewrite_roll_back
  wf_rewrite_end'
check "wf_rewrite_commit on the main branch returns 1 naming it, commits nothing, and the rollback restores the tree" \
  '[[ $OUT == *"main branch main"* && $OUT == *"commit status 1"* && $(tree_state "$P") == "$BEFORE" ]]' "$OUT"
git -C "$P" switch -q spec/007-demo

while IFS='|' read -r label program reason; do
  rewrite_run "$P" "wf_rewrite_begin \"\$PWD\"; $program"
  check "the path rewrite refuses $label with status 1 and a reason" '[[ $RC == 1 && $OUT == *"$reason"* ]]' \
    "want status 1 and a reason holding '$reason'; rc=$RC: $OUT"
done <<'EOF'
a move up out of the Done folder|wf_rewrite_spec_path .workflow/specs/done/012-alpha .workflow/specs/012-alpha|not supported
a folder that is not a spec|wf_rewrite_spec_path .workflow/deferred/x .workflow/specs/x|not a spec folder
a nested spec folder|wf_rewrite_spec_path .workflow/specs/a/b .workflow/specs/c|not a spec folder
the backlog folder|wf_rewrite_spec_path .workflow/specs/work-backlog .workflow/specs/x|not a spec folder
a rewrite to the same folder|wf_rewrite_spec_path .workflow/specs/013-beta .workflow/specs/013-beta|to itself
a move onto an existing path|wf_rewrite_move .workflow/specs/013-beta .workflow/specs/014-gamma|already exists
a move of a missing path|wf_rewrite_move .workflow/specs/099-none .workflow/specs/done/099-none|does not exist
a second run while the first is uncommitted|wf_rewrite_move .workflow/specs/013-beta .workflow/specs/013-b; wf_rewrite_begin "$PWD"|not committed yet
EOF
# The refused second run leaves its first move in place; put it back so the later checks start from the fixture.
mv "$P/.workflow/specs/013-b" "$P/.workflow/specs/013-beta"
for fn in wf_rewrite_move wf_rewrite_spec_path wf_rewrite_set_aside "wf_rewrite_commit main"; do
  rewrite_run "$P" "$fn .workflow/specs/013-beta .workflow/specs/done/013-beta"
  check "$fn before wf_rewrite_begin returns 1 and asks for it" '[[ $RC == 1 && $OUT == *"call wf_rewrite_begin first"* ]]' "rc=$RC: $OUT"
done
check "the refusals left the fixture unchanged" '[[ -z $(git -C "$P" status --porcelain) ]]' "$(git -C "$P" status --porcelain)"

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
