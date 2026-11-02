#!/usr/bin/env bash
# Suite: tracker-setup.sh (issue-tracking/scripts): the tracker check and the saved tracker settings.
# Covers: JRN-010 (spec 00014), against fake glab and gh (tests/fixtures/fake-trackers.sh) on a PATH that cannot reach a
#   real one: `check` refuses with exit 1 and a reason naming the cause, writing no settings file, when the host's CLI is
#   missing (glab on a gitlab origin, gh on a github origin), when it is not logged in, when the project has issues turned
#   off (both hosts), when the CLI is older than the minimum (both hosts) and when the origin is on neither host; with all
#   fine it exits 0 and prints the host first. `save` with two of the three flow labels missing on the tracker refuses
#   with exit 1 naming both, writes nothing and creates no label; with --create-labels it creates exactly the two and
#   writes .workflow/issue-tracking.yaml with the host and the three labels; on GitHub with every label present it saves
#   without creating any; with the CLI missing it refuses and writes nothing; `save --none` writes `issue_tracker: none`
#   with no CLI installed and no tracker call. The script is shellcheck-clean.
# shellcheck disable=SC2016,SC2329,SC2034  # check expressions are single-quoted and eval'd on purpose and read variables and call helpers shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/fake-trackers.sh
source "$TESTS_DIR/fixtures/fake-trackers.sh"
preflight

new_workdir
fake_trackers_install "$WORK/tracker"
TS_REL=.agents/skills/issue-tracking/scripts/tracker-setup.sh
SETTINGS_REL=.workflow/issue-tracking.yaml
GL=$WORK/gitlab
GH=$WORK/github
OTHER=$WORK/other
tracker_project "$GL" gitlab
tracker_project "$GH" github
tracker_project "$OTHER" other

# setup_run PROJECT FAKES ARGS... : run tracker-setup.sh in PROJECT with the FAKES PATH (gh, glab, both or none);
#   sets OUT, ERR and RC.
setup_run() {
  local project=$1 fakes=$2
  shift 2
  fake_run "$(fake_path "$fakes")" bash "$project/$TS_REL" --cwd "$project" "$@"
}

# no_settings PROJECT : PROJECT has no tracker settings file.
no_settings() { [[ ! -e $1/$SETTINGS_REL ]]; }

# setting PROJECT EXPR : one value of PROJECT's tracker settings.
setting() { yq "$2" "$1/$SETTINGS_REL" 2>/dev/null; }

# refused_naming PROJECT PATTERN : the last run exited 1, named PATTERN (an extended regex, any case) on stderr and wrote no
#   settings file.
refused_naming() { [[ $RC == 1 ]] && grep -Eiq "$2" <<<"$ERR" && no_settings "$1"; }

SAVE_LABELS=(--backlog "$TRACKER_BACKLOG" --in-progress "$TRACKER_IN_PROGRESS" --done "$TRACKER_DONE")

echo "== JRN-010: check refuses a tracker that cannot be used"
fake_trackers_reset
setup_run "$GL" gh check
check "JRN-010 check on a gitlab origin without glab exits 1 naming glab as missing, writing nothing" \
  'refused_naming "$GL" "glab.*(not installed|not found|missing|install)|(not installed|not found|missing|install).*glab"' \
  "rc=$RC err=$ERR"
setup_run "$GH" glab check
check "JRN-010 check on a github origin without gh exits 1 naming gh as missing, writing nothing" \
  'refused_naming "$GH" "gh.*(not installed|not found|missing|install)|(not installed|not found|missing|install).*gh"' \
  "rc=$RC err=$ERR"
FAKE_AUTH=logged-out setup_run "$GL" both check
check "JRN-010 check with glab not logged in exits 1 naming the login, writing nothing" \
  'refused_naming "$GL" "log ?in|auth"' "rc=$RC err=$ERR"
FAKE_AUTH=logged-out setup_run "$GH" both check
check "JRN-010 check with gh not logged in exits 1 naming the login, writing nothing" \
  'refused_naming "$GH" "log ?in|auth"' "rc=$RC err=$ERR"
