#!/usr/bin/env bash
# File: Helper script (not a hook): file and update a spec's or a task's tracker issue on GitLab (glab) or GitHub (gh).
# Purpose: The one place the workflow talks to the tracker about issues. The host comes from the `origin` remote through
#   wf_origin_host and must be the one .workflow/issue-tracking.yaml names; the issue flow labels come from that file.
# Usage:
#   issue-tracker.sh [--cwd <dir>] <command> [args]
#     create-spec                              create the spec's issue with a placeholder title and an empty body, in
#                                              the backlog stage; prints its URL.
#     fill <issue-url> <spec.md>               set the issue title from the file's first `# ` heading and the body to the
#                                              whole file, passed as a file.
#     create-task <spec-issue-url> <task-file> create a task's issue under the spec's issue (a GitLab child task, or a
#                                              `relates_to` linked issue when GitLab refuses the child; a GitHub
#                                              sub-issue), its body the task file, in the backlog stage; prints its URL.
#     move <issue-url> backlog|in_progress|done
#                                              remove the other flow labels and add this one; done also closes the
#                                              issue, in_progress reopens a closed one.
#     --cwd    any directory in the project or one of its worktrees. Default: $PWD.
#   An issue URL names its issue by the number in its last path segment, in the project the `origin` remote points at.
# stdout: a URL (create-spec, create-task), or `skipped: no tracker` when no tracker is set up (no settings file, or
#   `issue_tracker: none`); nothing for fill and move.
# Exit: 0 done or skipped; 1 the tracker failed (the CLI's message and what was being done, on stderr); 2 usage error,
#   not a git repository, bad settings (an unknown `issue_tracker`, a tracker without its three distinct, non-empty
#   `issue_flow` labels, or a host the `origin` remote is not on), an unreadable or headless file, or the CLI not installed.
# Called by: modules/discovery.md, modules/questioning-loop.md, modules/discovery-impact.md, modules/task-breakdown.md,
#   modules/implementation-setup.md, modules/implementation-waves.md, modules/implementation-finish.md,
#   modules/review-triage.md, modules/sign-off.md, feature-workflow/scripts/next-spec-number.sh.
# Notes: Requires git, jq, mikefarah yq v4 and the host's CLI (gh >= 2.94.0 for sub-issues). bash 3.2 compatible.
# Sources: first-party.

set -euo pipefail

SCRIPT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../../../lib/workflow-paths.sh
. "$SCRIPT_DIR/../../../lib/workflow-paths.sh"

PROG=issue-tracker.sh
# The spec has no title yet when its number is taken; fill replaces this once spec.md has its heading.
PLACEHOLDER_TITLE="New spec (title to follow)"
# GitLab files a child task only through GraphQL; the REST issues API has no parent field.
# shellcheck disable=SC2016 # the $ names are GraphQL variables, sent as written
TASK_TYPE_QUERY='query($path: ID!) { project(fullPath: $path) { workItemTypes(name: TASK) { nodes { id name } } } }'
# shellcheck disable=SC2016 # the $ names are GraphQL variables, sent as written
CREATE_TASK_MUTATION='mutation($input: WorkItemCreateInput!) {
  workItemCreate(input: $input) { workItem { id iid webUrl } errors } }'

# die MSG [CODE] : print "<prog>: MSG" to stderr and exit CODE (default 2; 1 for a tracker failure).
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit "${2:-2}"; }

# usage : print the usage lines to stderr and exit 2.
usage() {
  cat >&2 <<EOF
usage: $PROG [--cwd <dir>] create-spec
       $PROG [--cwd <dir>] fill <issue-url> <spec.md>
       $PROG [--cwd <dir>] create-task <spec-issue-url> <task-file>
       $PROG [--cwd <dir>] move <issue-url> backlog|in_progress|done
EOF
  exit 2
}

