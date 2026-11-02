#!/usr/bin/env bash
# File: Helper script (not a hook): check that the project's tracker can be used and save the tracker settings.
# Purpose: Setup for tracker issues, run by project-setup or on a project already under way. `check` proves the host CLI
#   (glab for GitLab, gh for GitHub, chosen from the `origin` remote through wf_origin_host) is installed, new enough and
#   logged in, and that the project has issues enabled. `save` runs the same check, then writes
#   .workflow/issue-tracking.yaml with the host and the three agreed issue flow labels, replacing any settings file there.
# Usage:
#   tracker-setup.sh [--cwd <dir>] check
#       prints the host (gitlab or github) on its first line.
#   tracker-setup.sh [--cwd <dir>] save --backlog <label> --in-progress <label> --done <label> [--create-labels]
#       writes the settings; labels the tracker lacks are created only with --create-labels, otherwise nothing is written.
#       Prints one `created label: <name>` line per label it creates, then `saved <settings file>`.
#   tracker-setup.sh [--cwd <dir>] save --none
#       writes `issue_tracker: none`, calling neither CLI; prints `saved <settings file>`.
#     --cwd    any directory in the project or one of its worktrees. Default: $PWD.
# Exit: 0 checked or saved; 1 refused, with the reason on stderr (the origin remote on neither GitHub nor GitLab, CLI
#   missing, CLI older than the minimum, not logged in, issues disabled, labels missing without --create-labels, or a
#   tracker call that failed); 2 usage error (including flow labels that are not three different names), not a git
#   repository, or the settings file cannot be written.
# Called by: project-setup, the issue-tracking skill.
# Notes: Requires git, jq, mikefarah yq v4 and the host's CLI: gh 2.94.0 or later (`gh issue create --parent`), glab
#   1.115.0 or later (`--description-file` on issue commands). bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

SCRIPT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../../lib/workflow-paths.sh
. "$SCRIPT_DIR/../../../lib/workflow-paths.sh"

PROG="tracker-setup.sh"
GH_MINIMUM=2.94.0
GH_MINIMUM_REASON="the first gh with \`gh issue create --parent\`"
GLAB_MINIMUM=1.115.0
GLAB_MINIMUM_REASON="the first glab with \`--description-file\` on issue commands"
VERSION_PATTERN='([0-9]+)\.([0-9]+)(\.([0-9]+))?'

# die MSG [CODE] : print "<prog>: MSG" to stderr and exit CODE (default 2; 1 for a refusal).
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-2}"; }

# usage : print the usage lines to stderr and exit 2.
usage() {
  cat >&2 <<EOF
usage: $PROG [--cwd <dir>] check
       $PROG [--cwd <dir>] save --backlog <label> --in-progress <label> --done <label> [--create-labels]
       $PROG [--cwd <dir>] save --none
EOF
  exit 2
}

# tracker_call WHAT ARGS... : run the host's CLI with ARGS in the project and print its stdout; exit 1 naming WHAT when it
#   fails, below the CLI's own message on stderr.
tracker_call() {
  local what=$1
  shift
  (cd "$project_root" && "$cli" "$@") || die "$cli could not $what" 1
}

