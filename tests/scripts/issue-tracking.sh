#!/usr/bin/env bash
# Suite: issue-tracker.sh (issue-tracking/scripts) and next-spec-number.sh (feature-workflow/scripts) with a tracker set up.
# Covers: spec 00014, against fake glab and gh that keep their own tracker state (tests/fixtures/fake-trackers.sh), never a network.
#   JRN-002: with a gitlab origin and GitLab settings and the fake handing out iid 42, next-spec-number.sh
#   prints 00042 and the issue URL; the tracker then holds exactly that issue, with a non-empty placeholder title, an
#   empty body and the backlog label; glab was asked, gh never. create-spec prints the new issue's URL. An issue number
#   longer than five digits is printed whole.
#   JRN-003: the same with a github origin, GitHub settings and number 7: 00007 and the URL; gh was asked, glab never.
#   JRN-004: two clones of one project, whose local specs would scan to 00051, each run the script against the one tracker
#   and get two different numbers, 00042 and 00043, and the tracker holds two issues.
#   JRN-005: fill sets the issue title from the file's first `# ` heading and the body to the whole file unchanged: on
#   GitLab a file starting with `#` holding `[`, `{`, `$HOME` and backtick lines; on GitHub a spec.md with frontmatter.
#   JRN-006: create-task on GitLab makes a child task under the spec's issue whose body is the task file, title from its
#   heading, in the backlog stage, and prints its URL; with the GraphQL call refused it makes one issue instead, linked
#   relates_to the spec's issue, with no parent; on GitHub it makes a sub-issue of the spec's issue.
#   JRN-007: move on each host takes an issue from backlog to in_progress to done and back to in_progress, and to
#   backlog: each move leaves exactly the new flow label beside the issue's other labels; done closes the issue and
#   in_progress reopens it; an unknown stage, or no stage, exits 2 and changes nothing.
#   JRN-008: a network failure on GitLab and an auth failure on GitHub make next-spec-number.sh exit 1 naming the cause on
#   stderr, with nothing on stdout, no new spec folder and no issue; create-spec and move fail the same way.
#   Without a tracker set up (no settings file, or issue_tracker: none), every issue-tracker.sh command prints
#   `skipped: no tracker`, exits 0 and calls neither CLI. Settings naming a host the origin is not on exit 2 with no call.
#   Refused before any call, with exit 2: settings naming an unknown tracker or putting two flow stages on one label, fill
#   with a file that has no `# ` heading or does not exist, an argument that is not an issue URL or is an http one, and a
#   GitLab project without glab installed. A network failure during create-task and an auth failure during fill exit 1
#   naming the cause and change nothing on the tracker. A tracker answering with http issue URLs makes create-spec and
#   create-task on each host exit 1 naming the URL and saying only https trackers are supported, with nothing on stdout.
#   The scripts are shellcheck-clean.
# shellcheck disable=SC2016,SC2329,SC1010,SC2034  # check expressions are single-quoted and eval'd on purpose and read variables and call helpers shellcheck cannot see; "done" is a stage and a status word
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/fake-trackers.sh
source "$TESTS_DIR/fixtures/fake-trackers.sh"
preflight

new_workdir
fake_trackers_install "$WORK/tracker"
NSN_REL=.agents/skills/feature-workflow/scripts/next-spec-number.sh
IT_REL=.agents/skills/issue-tracking/scripts/issue-tracker.sh
GL=$WORK/gitlab
GH=$WORK/github
PLAIN=$WORK/plain
NONE=$WORK/none
tracker_project "$GL" gitlab
tracker_settings "$GL" gitlab
tracker_project "$GH" github
tracker_settings "$GH" github
tracker_project "$PLAIN" gitlab
tracker_project "$NONE" gitlab
tracker_settings "$NONE" none

# fresh_tracker : an empty tracker that already has the three flow labels, as setup leaves it.
fresh_tracker() {
  fake_trackers_reset
  fake_label_seed "$TRACKER_BACKLOG" "$TRACKER_IN_PROGRESS" "$TRACKER_DONE"
}