# configured_tracker SETTINGS : print the tracker the settings file SETTINGS names (gitlab, github or none), none when the
#   file is absent; exit 2 when it cannot be read, names another tracker, or gives a tracker no complete issue flow.
configured_tracker() {
  local settings=$1 tracker flow_labels
  if [[ ! -f $settings ]]; then
    echo none
    return 0
  fi
  tracker=$(yq '.issue_tracker // ""' "$settings") || die "cannot read $settings"
  case $tracker in
    none)
      echo none
      return 0
      ;;
    gitlab | github) ;;
    *) die "$settings: issue_tracker must be gitlab, github or none, not '$tracker'" ;;
  esac
  flow_labels=$(yq '[.issue_flow.backlog, .issue_flow.in_progress, .issue_flow.done]
    | map(select(tag == "!!str" and . != "")) | unique | length' "$settings") || die "cannot read issue_flow in $settings"
  [[ $flow_labels == 3 ]] ||
    die "$settings: issue_flow needs three different, non-empty labels: backlog, in_progress and done"
  echo "$tracker"
}

# absolute_path PATH : print PATH made absolute against the current folder, since the CLIs run in the project root.
absolute_path() {
  case $1 in
    /*) printf '%s\n' "$1" ;;
    *) printf '%s/%s\n' "$PWD" "$1" ;;
  esac
}

# tracker_call WHAT ARGS... : run the host's CLI with ARGS in the project and print its stdout; exit 1 naming WHAT when it
#   fails, below the CLI's own message on stderr.
tracker_call() {
  local what=$1
  shift
  (cd "$project_root" && "$cli" "$@") || die "$cli could not $what" 1
}

# json_field WHAT FILTER JSON : print the non-empty value FILTER picks from JSON; exit 1 naming WHAT when there is none.
json_field() {
  local value
  value=$(jq -r "$2 // empty" <<<"$3" 2>/dev/null) || value=""
  [[ -n $value ]] || die "$cli answered without $1: $3" 1
  printf '%s\n' "$value"
}

# issue_number URL : print the issue number in the last path segment of URL; exit 2 when it holds none.
issue_number() {
  local number=${1##*/}
  [[ $1 == *://*/* && $number =~ ^[0-9]+$ ]] || die "not an issue URL ending in its number: $1"
  printf '%s\n' "$number"
}

# first_heading FILE : print the text of FILE's first `# ` heading after any frontmatter; exit 2 when FILE cannot be read
#   or has no such heading.
first_heading() {
  local heading
  [[ -f $1 && -r $1 ]] || die "cannot read $1"
  heading=$(awk '
    NR == 1 && /^---[[:space:]]*$/ { in_frontmatter = 1; next }
    in_frontmatter { if (/^---[[:space:]]*$/) in_frontmatter = 0; next }
    /^# / { sub(/^# +/, ""); sub(/[[:space:]]+$/, ""); print; exit }
  ' "$1") || die "cannot read $1"
  [[ -n $heading ]] || die "$1 has no '# ' heading to title the issue"
  printf '%s\n' "$heading"
}

# create_spec_issue : create the spec's issue, titled PLACEHOLDER_TITLE with an empty body and the backlog label; print
#   its URL.
create_spec_issue() {
  local answer
  if [[ $cli == gh ]]; then
    answer=$(tracker_call "create the spec's issue" api 'repos/{owner}/{repo}/issues' -f "title=$PLACEHOLDER_TITLE" \
      -f "labels[]=$backlog_label") || exit 1
    json_field "the new issue's URL" .html_url "$answer"
  else
    answer=$(tracker_call "create the spec's issue" api projects/:fullpath/issues -X POST -f "title=$PLACEHOLDER_TITLE" \
      -f "labels=$backlog_label") || exit 1
    json_field "the new issue's URL" .web_url "$answer"
  fi
}

# fill_issue URL FILE : set the title of the issue at URL to FILE's first heading and its body to the whole of FILE.
fill_issue() {
  local number title file request
  number=$(issue_number "$1") || exit 2
  file=$(absolute_path "$2")
  title=$(first_heading "$file") || exit 2
  if [[ $cli == gh ]]; then
    tracker_call "fill issue #$number" issue edit "$number" --title "$title" --body-file "$file" >/dev/null || exit 1
  else
    # A JSON request file carries the body as one string, so a line opening with `[` or `{` is never read as JSON.
    request=$scratch/fill.json
    jq -n --arg title "$title" --rawfile description "$file" '{title: $title, description: $description}' >"$request" ||
      die "cannot read $file"
    tracker_call "fill issue #$number" api "projects/:fullpath/issues/$number" -X PUT \
      -H 'Content-Type: application/json' --input "$request" >/dev/null || exit 1
  fi
}

# flow_label STAGE : print the issue flow label of STAGE (backlog, in_progress or done).
flow_label() {
  case $1 in
    backlog) printf '%s\n' "$backlog_label" ;;
    in_progress) printf '%s\n' "$in_progress_label" ;;
    done) printf '%s\n' "$done_label" ;;
  esac
}