# version_at_least VERSION MINIMUM : status 0 when the dotted VERSION is MINIMUM or later, 1 when it is older.
version_at_least() {
  local IFS=. have=() want=() i
  read -r -a have <<<"$1"
  read -r -a want <<<"$2"
  # 10# keeps a part such as 09 decimal; bash would read it as octal.
  for i in 0 1 2; do
    if ((10#${have[i]:-0} > 10#${want[i]:-0})); then return 0; fi
    if ((10#${have[i]:-0} < 10#${want[i]:-0})); then return 1; fi
  done
  return 0
}

# installed_version : print the version the host's CLI reports on the first line of `--version`; exit 1 when it reports
#   none.
installed_version() {
  local output first_line
  output=$("$cli" --version) || die "$cli --version failed" 1
  first_line=${output%%$'\n'*}
  [[ $first_line =~ $VERSION_PATTERN ]] || die "cannot read a version from \`$cli --version\`: $first_line" 1
  printf '%s\n' "${BASH_REMATCH[0]}"
}

# require_login : exit 1 when the host's CLI is not logged in, showing what `auth status` said.
require_login() {
  local answer
  if ! answer=$(cd "$project_root" && "$cli" auth status 2>&1); then
    printf '%s\n' "$answer" >&2
    die "$cli is not logged in to $tracker; run \`$cli auth login\` and check again" 1
  fi
}

# require_issues_enabled : exit 1 when the project on the tracker has its issues turned off.
require_issues_enabled() {
  local answer enabled
  if [[ $cli == gh ]]; then
    enabled=$(tracker_call "read whether the repository has issues" repo view --json hasIssuesEnabled \
      --jq .hasIssuesEnabled) || exit 1
  else
    answer=$(tracker_call "read the project" api projects/:fullpath) || exit 1
    # GitLab reports `private` for issues only members can see, which the workflow can still use.
    enabled=$(jq -r 'if .issues_access_level == null then "unknown"
      else .issues_access_level != "disabled" end' <<<"$answer" 2>/dev/null) || enabled=unknown
  fi
  case $enabled in
    true) ;;
    false) die "issues are turned off on this $tracker project; turn them on in its settings and check again" 1 ;;
    *) die "$cli did not say whether issues are turned on: ${answer:-$enabled}" 1 ;;
  esac
}

# check_tracker : set tracker and cli from the origin remote, then exit 1 unless the CLI is installed, new enough and
#   logged in and the project has issues turned on.
check_tracker() {
  local minimum reason version
  tracker=$(wf_origin_host "$project_root")
  case $tracker in
    github) cli=gh minimum=$GH_MINIMUM reason=$GH_MINIMUM_REASON ;;
    gitlab) cli=glab minimum=$GLAB_MINIMUM reason=$GLAB_MINIMUM_REASON ;;
    *) die "the origin remote is on neither GitHub nor GitLab, so there is no tracker to use; save --none records that" 1 ;;
  esac
  command -v "$cli" >/dev/null || die "$cli is not installed; install $cli $minimum or later to use the $tracker tracker" 1
  version=$(installed_version) || exit 1
  version_at_least "$version" "$minimum" ||
    die "$cli $version is older than the minimum version $minimum, $reason; upgrade $cli and check again" 1
  require_login
  require_issues_enabled
}

# tracker_labels : print the names of the labels the project has on the tracker, one per line.
tracker_labels() {
  local answer
  if [[ $cli == gh ]]; then
    tracker_call "list the repository's labels" label list --json name --limit 1000 --jq '.[].name' || exit 1
  else
    answer=$(tracker_call "list the project's labels" api --paginate "projects/:fullpath/labels?per_page=100") || exit 1
    jq -r '.[].name' <<<"$answer" || die "glab answered the label list with no JSON: $answer" 1
  fi
}

# create_label NAME : create the label NAME on the tracker.
create_label() {
  if [[ $cli == gh ]]; then
    tracker_call "create the label '$1'" label create "$1" >/dev/null || exit 1
  else
    tracker_call "create the label '$1'" label create --name "$1" >/dev/null || exit 1
  fi
}