# next_number PROJECT : run next-spec-number.sh in PROJECT with both fakes on PATH; sets OUT, ERR and RC.
next_number() { fake_run "$(fake_path both)" bash "$1/$NSN_REL" --cwd "$1"; }

# tracker PROJECT ARGS... : run issue-tracker.sh in PROJECT with both fakes on PATH; sets OUT, ERR and RC.
tracker() {
  local project=$1
  shift
  fake_run "$(fake_path both)" bash "$project/$IT_REL" --cwd "$project" "$@"
}

# only_issue_besides N : the number of the one issue on the tracker other than N; empty unless there is exactly one.
only_issue_besides() {
  local others
  others=$(fake_issue_numbers | grep -vx "$1")
  [[ $(printf '%s\n' "$others" | grep -c .) == 1 ]] && printf '%s' "$others"
}

# labels_are N LABEL... : issue N carries exactly these labels.
labels_are() {
  local n=$1
  shift
  [[ $(fake_issue "$n" labels) == "$(printf '%s\n' "$@" | LC_ALL=C sort)" ]]
}

# names_network_cause / names_auth_cause : the last run's stderr says what went wrong.
names_network_cause() { grep -Eiq 'no such host|network|connect|reach' <<<"$ERR"; }
names_auth_cause() { grep -Eiq 'auth|log ?in|401|credential|token' <<<"$ERR"; }

# spec_folder_count PROJECT : how many folders sit in PROJECT's specs folder.
spec_folder_count() { find "$1/.workflow/specs" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' '; }

TASK_FILE=$WORK/T01-move.md
printf '# T1: Move script\n\nSpec: [spec.md](../spec.md)\n\n## What to build\n\n[the move](#what-to-build) with `rollback`.\n' \
  >"$TASK_FILE"

echo "== JRN-002: a GitLab issue names the spec"
fresh_tracker
FAKE_ISSUE_NUMBER=42 next_number "$GL"
eq "JRN-002 next-spec-number.sh prints 00042 and the GitLab issue URL" "$RC|$OUT" "0|00042
$(fake_url glab 42)"
eq "JRN-002 the tracker holds exactly the one new issue, 42" "$(fake_issue_numbers | tr '\n' ' ')" "42 "
check "JRN-002 the new issue has a placeholder title and an empty body" \
  '[[ -n $(fake_issue 42 title) && -z $(fake_issue 42 body) ]]' "title=$(fake_issue 42 title) body=$(fake_issue 42 body)"
check "JRN-002 the new spec issue starts in the backlog stage" 'labels_are 42 "$TRACKER_BACKLOG"' "$(fake_issue 42 labels)"
check "JRN-002 the GitLab origin drives glab and never gh" '[[ $(fake_cli_call_count glab) -gt 0 && $(fake_cli_call_count gh) == 0 ]]' \
  "$(fake_calls)"
fresh_tracker
FAKE_ISSUE_NUMBER=43 tracker "$GL" create-spec
eq "JRN-002 create-spec prints the new issue's URL" "$RC|$OUT|$(fake_issue_numbers)" "0|$(fake_url glab 43)|43"
fresh_tracker
FAKE_ISSUE_NUMBER=123456 next_number "$GL"
eq "JRN-002 an issue number longer than five digits is printed whole" "$RC|${OUT%%$'\n'*}" "0|123456"

echo "== JRN-003: a GitHub issue names the spec"
fresh_tracker
FAKE_ISSUE_NUMBER=7 next_number "$GH"
eq "JRN-003 next-spec-number.sh prints 00007 and the GitHub issue URL" "$RC|$OUT" "0|00007
$(fake_url gh 7)"
check "JRN-003 the tracker holds the one new issue, with a placeholder title and an empty body" \
  '[[ $(fake_issue_numbers) == 7 && -n $(fake_issue 7 title) && -z $(fake_issue 7 body) ]]' \
  "issues=$(fake_issue_numbers | tr '\n' ' ') title=$(fake_issue 7 title)"