# move_issue URL STAGE : give the issue at URL the flow label of STAGE in place of the other two; done closes the issue and
#   in_progress reopens it when it is closed.
move_issue() {
  local number stage=$2 label stale_labels=() other state="" answer state_event=()
  number=$(issue_number "$1") || exit 2
  label=$(flow_label "$stage")
  for other in backlog in_progress "done"; do
    [[ $other == "$stage" ]] || stale_labels+=("$(flow_label "$other")")
  done
  if [[ $cli == gh ]]; then
    if [[ $stage == in_progress ]]; then
      state=$(tracker_call "read the state of issue #$number" issue view "$number" --json state --jq .state) || exit 1
    fi
    tracker_call "relabel issue #$number" issue edit "$number" --remove-label "${stale_labels[0]}" \
      --remove-label "${stale_labels[1]}" --add-label "$label" >/dev/null || exit 1
    if [[ $stage == "done" ]]; then
      tracker_call "close issue #$number" issue close "$number" >/dev/null || exit 1
    elif [[ $state == CLOSED ]]; then
      tracker_call "reopen issue #$number" issue reopen "$number" >/dev/null || exit 1
    fi
  else
    if [[ $stage == in_progress ]]; then
      answer=$(tracker_call "read the state of issue #$number" api "projects/:fullpath/issues/$number") || exit 1
      state=$(json_field "the issue's state" .state "$answer") || exit 1
    fi
    if [[ $stage == "done" ]]; then
      state_event=(-f state_event=close)
    elif [[ $state == closed ]]; then
      state_event=(-f state_event=reopen)
    fi
    # The labels and the state change in one request, so a failure never leaves the issue half moved. The array is
    # expanded through `+` because bash 3.2 calls an empty array unbound under `set -u`, which a move to backlog or
    # in_progress on an open issue would otherwise hit.
    tracker_call "move issue #$number to $stage" api "projects/:fullpath/issues/$number" -X PUT \
      -f "remove_labels=${stale_labels[0]},${stale_labels[1]}" -f "add_labels=$label" ${state_event[@]+"${state_event[@]}"} \
      >/dev/null || exit 1
  fi
}

# first_url : print the first URL in stdin, or nothing when it holds none.
# grep exits 1 when it finds no URL, and under `set -e` that would end the script with no message; the caller reports
# the missing URL instead.
first_url() { grep -Eo 'https?://[^[:space:]]+' | head -n 1 || true; }

# create_github_task SPEC_NUMBER TITLE FILE : create a sub-issue of issue SPEC_NUMBER titled TITLE, its body FILE, in the
#   backlog stage; print its URL.
create_github_task() {
  local answer url
  answer=$(tracker_call "create a sub-issue of issue #$1" issue create --title "$2" --body-file "$3" \
    --label "$backlog_label" --parent "$1") || exit 1
  url=$(first_url <<<"$answer")
  [[ -n $url ]] || die "gh created a sub-issue of issue #$1 but printed no URL: $answer" 1
  printf '%s\n' "$url"
}