FAKE_ISSUES=disabled setup_run "$GL" both check
check "JRN-010 check on a GitLab project with issues turned off exits 1 naming issues, writing nothing" \
  'refused_naming "$GL" "issues"' "rc=$RC err=$ERR"
FAKE_ISSUES=disabled setup_run "$GH" both check
check "JRN-010 check on a GitHub repository with issues turned off exits 1 naming issues, writing nothing" \
  'refused_naming "$GH" "issues"' "rc=$RC err=$ERR"
FAKE_GLAB_VERSION=1.0.0 setup_run "$GL" both check
check "JRN-010 check with a glab older than the minimum exits 1 naming the version, writing nothing" \
  'refused_naming "$GL" "version|1\.0\.0|older|minimum"' "rc=$RC err=$ERR"
FAKE_GH_VERSION=2.40.0 setup_run "$GH" both check
check "JRN-010 check with a gh older than the minimum exits 1 naming the version, writing nothing" \
  'refused_naming "$GH" "version|2\.40\.0|older|minimum"' "rc=$RC err=$ERR"
setup_run "$OTHER" both check
check "JRN-010 check on an origin on neither GitHub nor GitLab exits 1 naming the origin, writing nothing" \
  'refused_naming "$OTHER" "origin|github|gitlab|host"' "rc=$RC err=$ERR"

echo "== JRN-010: check passes a usable tracker"
setup_run "$GL" both check
eq "JRN-010 check on a usable GitLab tracker exits 0 and prints gitlab first" "$RC|${OUT%%$'\n'*}" "0|gitlab"
setup_run "$GH" both check
eq "JRN-010 check on a usable GitHub tracker exits 0 and prints github first" "$RC|${OUT%%$'\n'*}" "0|github"

echo "== JRN-010: save writes the settings and creates labels only when confirmed"
fake_trackers_reset
fake_label_seed "$TRACKER_BACKLOG"
setup_run "$GL" both save "${SAVE_LABELS[@]}"
check "JRN-010 save with two flow labels missing exits 1 naming both, writing nothing" \
  'refused_naming "$GL" "In progress" && grep -q "Done" <<<"$OUT$ERR"' "rc=$RC out=$OUT err=$ERR"
eq "JRN-010 save without --create-labels creates no label" "$RC|$(fake_label_names | tr '\n' ,)" "1|Backlog,"
setup_run "$GL" both save "${SAVE_LABELS[@]}" --create-labels
eq "JRN-010 save --create-labels creates exactly the two missing labels" "$RC|$(fake_label_names | tr '\n' ,)" \
  "0|Backlog,Done,In progress,"
eq "JRN-010 save --create-labels writes the GitLab host and the three flow labels" \
  "$(setting "$GL" '[.issue_tracker, .issue_flow.backlog, .issue_flow.in_progress, .issue_flow.done] | join("|")')" \
  "gitlab|Backlog|In progress|Done"
fake_trackers_reset
fake_label_seed "$TRACKER_BACKLOG" "$TRACKER_IN_PROGRESS" "$TRACKER_DONE"
setup_run "$GH" both save "${SAVE_LABELS[@]}"
eq "JRN-010 save on GitHub with every flow label present writes the settings without --create-labels" \
  "$RC|$(setting "$GH" '[.issue_tracker, .issue_flow.backlog, .issue_flow.in_progress, .issue_flow.done] | join("|")')" \
  "0|github|Backlog|In progress|Done"
rm -f "$GL/$SETTINGS_REL"
setup_run "$GL" gh save "${SAVE_LABELS[@]}" --create-labels
check "JRN-010 save on a gitlab origin without glab exits 1 naming glab, writing nothing" \
  'refused_naming "$GL" "glab"' "rc=$RC err=$ERR"
fake_trackers_reset
setup_run "$OTHER" none save --none
eq "JRN-010 save --none writes issue_tracker: none with no CLI installed and no tracker call" \
  "$RC|$(setting "$OTHER" .issue_tracker)|$(fake_call_count)" "0|none|0"

shellcheck_files "shellcheck: tracker-setup.sh" "$GL/$TS_REL"
finish