check "JRN-003 the GitHub origin drives gh and never glab" '[[ $(fake_cli_call_count gh) -gt 0 && $(fake_cli_call_count glab) == 0 ]]' \
  "$(fake_calls)"

echo "== JRN-004: two starts against one tracker"
SHARED=$WORK/shared
tracker_project "$SHARED" gitlab
tracker_settings "$SHARED" gitlab
mkdir -p "$SHARED/.workflow/specs/00050-local"
printf -- '---\nstatus: done\n---\n\n# Local\n' >"$SHARED/.workflow/specs/00050-local/spec.md"
git_commit_all "$SHARED" "fixture: tracker settings and a local spec"
for clone in one two; do
  git clone -q "$SHARED" "$WORK/clone-$clone"
  git -C "$WORK/clone-$clone" remote set-url origin "$TRACKER_ORIGIN_GITLAB"
done
fresh_tracker
FAKE_ISSUE_NUMBER=42 next_number "$WORK/clone-one"
FIRST=${OUT%%$'\n'*}
FAKE_ISSUE_NUMBER=42 next_number "$WORK/clone-two"
SECOND=${OUT%%$'\n'*}
eq "JRN-004 the two clones get two different tracker numbers, 00042 and 00043, not the local 00051" \
  "$FIRST $SECOND" "00042 00043"
eq "JRN-004 the tracker holds one issue per start" "$(fake_issue_numbers | tr '\n' ' ')" "42 43 "

echo "== JRN-005: the spec is copied into its issue"
GL_SPEC=$WORK/gitlab-spec.md
printf '# Widget export\n\n[1, 2] opens this line with a bracket.\n{"a": 1} opens this one with a brace.\nKeep $HOME and `code` as written.\n' \
  >"$GL_SPEC"
fresh_tracker
fake_issue_seed 42 "Spec placeholder" open "$TRACKER_BACKLOG"
tracker "$GL" fill "$(fake_url glab 42)" "$GL_SPEC"
eq "JRN-005 GitLab fill sets the title from the first heading" "$RC|$(fake_issue 42 title)" "0|Widget export"
eq "JRN-005 GitLab fill sets the body to the whole file, unchanged" "$(fake_issue 42 body)" "$(cat "$GL_SPEC")"
GH_SPEC=$WORK/github-spec.md
printf -- '---\nstatus: draft\ntracker_issue: "%s"\n---\n\n# Tracker issues as spec IDs\n\n[Design log](design-log.md)\n\n## Why\n\nNumbers collide.\n' \
  "$(fake_url gh 7)" >"$GH_SPEC"
fresh_tracker
fake_issue_seed 7 "Spec placeholder" open "$TRACKER_BACKLOG"
tracker "$GH" fill "$(fake_url gh 7)" "$GH_SPEC"
eq "JRN-005 GitHub fill takes the title from the first heading after the frontmatter" "$RC|$(fake_issue 7 title)" \
  "0|Tracker issues as spec IDs"
eq "JRN-005 GitHub fill sets the body to the whole file, unchanged" "$(fake_issue 7 body)" "$(cat "$GH_SPEC")"

echo "== JRN-006: task issues under the spec issue"
fresh_tracker
fake_issue_seed 42 "Spec" open "$TRACKER_IN_PROGRESS"
tracker "$GL" create-task "$(fake_url glab 42)" "$TASK_FILE"
TASK=$(only_issue_besides 42)
eq "JRN-006 GitLab create-task prints the URL of the one new issue" "$RC|$OUT" "0|$(fake_url glab "${TASK:-none}")"
eq "JRN-006 the GitLab task issue is a child of the spec's issue" "$(fake_issue "${TASK:-none}" parent)" 42
eq "JRN-006 the GitLab task issue's body is the task file" "$(fake_issue "${TASK:-none}" body)" "$(cat "$TASK_FILE")"
check "JRN-006 the GitLab task issue is titled from the task file and starts in the backlog stage" \
  '[[ $(fake_issue "${TASK:-none}" title) == *"Move script"* ]] && labels_are "${TASK:-none}" "$TRACKER_BACKLOG"' \
  "title=$(fake_issue "${TASK:-none}" title) labels=$(fake_issue "${TASK:-none}" labels)"