# child_graphql WHAT ARGS... : run `glab api graphql ARGS` in the project and print GitLab's answer, adding glab's message
#   to CHILD_REFUSAL. glab exits non-zero when GitLab refuses with GraphQL `errors` yet still prints that answer, so such
#   an answer is printed like any other. Exit 1 naming WHAT, below glab's message, when no GitLab answer comes back, as on
#   a timeout or a lost login.
child_graphql() {
  local what=$1 answer status=0 glab_message=$scratch/graphql-stderr
  shift
  answer=$(cd "$project_root" && glab api graphql "$@" 2>"$glab_message") || status=$?
  if [[ $status != 0 ]] && ! jq -e 'type == "object" and has("errors")' <<<"$answer" >/dev/null 2>&1; then
    cat "$glab_message" >&2
    die "glab could not $what" 1
  fi
  cat "$glab_message" >>"$CHILD_REFUSAL" || die "cannot write $CHILD_REFUSAL"
  printf '%s\n' "$answer"
}

# create_child_task PROJECT_PATH PARENT_ID TITLE FILE : create a GitLab task titled TITLE, its description FILE, as a child
#   of the work item with global id PARENT_ID in project PROJECT_PATH; print its URL. Print nothing, with GitLab's answer
#   in CHILD_REFUSAL, when the project has no task type or GitLab refuses the task; exit 1 when the call itself fails.
create_child_task() {
  local types type_id request answer url
  types=$(child_graphql "read the project's work item types" -f "query=$TASK_TYPE_QUERY" -f "path=$1") || exit 1
  type_id=$(jq -r '[.data.project.workItemTypes.nodes[]? | select(.name == "Task") | .id][0] // empty' <<<"$types") ||
    die "glab answered the work item types query with no JSON: $types" 1
  if [[ -z $type_id ]]; then
    printf 'the project has no Task work item type: %s\n' "$types" >>"$CHILD_REFUSAL" || die "cannot write $CHILD_REFUSAL"
    return 0
  fi
  request=$scratch/child-task.json
  jq -n --arg query "$CREATE_TASK_MUTATION" --arg path "$1" --arg parent "gid://gitlab/WorkItem/$2" --arg title "$3" \
    --rawfile description "$4" --arg type "$type_id" \
    '{query: $query, variables: {input: {namespacePath: $path, title: $title, workItemTypeId: $type,
      descriptionWidget: {description: $description}, hierarchyWidget: {parentId: $parent}}}}' >"$request" ||
    die "cannot read $4"
  answer=$(child_graphql "create a child task under work item $2" -H 'Content-Type: application/json' --input "$request") ||
    exit 1
  url=$(jq -r 'if (.errors // []) == [] and (.data.workItemCreate.errors // []) == []
    then .data.workItemCreate.workItem.webUrl // empty else empty end' <<<"$answer") ||
    die "glab answered the child task request with no JSON: $answer" 1
  if [[ -z $url ]]; then
    printf '%s\n' "$answer" >>"$CHILD_REFUSAL" || die "cannot write $CHILD_REFUSAL"
    return 0
  fi
  printf '%s\n' "$url"
}

# create_linked_issue PROJECT_ID SPEC_NUMBER TITLE FILE : create a GitLab issue titled TITLE, its description FILE, in the
#   backlog stage, linked relates_to issue SPEC_NUMBER of project PROJECT_ID; print its URL.
create_linked_issue() {
  local request=$scratch/linked-issue.json answer url number
  jq -n --arg title "$3" --rawfile description "$4" --arg labels "$backlog_label" \
    '{title: $title, description: $description, labels: $labels}' >"$request" || die "cannot read $4"
  answer=$(tracker_call "create the task's issue" api projects/:fullpath/issues -X POST \
    -H 'Content-Type: application/json' --input "$request") || exit 1
  url=$(json_field "the new issue's URL" .web_url "$answer") || exit 1
  number=$(json_field "the new issue's number" .iid "$answer") || exit 1
  tracker_call "link the new issue $url to issue #$2" api "projects/:fullpath/issues/$number/links" -X POST \
    -f "target_project_id=$1" -f "target_issue_iid=$2" -f link_type=relates_to >/dev/null || exit 1
  printf '%s\n' "$url"
}

