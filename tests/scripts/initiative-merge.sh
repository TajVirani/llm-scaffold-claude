#!/usr/bin/env bash
# Suite: a planned initiative reaching main and its later done flip; JRN-005 "Planned initiative merges and later flips done".
# Covers: initiative-transition.sh status planned with every slice emitted; the merge step per rules-setting.sh task_review
#   (local: --no-ff merge on main, branch deleted, nothing pushed; pr: the generic mode of open-task-pr.sh printing the gh or glab
#   command with head initiative/NNN-slug and base main, and --record writing merge_pr); the resume check reading each emitted
#   spec from main; the sign-off hand-off leaving an initiative still exploring untouched; the done flip on a re-created branch,
#   merged the same way; done being terminal (every subcommand exits 2); the generic mode's usage errors (exit 2), its skip
#   paths (missing head, unknown host, no remote) and its reuse of an open PR.
#   gh and glab are stubs on PATH; the origin remote is a local bare repo; no network.
# shellcheck disable=SC2016,SC2329  # check expressions are single-quoted and eval'd on purpose, and call helpers shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/initiative.sh
source "$TESTS_DIR/fixtures/initiative.sh"
preflight

new_workdir
INI=.workflow/initiatives/001-storage-overhaul
BR=initiative/001-storage-overhaul
SCRIPTS_REL=.agents/skills/feature-workflow/scripts

# every_slice_emitted DIR : fixture state written directly: every question settled, S1 and S2 emitted as 002-core-flow and 003-reports.
every_slice_emitted() {
  yq --front-matter=process -i '.questions[] |= (.state = "settled" | .launched = null | .settled = "decided in round 2")' "$1/$INI/questions.md"
  yq --front-matter=process -i '.slices[0].status = "emitted" | .slices[0].spec = "002-core-flow" | .slices[1].status = "emitted" | .slices[1].spec = "003-reports"' \
    "$1/$INI/initiative.md"
  git -C "$1" commit -q -am "initiative 001-storage-overhaul: S1 and S2 emitted"
}
commit_initiative() { git -C "$1" add "$INI" && git -C "$1" commit -q --allow-empty -m "$2"; }
merge_locally() {
  git -C "$1" switch -q main
  git -C "$1" merge -q --no-ff -m "$2" "$BR"
  git -C "$1" branch -q -d "$BR"
}
on_main() { git -C "$1" show "main:$INI/initiative.md" | yq --front-matter=extract "$2" 2>/dev/null; }

echo "== JRN-005 planned under task_review local"
P=$WORK/local
large_path_repo "$P"
set_task_review "$P" local
git -C "$P" commit -q -am "rules: task_review local"
seed_initiative "$P" 001 storage-overhaul
every_slice_emitted "$P"
IT() { initiative_transition "$P" "$@"; }
t "JRN-005 planned is accepted once every slice is emitted" 0 IT status "$INI" planned
eq "JRN-005 the initiative is planned" "$(fm "$P/$INI/initiative.md" .status)" planned
commit_initiative "$P" "initiative 001-storage-overhaul: planned"
eq "JRN-005 task_review reads local" "$(bash "$P/$SCRIPTS_REL/rules-setting.sh" task_review --cwd "$P" 2>/dev/null)" local
merge_locally "$P" "Merge initiative 001-storage-overhaul (planned)"
eq "JRN-005 local: one merge commit on main" "$(git -C "$P" log --merges --format=%s main | grep -c .)" 1
eq "JRN-005 local: the merge commit has two parents" "$(git -C "$P" rev-list --parents -n 1 main | wc -w | tr -d ' ')" 3
eq "JRN-005 local: the local initiative branch is deleted" "$(git -C "$P" branch --list "$BR")" ""
check "JRN-005 local: nothing is pushed" '! git -C "$P.origin.git" show-ref --verify --quiet "refs/heads/$BR"'
eq "JRN-005 local: main carries the planned initiative" "$(on_main "$P" .status)" planned
eq "JRN-005 local: merge_pr stays null" "$(on_main "$P" .merge_pr)" null