fresh_tracker
fake_issue_seed 42 "Spec" open "$TRACKER_IN_PROGRESS"
FAKE_GRAPHQL=refuse tracker "$GL" create-task "$(fake_url glab 42)" "$TASK_FILE"
TASK=$(only_issue_besides 42)
eq "JRN-006 with the child call refused, create-task prints the URL of the one new issue" "$RC|$OUT" \
  "0|$(fake_url glab "${TASK:-none}")"
check "JRN-006 with the child call refused, the task issue is linked relates_to the spec's issue and has no parent" \
  '[[ $(fake_issue "${TASK:-none}" links) == "relates_to 42" && -z $(fake_issue "${TASK:-none}" parent) ]]' \
  "issues=$(fake_issue_numbers | tr '\n' ' ') links=$(fake_issue "${TASK:-none}" links): $ERR"
eq "JRN-006 the linked task issue's body is the task file" "$(fake_issue "${TASK:-none}" body)" "$(cat "$TASK_FILE")"
fresh_tracker
fake_issue_seed 7 "Spec" open "$TRACKER_IN_PROGRESS"
tracker "$GH" create-task "$(fake_url gh 7)" "$TASK_FILE"
TASK=$(only_issue_besides 7)
eq "JRN-006 GitHub create-task prints the URL of the one new issue" "$RC|$OUT" "0|$(fake_url gh "${TASK:-none}")"
eq "JRN-006 the GitHub task issue is a sub-issue of the spec's issue" "$(fake_issue "${TASK:-none}" parent)" 7
eq "JRN-006 the GitHub task issue's body is the task file" "$(fake_issue "${TASK:-none}" body)" "$(cat "$TASK_FILE")"

echo "== JRN-007: issues move through the issue flow"
# move_case HOST FROM_LABEL FROM_STATE STAGE : seed one issue in that stage beside a `bug` label, then move it to STAGE.
move_case() {
  if [[ $1 == glab ]]; then project=$GL n=42; else project=$GH n=7; fi
  fresh_tracker
  fake_issue_seed "$n" "Spec" "$3" "$2" bug
  tracker "$project" move "$(fake_url "$1" "$n")" "$4"
}
# moved_to LABEL STATE : the last move succeeded and left the issue in STATE with exactly LABEL beside `bug`.
moved_to() { [[ $RC == 0 && $(fake_issue "$n" state) == "$2" ]] && labels_are "$n" bug "$1"; }
for host in glab gh; do
  move_case "$host" "$TRACKER_BACKLOG" open in_progress
  check "JRN-007 $host: backlog to in_progress swaps the flow label and keeps the issue open" \
    'moved_to "$TRACKER_IN_PROGRESS" open' "rc=$RC labels=$(fake_issue "$n" labels | tr '\n' ,) state=$(fake_issue "$n" state): $ERR"
  move_case "$host" "$TRACKER_IN_PROGRESS" open done
  check "JRN-007 $host: in_progress to done swaps the flow label and closes the issue" \
    'moved_to "$TRACKER_DONE" closed' "rc=$RC labels=$(fake_issue "$n" labels | tr '\n' ,) state=$(fake_issue "$n" state): $ERR"
  move_case "$host" "$TRACKER_DONE" closed in_progress
  check "JRN-007 $host: a done issue moved back to in_progress is reopened with only the in-progress flow label" \
    'moved_to "$TRACKER_IN_PROGRESS" open' "rc=$RC labels=$(fake_issue "$n" labels | tr '\n' ,) state=$(fake_issue "$n" state): $ERR"
  move_case "$host" "$TRACKER_IN_PROGRESS" open backlog
  check "JRN-007 $host: in_progress back to backlog swaps the flow label" \
    'moved_to "$TRACKER_BACKLOG" open' "rc=$RC labels=$(fake_issue "$n" labels | tr '\n' ,): $ERR"
  move_case "$host" "$TRACKER_IN_PROGRESS" open review
  check "JRN-007 $host: an unknown stage exits 2 and leaves the labels" \
    '[[ $RC == 2 ]] && labels_are $n bug "$TRACKER_IN_PROGRESS"' "rc=$RC labels=$(fake_issue "$n" labels | tr '\n' ,)"
  if [[ $host == glab ]]; then project=$GL n=42; else project=$GH n=7; fi
  tracker "$project" move "$(fake_url "$host" "$n")"
  check "JRN-007 $host: move without a stage exits 2 and leaves the labels" \
    '[[ $RC == 2 ]] && labels_are $n bug "$TRACKER_IN_PROGRESS"' "rc=$RC labels=$(fake_issue "$n" labels | tr '\n' ,)"