# create_gitlab_task SPEC_NUMBER TITLE FILE : create a child task of issue SPEC_NUMBER titled TITLE, its description FILE,
#   in the backlog stage, or a linked issue when GitLab refuses the child; print its URL.
create_gitlab_task() {
  local project project_path project_id spec_issue spec_id url number
  project=$(tracker_call "read the project" api projects/:fullpath) || exit 1
  project_path=$(json_field "the project's path" .path_with_namespace "$project") || exit 1
  project_id=$(json_field "the project's id" .id "$project") || exit 1
  spec_issue=$(tracker_call "read issue #$1" api "projects/:fullpath/issues/$1") || exit 1
  spec_id=$(json_field "the id of issue #$1" .id "$spec_issue") || exit 1
  CHILD_REFUSAL=$scratch/child-refusal
  url=$(create_child_task "$project_path" "$spec_id" "$2" "$3") || exit 1
  if [[ -n $url ]]; then
    number=$(issue_number "$url") || exit 1
    tracker_call "add the backlog label to the new task $url" api "projects/:fullpath/issues/$number" -X PUT \
      -f "add_labels=$backlog_label" >/dev/null || exit 1
  else
    printf '%s: GitLab refused a child task under issue #%s, so the task gets an issue linked to it instead: %s\n' \
      "$PROG" "$1" "$(head -n 1 "$CHILD_REFUSAL" 2>/dev/null)" >&2
    url=$(create_linked_issue "$project_id" "$1" "$2" "$3") || exit 1
  fi
  printf '%s\n' "$url"
}

# create_task_issue SPEC_URL FILE : create the issue of the task in FILE under the spec's issue at SPEC_URL; print its URL.
create_task_issue() {
  local spec_number title file
  spec_number=$(issue_number "$1") || exit 2
  file=$(absolute_path "$2")
  title=$(first_heading "$file") || exit 2
  if [[ $cli == gh ]]; then
    create_github_task "$spec_number" "$title" "$file"
  else
    create_gitlab_task "$spec_number" "$title" "$file"
  fi
}

cwd=$PWD
args=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --cwd)
      [[ $# -ge 2 ]] || usage
      cwd=$2
      shift 2
      ;;
    -h | --help) usage ;;
    -*) usage ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done
[[ -d $cwd ]] || die "--cwd is not a directory: $cwd"
[[ ${#args[@]} -ge 1 ]] || usage

command=${args[0]}
case $command in
  create-spec) [[ ${#args[@]} -eq 1 ]] || usage ;;
  fill | create-task) [[ ${#args[@]} -eq 3 ]] || usage ;;
  move)
    [[ ${#args[@]} -eq 3 ]] || usage
    case ${args[2]} in
      backlog | in_progress | done) ;;
      *) usage ;;
    esac
    ;;
  *) usage ;;
esac

project_root=$(wf_project_root "$cwd") || exit 2
settings=$(wf_path "$project_root" "$WF_ISSUE_TRACKING")
tracker=$(configured_tracker "$settings") || exit 2
if [[ $tracker == none ]]; then
  echo "skipped: no tracker"
  exit 0
fi

origin_host=$(wf_origin_host "$project_root")
[[ $origin_host == "$tracker" ]] ||
  die "$settings names $tracker, but the origin remote is not on $tracker${origin_host:+ (it is on $origin_host)}"

case $tracker in
  github) cli=gh ;;
  gitlab) cli=glab ;;
esac
command -v "$cli" >/dev/null || die "$cli is not installed; it is needed to reach the $tracker tracker"
backlog_label=$(yq '.issue_flow.backlog' "$settings") || die "cannot read issue_flow in $settings"
in_progress_label=$(yq '.issue_flow.in_progress' "$settings") || die "cannot read issue_flow in $settings"
done_label=$(yq '.issue_flow.done' "$settings") || die "cannot read issue_flow in $settings"
scratch=$(mktemp -d "${TMPDIR:-/tmp}/issue-tracker.XXXXXX") || die "cannot make a scratch folder"
trap 'rm -rf "$scratch"' EXIT

case $command in
  create-spec) create_spec_issue ;;
  fill) fill_issue "${args[1]}" "${args[2]}" ;;
  create-task) create_task_issue "${args[1]}" "${args[2]}" ;;
  move) move_issue "${args[1]}" "${args[2]}" ;;
esac