# write_settings TRACKER [BACKLOG IN_PROGRESS DONE] : replace the settings file with TRACKER and, unless it is none, the
#   three issue flow labels; print `saved <settings file>`.
write_settings() {
  local draft
  mkdir -p "$(dirname "$settings")" || die "cannot create the folder of $settings"
  # The draft sits beside the settings file so the move into place replaces it whole, never half written.
  draft=$(mktemp "$settings.XXXXXX") || die "cannot write beside $settings"
  if [[ $1 == none ]]; then
    TRACKER=$1 yq -n '.issue_tracker = strenv(TRACKER)' >"$draft" || { rm -f "$draft"; die "cannot write $settings"; }
  else
    # Double-quoted labels stay strings, such as yes and 123, for YAML 1.1 readers.
    TRACKER=$1 BACKLOG=$2 IN_PROGRESS=$3 DONE=$4 yq -n '.issue_tracker = strenv(TRACKER)
      | .issue_flow.backlog = strenv(BACKLOG) | .issue_flow.in_progress = strenv(IN_PROGRESS)
      | .issue_flow.done = strenv(DONE) | .issue_flow[] style="double"' >"$draft" ||
      { rm -f "$draft"; die "cannot write $settings"; }
  fi
  # mktemp makes the draft readable by its owner only; the settings file is shared project data.
  chmod 644 "$draft" || { rm -f "$draft"; die "cannot write $settings"; }
  mv "$draft" "$settings" || { rm -f "$draft"; die "cannot write $settings"; }
  printf 'saved %s\n' "$settings"
}

# save_tracker : check the tracker, make sure the three flow labels exist on it (creating the missing ones only with
#   --create-labels) and write the settings; exit 1, writing nothing, when labels are missing without --create-labels.
save_tracker() {
  local existing label missing=()
  if [[ $backlog == "$in_progress" || $backlog == "$done_label" || $in_progress == "$done_label" ]]; then
    die "the backlog, in progress and done labels must be three different names"
  fi
  check_tracker
  existing=$(tracker_labels) || exit 1
  for label in "$backlog" "$in_progress" "$done_label"; do
    grep -Fxq -- "$label" <<<"$existing" || missing+=("$label")
  done
  if [[ ${#missing[@]} -gt 0 && $create_labels -eq 0 ]]; then
    die "the $tracker tracker has no label $(quoted_list "${missing[@]}"); agree to create them, then run save again with --create-labels" 1
  fi
  for label in ${missing[@]+"${missing[@]}"}; do
    create_label "$label"
    printf 'created label: %s\n' "$label"
  done
  write_settings "$tracker" "$backlog" "$in_progress" "$done_label"
}

# quoted_list NAME... : print the NAMEs each in single quotes, joined by ", ".
quoted_list() {
  local name joined=""
  for name in "$@"; do joined+="${joined:+, }'$name'"; done
  printf '%s\n' "$joined"
}

cwd=$PWD command=""
backlog="" in_progress="" done_label="" create_labels=0 none=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --cwd | --backlog | --in-progress | --done)
      [[ $# -ge 2 ]] || usage
      case $1 in
        --cwd) cwd=$2 ;;
        --backlog) backlog=$2 ;;
        --in-progress) in_progress=$2 ;;
        --done) done_label=$2 ;;
      esac
      shift 2
      ;;
    --create-labels)
      create_labels=1
      shift
      ;;
    --none)
      none=1
      shift
      ;;
    check | save)
      [[ -z $command ]] || usage
      command=$1
      shift
      ;;
    *) usage ;;
  esac
done
[[ -d $cwd ]] || die "--cwd is not a directory: $cwd"
case $command in
  check)
    [[ $none -eq 0 && $create_labels -eq 0 && -z $backlog$in_progress$done_label ]] || usage
    ;;
  save)
    if [[ $none -eq 1 ]]; then
      [[ $create_labels -eq 0 && -z $backlog$in_progress$done_label ]] || usage
    else
      [[ -n $backlog && -n $in_progress && -n $done_label ]] || usage
    fi
    ;;
  *) usage ;;
esac

project_root=$(wf_project_root "$cwd") || exit 2
settings=$(wf_path "$project_root" "$WF_ISSUE_TRACKING")
tracker="" cli=""

case $command in
  check)
    check_tracker
    printf '%s\n' "$tracker"
    ;;
  save)
    if [[ $none -eq 1 ]]; then
      write_settings none
    else
      save_tracker
    fi
    ;;
esac