done

echo "== JRN-008: an unreachable tracker stops the spec start"
fresh_tracker
BEFORE=$(spec_folder_count "$GL")
FAKE_FAIL=network next_number "$GL"
check "JRN-008 a GitLab network failure exits 1 naming the cause, with nothing on stdout" \
  '[[ $RC == 1 && -z $OUT ]] && names_network_cause' "rc=$RC out=$OUT err=$ERR"
check "JRN-008 the network failure exits 1 leaving no new spec folder and no issue" \
  '[[ $RC == 1 && $(spec_folder_count "$GL") == "$BEFORE" && -z $(fake_issue_numbers) ]]' "rc=$RC folders=$(spec_folder_count "$GL")"
FAKE_FAIL=auth next_number "$GH"
check "JRN-008 a GitHub auth failure exits 1 naming the cause, with nothing on stdout" \
  '[[ $RC == 1 && -z $OUT ]] && names_auth_cause' "rc=$RC out=$OUT err=$ERR"
FAKE_FAIL=network tracker "$GL" create-spec
check "JRN-008 create-spec on a network failure exits 1 naming the cause, with nothing on stdout" \
  '[[ $RC == 1 && -z $OUT ]] && names_network_cause' "rc=$RC out=$OUT err=$ERR"
fake_issue_seed 42 "Spec" open "$TRACKER_BACKLOG"
FAKE_FAIL=auth tracker "$GL" move "$(fake_url glab 42)" in_progress
check "JRN-008 move on an auth failure exits 1 naming the cause" '[[ $RC == 1 ]] && names_auth_cause' "rc=$RC err=$ERR"

echo "== no tracker set up: every command is skipped"
for project in "$PLAIN" "$NONE"; do
  case $project in
    "$PLAIN") setting="no settings file" ;;
    *) setting="issue_tracker: none" ;;
  esac
  fresh_tracker
  for command in create-spec "fill $(fake_url glab 42) $GL_SPEC" "create-task $(fake_url glab 42) $TASK_FILE" \
    "move $(fake_url glab 42) done"; do
    # shellcheck disable=SC2086  # each command line splits into the subcommand and its arguments
    tracker "$project" $command
    check "JRN-001 with $setting, issue-tracker.sh ${command%% *} prints skipped: no tracker and calls no tracker" \
      '[[ $RC == 0 && $OUT == "skipped: no tracker" && $(fake_call_count) == 0 ]]' "rc=$RC out=$OUT calls=$(fake_calls)"
  done
done

echo "== settings that do not fit the origin"
MISMATCH=$WORK/mismatch
tracker_project "$MISMATCH" gitlab
tracker_settings "$MISMATCH" github
fresh_tracker
tracker "$MISMATCH" create-spec
check "JRN-002 settings naming GitHub on a GitLab origin exit 2 with no tracker call" \
  '[[ $RC == 2 && $(fake_call_count) == 0 ]]' "rc=$RC out=$OUT calls=$(fake_calls)"