echo "== JRN-005 emitted specs done on main, resume"
for spec in 002-core-flow 003-reports; do
  mkdir -p "$P/.workflow/specs/$spec"
  sed '1,/^---$/s/^status: draft /status: done /' "$P/$FW_ASSETS_REL/spec.md" >"$P/.workflow/specs/$spec/spec.md"
done
git -C "$P" add .workflow/specs && git -C "$P" commit -q -m "specs 002 and 003: done"
pending=""
for spec in $(on_main "$P" '.slices[].spec'); do
  [ "$(git -C "$P" show "main:.workflow/specs/$spec/spec.md" | yq --front-matter=extract .status)" = "done" ] || pending="$pending $spec"
done
eq "JRN-005 resume reads every emitted spec as done on main" "$pending" ""
git -C "$P" switch -q -c "$BR" main
refused "JRN-005 done is refused while a slice is not done" IT status "$INI" "done"
t "JRN-005 S1 moves to done" 0 IT set-slice "$INI" S1 --status "done"
t "JRN-005 S2 moves to done" 0 IT set-slice "$INI" S2 --status "done"
t "JRN-005 done is accepted once every slice is done" 0 IT status "$INI" "done"
commit_initiative "$P" "initiative 001-storage-overhaul: done"
merge_locally "$P" "Merge initiative 001-storage-overhaul (done)"
eq "JRN-005 done: a second merge commit on main" "$(git -C "$P" log --merges --format=%s main | grep -c .)" 2
eq "JRN-005 done: the re-created branch is deleted" "$(git -C "$P" branch --list "$BR")" ""
eq "JRN-005 done: main carries the done initiative" "$(on_main "$P" .status)" "done"
eq "JRN-005 done: every slice on main is done" "$(on_main "$P" '[.slices[].status] | join(" ")')" "done done"

echo "== JRN-005 done is terminal"
refused "JRN-005 after done, status exploring exits 2" IT status "$INI" exploring
refused "JRN-005 after done, status planned exits 2" IT status "$INI" planned
refused "JRN-005 after done, step exits 2" IT step "$INI" "$LARGE_ENTRY_STEP"
refused "JRN-005 after done, set-slice exits 2" IT set-slice "$INI" S1 --status emitted --spec 002-core-flow
refused "JRN-005 after done, set-question exits 2" IT set-question "$INI" IQ1 --state open
refused "JRN-005 after done, set-pr exits 2" IT set-pr "$INI" null

echo "== JRN-005 planned under task_review pr (stubbed gh / glab)"
Q=$WORK/pr
large_path_repo "$Q"
STUBLOG=$WORK/stub.log
: >"$STUBLOG"
stub_pr_clis "$Q" "$STUBLOG"
git -C "$Q" remote set-url origin https://github.com/o/r.git
git -C "$Q" config remote.origin.pushurl "$Q.origin.git"
seed_initiative "$Q" 001 storage-overhaul
every_slice_emitted "$Q"
initiative_transition "$Q" status "$INI" planned >/dev/null 2>&1
commit_initiative "$Q" "initiative 001-storage-overhaul: planned"
eq "JRN-005 task_review reads pr" "$(bash "$Q/$SCRIPTS_REL/rules-setting.sh" task_review --cwd "$Q" 2>/dev/null)" pr
BASE=$(bash "$Q/$SCRIPTS_REL/rules-setting.sh" main_branch --cwd "$Q" 2>/dev/null)
eq "JRN-005 the PR base is the main branch" "$BASE" main
OTP() { env PATH="$Q/bin:$PATH" bash "$Q/$SCRIPTS_REL/open-task-pr.sh" "$@"; }
TITLE="Initiative 001-storage-overhaul: planned"
out=$(OTP --head "$BR" --base "$BASE" --title "$TITLE" --cwd "$Q" --record "$INI" --dry-run 2>"$WORK/err"); rc=$?
eq "JRN-005 pr dry run exits 0" "$rc" 0
check "JRN-005 pr dry run prints the gh command with head and base" \
  'grep -q "^gh pr create --base main --head initiative/001-storage-overhaul" <<<"$out"' "$out $(cat "$WORK/err")"