echo "== bad settings, bad arguments and a missing CLI are refused before any tracker call"
BAD=$WORK/bad-settings
tracker_project "$BAD" gitlab
mkdir -p "$BAD/.workflow"
printf 'issue_tracker: jira\n' >"$BAD/.workflow/issue-tracking.yaml"
fresh_tracker
tracker "$BAD" create-spec
check "settings naming an unknown tracker exit 2 naming the setting, with no tracker call" \
  '[[ $RC == 2 && $ERR == *issue_tracker* && $(fake_call_count) == 0 ]]' "rc=$RC err=$ERR calls=$(fake_calls)"
printf 'issue_tracker: gitlab\nissue_flow:\n  backlog: Todo\n  in_progress: Todo\n  done: Done\n' \
  >"$BAD/.workflow/issue-tracking.yaml"
tracker "$BAD" move "$(fake_url glab 42)" done
check "settings with two flow stages on one label exit 2 naming issue_flow, with no tracker call" \
  '[[ $RC == 2 && $ERR == *issue_flow* && $(fake_call_count) == 0 ]]' "rc=$RC err=$ERR calls=$(fake_calls)"
HEADLESS=$WORK/headless.md
printf -- '---\nstatus: draft\n---\n\nNo heading here.\n## Only a second-level one\n' >"$HEADLESS"
fake_issue_seed 42 "Spec placeholder" open "$TRACKER_BACKLOG"
tracker "$GL" fill "$(fake_url glab 42)" "$HEADLESS"
check "fill with a file that has no '# ' heading exits 2 and leaves the issue untouched" \
  '[[ $RC == 2 && $(fake_issue 42 title) == "Spec placeholder" && $(fake_call_count) == 0 ]]' \
  "rc=$RC title=$(fake_issue 42 title) calls=$(fake_calls)"
tracker "$GL" fill "$(fake_url glab 42)" "$WORK/no-such-spec.md"
check "fill with a missing file exits 2 with no tracker call" '[[ $RC == 2 && $(fake_call_count) == 0 ]]' \
  "rc=$RC calls=$(fake_calls)"
tracker "$GL" move not-an-issue-url done
check "move with an argument that is not an issue URL exits 2 with no tracker call" \
  '[[ $RC == 2 && $(fake_call_count) == 0 ]]' "rc=$RC calls=$(fake_calls)"
HTTP_SPEC_URL=$(fake_url glab 42)
HTTP_SPEC_URL=http://${HTTP_SPEC_URL#https://}
tracker "$GL" create-task "$HTTP_SPEC_URL" "$TASK_FILE"
check "create-task with an http spec issue URL exits 2 with no tracker call" \
  '[[ $RC == 2 && -z $OUT && $(fake_call_count) == 0 ]]' "rc=$RC out=$OUT err=$ERR calls=$(fake_calls)"
fake_run "$(fake_path gh)" bash "$GL/$IT_REL" --cwd "$GL" create-spec
check "a GitLab project without glab installed exits 2 naming glab, with no tracker call" \
  '[[ $RC == 2 && -z $OUT && $ERR == *glab* && $(fake_call_count) == 0 ]]' "rc=$RC out=$OUT err=$ERR calls=$(fake_calls)"

echo "== a tracker failure while filing a task"
fresh_tracker
fake_issue_seed 42 "Spec" open "$TRACKER_IN_PROGRESS"
FAKE_FAIL=network tracker "$GL" create-task "$(fake_url glab 42)" "$TASK_FILE"
check "create-task on a GitLab network failure exits 1 naming the cause, with nothing on stdout and no new issue" \
  '[[ $RC == 1 && -z $OUT && $(fake_issue_numbers) == 42 ]] && names_network_cause' \
  "rc=$RC out=$OUT issues=$(fake_issue_numbers | tr '\n' ' ') err=$ERR"