check "JRN-005 pr dry run prints the title" 'grep -qF "$TITLE" <<<"$out"' "$out"
check "JRN-005 pr dry run creates nothing" '! grep -q "create" "$STUBLOG"' "$(cat "$STUBLOG")"
out=$(OTP --head "$BR" --base "$BASE" --title "$TITLE" --cwd "$Q" --record "$INI" 2>"$WORK/err")
eq "JRN-005 pr: the PR URL is printed" "$out" "https://github.com/o/r/pull/21"
check "JRN-005 pr: the initiative branch is pushed" 'git -C "$Q.origin.git" show-ref --verify --quiet "refs/heads/$BR"'
eq "JRN-005 pr: --record writes merge_pr" "$(fm "$Q/$INI/initiative.md" .merge_pr)" "https://github.com/o/r/pull/21"
git -C "$Q" remote set-url origin git@gitlab.com:o/r.git
out=$(OTP --head "$BR" --base "$BASE" --title "$TITLE" --cwd "$Q" --dry-run 2>"$WORK/err")
check "JRN-005 pr dry run on GitLab prints the glab command with source and target" \
  'grep -q "^glab mr create --target-branch main --source-branch initiative/001-storage-overhaul" <<<"$out"' "$out $(cat "$WORK/err")"

echo "== generic mode: argument and host edge cases"
GENERIC_ARGS=(--head "$BR" --base "$BASE" --title "$TITLE" --cwd "$Q")
refused "generic mode mixed with <spec-dir> <task-id> exits 2" OTP .workflow/specs/002-core-flow T1 "${GENERIC_ARGS[@]}" --dry-run
refused "generic mode without --title exits 2" OTP --head "$BR" --base "$BASE" --cwd "$Q" --dry-run
refused "generic mode without --head exits 2" OTP --base "$BASE" --title "$TITLE" --cwd "$Q" --dry-run
refused "generic mode without --base exits 2" OTP --head "$BR" --title "$TITLE" --cwd "$Q" --dry-run
refused "generic mode with an unknown option exits 2" OTP "${GENERIC_ARGS[@]}" --draft --dry-run
refused "generic mode with --cwd missing its directory exits 2" OTP --head "$BR" --base "$BASE" --title "$TITLE" --cwd
refused "generic --record on an initiative folder outside the initiatives root exits 2" \
  OTP "${GENERIC_ARGS[@]}" --record .workflow/specs/001-storage-overhaul --dry-run
mkdir -p "$Q/elsewhere" && cp "$Q/$INI/initiative.md" "$Q/elsewhere/initiative.md"
refused "generic --record on a directory with initiative.md outside the initiatives root exits 2" \
  OTP "${GENERIC_ARGS[@]}" --record elsewhere --dry-run
rm -rf "$Q/elsewhere"
out=$(OTP --head "$BR" --help 2>&1); rc=$?
check "generic --help prints the generic usage and exits 0" '[ $rc -eq 0 ] && grep -q "^usage: open-task-pr.sh --head <branch> --base <branch> --title <text>" <<<"$out"' "rc=$rc $out"
refused "generic --record without a directory exits 2" OTP "${GENERIC_ARGS[@]}" --record
refused "generic --record on a directory without initiative.md exits 2" OTP "${GENERIC_ARGS[@]}" --record .workflow/specs --dry-run
out=$(OTP --head initiative/999-missing --base "$BASE" --title "$TITLE" --cwd "$Q" --dry-run 2>/dev/null); rc=$?
check "generic mode with a head branch missing locally -> skipped, rc 0" \
  '[ $rc -eq 0 ] && grep -q "^skipped: head branch initiative/999-missing does not exist locally" <<<"$out"' "$out"
git -C "$Q" remote set-url origin https://example.org/o/r.git
out=$(OTP "${GENERIC_ARGS[@]}" --dry-run 2>/dev/null); rc=$?
check "generic mode with an origin that is neither GitHub nor GitLab -> skipped, rc 0" \
  '[ $rc -eq 0 ] && grep -q "^skipped: origin host is neither GitHub nor GitLab" <<<"$out"' "$out"
git -C "$Q" remote remove origin
out=$(OTP "${GENERIC_ARGS[@]}" --dry-run 2>/dev/null); rc=$?
check "generic mode with no remote -> skipped, rc 0" '[ $rc -eq 0 ] && [ "$out" = "skipped: no origin remote" ]' "$out"

echo "== generic mode reuses an open PR"
R=$WORK/reuse
large_path_repo "$R"
: >"$STUBLOG"
stub_pr_clis "$R" "$STUBLOG"
cat >>"$R/bin/gh" <<'STUB'
[ "$1 $2" != "pr list" ] || echo "https://github.com/o/r/pull/7"
STUB
git -C "$R" remote set-url origin https://github.com/o/r.git
git -C "$R" config remote.origin.pushurl "$R.origin.git"
git -C "$R" branch "$BR"
out=$(env PATH="$R/bin:$PATH" bash "$R/$SCRIPTS_REL/open-task-pr.sh" --head "$BR" --base main --title "$TITLE" --cwd "$R" 2>"$WORK/err")
eq "generic mode prints the URL of the open PR for the same head and base" "$out" "https://github.com/o/r/pull/7"
check "generic mode creates no second PR" '! grep -q "pr create" "$STUBLOG"' "$(cat "$STUBLOG")"
check "generic mode lists open PRs for that head and base" 'grep -q "^gh pr list --head $BR --base main --state open" "$STUBLOG"' "$(cat "$STUBLOG")"
check "generic mode pushes only the head branch" \
  'git -C "$R.origin.git" show-ref --verify --quiet "refs/heads/$BR" && [ "$(git -C "$R.origin.git" for-each-ref --format=x refs/heads | grep -c .)" -eq 2 ]'

echo "== JRN-005 sign-off hand-off on an initiative still exploring"
# close_check DIR : replays 6.13 from sign-off: the initiative's status on main, then the emitted specs, then the done flip.
close_check() {
  local p=$1 spec pending="" slice
  [ "$(on_main "$p" .status)" = planned ] || return 0
  for spec in $(on_main "$p" '.slices[].spec'); do
    [ "$(git -C "$p" show "main:.workflow/specs/$spec/spec.md" 2>/dev/null | yq --front-matter=extract .status)" = "done" ] || pending="$pending $spec"
  done
  [ -z "$pending" ] || return 0
  git -C "$p" switch -q --no-track -c "$BR" main 2>/dev/null || return 1
  for slice in $(fm "$p/$INI/initiative.md" '.slices[].id'); do initiative_transition "$p" set-slice "$INI" "$slice" --status done >/dev/null 2>&1; done
  initiative_transition "$p" status "$INI" done >/dev/null 2>&1
}
repo_state() { git -C "$1" for-each-ref --format='%(refname) %(objectname)'; git -C "$1" status --porcelain; git -C "$1" show "$BR:$INI/initiative.md"; }
E=$WORK/exploring
large_path_repo "$E"
seed_initiative "$E" 001 storage-overhaul
yq --front-matter=process -i '.slices[0].status = "emitted" | .slices[0].spec = "002-core-flow"' "$E/$INI/initiative.md"
commit_initiative "$E" "initiative 001-storage-overhaul: emitted S1 as 002-core-flow"
git -C "$E" switch -q main
mkdir -p "$E/.workflow/specs/002-core-flow"
sed '1,/^---$/s/^status: draft /status: done /' "$E/$FW_ASSETS_REL/spec.md" >"$E/.workflow/specs/002-core-flow/spec.md"
git -C "$E" add .workflow/specs && git -C "$E" commit -q -m "Merge spec 002-core-flow"
before=$(repo_state "$E")
close_check "$E"; rc=$?
check "JRN-005 the 6.13 hand-off on an exploring initiative re-creates no branch and changes nothing" \
  '[ $rc -eq 0 ] && [ "$(repo_state "$E")" = "$before" ]' "rc=$rc"

shellcheck_files "JRN-005 shellcheck merge components" "$P/$IT_REL" "$P/$SCRIPTS_REL/open-task-pr.sh" "$P/$SCRIPTS_REL/rules-setting.sh"
finish