# Only the GraphQL calls time out, so the REST calls the linked-issue fallback would make still succeed.
GRAPHQL_TIMEOUT_BIN=$WORK/bin-graphql-timeout
mkdir -p "$GRAPHQL_TIMEOUT_BIN"
printf '#!/usr/bin/env bash\nif [[ $1 == api && $2 == graphql ]]; then\n  echo "dial tcp: i/o timeout" >&2\n  exit 1\nfi\nexec %q "$@"\n' \
  "$FAKE_BIN/glab" >"$GRAPHQL_TIMEOUT_BIN/glab"
chmod +x "$GRAPHQL_TIMEOUT_BIN/glab"
fresh_tracker
fake_issue_seed 42 "Spec" open "$TRACKER_IN_PROGRESS"
fake_run "$GRAPHQL_TIMEOUT_BIN:$(fake_path both)" bash "$GL/$IT_REL" --cwd "$GL" create-task "$(fake_url glab 42)" "$TASK_FILE"
check "create-task with the GitLab child call timing out exits 1 naming the timeout, with no linked issue in its place" \
  '[[ $RC == 1 && -z $OUT && $(fake_issue_numbers) == 42 && $ERR == *"i/o timeout"* && $ERR != *refused* ]]' \
  "rc=$RC out=$OUT issues=$(fake_issue_numbers | tr '\n' ' ') err=$ERR"
fresh_tracker
fake_issue_seed 7 "Spec" open "$TRACKER_IN_PROGRESS"
FAKE_FAIL=auth tracker "$GH" fill "$(fake_url gh 7)" "$GH_SPEC"
check "fill on a GitHub auth failure exits 1 naming the cause and leaves the issue untouched" \
  '[[ $RC == 1 && $(fake_issue 7 title) == Spec ]] && names_auth_cause' "rc=$RC title=$(fake_issue 7 title) err=$ERR"

echo "== a tracker that answers with http issue URLs"
# Each wrapper passes the call to the fake and turns every https in its answer into http, as a tracker served over http
# would answer.
HTTP_BIN=$WORK/bin-http-urls
mkdir -p "$HTTP_BIN"
for cli in gh glab; do
  printf '#!/usr/bin/env bash\nanswer=$(%q "$@") || exit\nprintf "%%s\\n" "$answer" | sed "s#https://#http://#g"\n' \
    "$FAKE_BIN/$cli" >"$HTTP_BIN/$cli"
  chmod +x "$HTTP_BIN/$cli"
done
# refuses_http_url HOST : the last run exited 1 with nothing on stdout, naming an http URL of HOST and saying only https
#   trackers are supported.
refuses_http_url() {
  local http_url
  http_url=$(fake_url "$1" "")
  http_url=http://${http_url#https://}
  [[ $RC == 1 && -z $OUT && $ERR == *"$http_url"* && $ERR == *"only https trackers are supported"* ]]
}
for host in glab gh; do
  if [[ $host == glab ]]; then project=$GL n=42; else project=$GH n=7; fi
  fresh_tracker
  fake_run "$HTTP_BIN:$(fake_path both)" bash "$project/$IT_REL" --cwd "$project" create-spec
  check "$host: create-spec given an http issue URL by the tracker exits 1 naming it and saying only https is supported" \
    'refuses_http_url "$host"' "rc=$RC out=$OUT err=$ERR"
  fresh_tracker
  fake_issue_seed "$n" "Spec" open "$TRACKER_IN_PROGRESS"
  fake_run "$HTTP_BIN:$(fake_path both)" bash "$project/$IT_REL" --cwd "$project" create-task "$(fake_url "$host" "$n")" \
    "$TASK_FILE"
  check "$host: create-task given an http issue URL by the tracker exits 1 naming it and saying only https is supported" \
    'refuses_http_url "$host"' "rc=$RC out=$OUT err=$ERR"
done

shellcheck_files "shellcheck: issue-tracker.sh and next-spec-number.sh" "$GL/$IT_REL" "$GL/$NSN_REL"
finish
