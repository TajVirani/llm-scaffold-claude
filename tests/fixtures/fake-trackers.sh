#!/usr/bin/env bash
# File: Fake gh and glab for the tracker suites (next-spec-number, issue-tracking, issue-tracking-setup, tracker-adoption).
#   Sourced after lib/common.sh, and by the fake executables themselves; defines variables and functions only. bash 3.2
#   compatible. No call reaches a network: the fakes keep a small tracker of their own in a state folder.
# Provides, for the suites:
#   fake_trackers_install DIR   writes the fakes and a tools folder under DIR and an empty tracker state; sets and exports
#                               FAKE_TRACKER_DIR=DIR, and sets FAKE_BIN (gh and glab), FAKE_BIN_GH (gh only), FAKE_BIN_GLAB
#                               (glab only) and FAKE_TOOLS (links to the system tools the scripts need, and no gh or glab)
#   fake_path [gh|glab|both|none] prints a PATH for a script run: the named fakes first, then the caller's PATH for both,
#                               or only FAKE_TOOLS for gh, glab and none, so a real gh or glab installed on the machine is out
#                               of reach and "the CLI is missing" can be staged
#   fake_trackers_reset         forgets every issue, label and call, keeping the fakes
#   fake_label_seed LABEL...    the project's labels exist on the tracker
#   fake_issue_seed N TITLE STATE [LABEL...]   issue N exists with that title, state (open or closed) and labels
#   fake_run PATH CMD...        runs CMD with that PATH and git transports limited to local files; sets OUT, ERR and RC
#   fake_call_count             number of calls the fakes answered
#   fake_cli_call_count gh|glab number of calls to that fake
#   fake_calls                  every recorded call, one line each (`<cli> <quoted args>`), for failure details
#   fake_issue_numbers          the numbers of the issues on the tracker, ascending
#   fake_issue N FIELD          one field of issue N: title, body, state (open|closed), parent (a number or empty), kind
#                               (issue|task), labels (one per line, sorted) or links (`relates_to <n>` lines, sorted)
#   fake_label_names            the project's labels, one per line, sorted
#   fake_url gh|glab N          the URL the fake gives issue N on that host
#   TRACKER_ORIGIN_GITLAB, TRACKER_ORIGIN_GITHUB, TRACKER_ORIGIN_OTHER   `origin` URLs on GitLab, on GitHub and on neither
#   TRACKER_BACKLOG, TRACKER_IN_PROGRESS, TRACKER_DONE   the issue flow labels the fixtures agree on
#   TRACKER_GITIGNORE           the local workflow state ignore block install.sh writes
#   tracker_project DIR [gitlab|github|other|none]   git repo on main with a committed copy of .agents/, the ignore block and
#                               an `origin` remote on that host (default gitlab; none adds no remote)
#   tracker_settings DIR gitlab|github|none   writes DIR/.workflow/issue-tracking.yaml for that host and the three flow labels
# Answered call shapes (anything else exits 1 with a not-found message, so an unplanned call fails loudly):
#   both: `--version` and `version`; `auth status`; `label list` (`--json name`, `-F json`, `--output json`); `label create`
#     (an existing label is refused); `issue create`, `issue edit` (gh) / `issue update` (glab), `issue close`,
#     `issue reopen`, `issue view` (JSON with `--json` / `-F json` / `--output json`). An issue is named by its number,
#     `#N` or its URL.
#   gh: `repo view --json hasIssuesEnabled`; `issue create --title --body|--body-file --label --parent`; `issue edit
#     --title --body|--body-file --add-label --remove-label`; `--jq`/`-q` on `api`, `repo view`, `issue view` and
#     `label list`. A label must exist before gh adds it. `api` with -X/--method, -f/--raw-field, -F/--field (`@file`,
#     `@-`), --input, -H: repos/O/R; repos/O/R/issues (POST creates); repos/O/R/issues/N (GET, PATCH title, body, state,
#     labels); repos/O/R/issues/N/labels (POST, PUT) and .../labels/NAME (DELETE); repos/O/R/issues/N/sub_issues (POST
#     sub_issue_id, the child's REST id); repos/O/R/labels (GET, POST); user. REST ids are 1000000 + the number.
#   glab: `issue create --title --description|--description-file --label --linked-issues --link-type`; `issue update
#     --title --description|--description-file --label --unlabel`. Labels added to an issue are created on the fly, as on
#     GitLab. `api` with -X/--method, -f/--raw-field, -F/--field (`@file`, `@-`), --input, -H: projects/P (GET, with
#     issues_access_level); projects/P/issues (POST creates); projects/P/issues/N (GET, PUT title, description,
#     add_labels, remove_labels, labels, state_event); projects/P/issues/N/links (POST target_issue_iid, link_type);
#     projects/P/labels (GET, POST); user; graphql. REST ids are 5000 + the number, so issue N is
#     gid://gitlab/Issue/<5000+N> and gid://gitlab/WorkItem/<5000+N>.
#   glab graphql: the query and its variables come from the fields (`query` plus the rest) or from --input
#     ({"query", "variables"}). workItemCreate makes a task (title, description and hierarchyWidget parentId from the
#     variables or the query text); workItemUpdate with hierarchyWidget parentId sets the parent of its id, and with
#     childrenIds sets its id as the parent of each child; workItemTypes lists Issue and Task; any other query is answered
#     with the project id and, for an iid it names, that issue as workItem, workItems, issue and issues nodes.
# Read by the fakes at call time:
#   FAKE_ISSUE_NUMBER   the number the first new issue gets (default 1); each later one takes the highest number plus one
#   FAKE_FAIL           network | auth: every call but `--version` fails with exit 1 and that kind of message
#   FAKE_AUTH           logged-out: `auth status` exits 1 saying no one is logged in
#   FAKE_ISSUES         disabled: the project has its issues turned off
#   FAKE_GRAPHQL        refuse: a graphql mutation that creates a work item or sets a parent is refused with exit 1
#   FAKE_GH_VERSION, FAKE_GLAB_VERSION   the versions `--version` reports (defaults 2.99.0 and 1.127.0)
# A fake reads stdin only when an argument names it (`-` after a file flag, `@-`), so a call never waits on a terminal.
# shellcheck disable=SC2034  # FAKE_BIN* and the run results are read by the suites that source this file

FAKE_TRACKERS_SOURCE=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")
FAKE_GH_BASE=https://github.com/acme/widget
FAKE_GLAB_BASE=https://gitlab.com/acme/widget
FAKE_TOOL_NAMES="bash sh env cat sed awk grep head tail tr cut sort uniq wc mktemp rm mv cp ln mkdir rmdir ls find xargs
  date basename dirname cmp diff comm touch chmod tee uname readlink realpath id paste od stat seq sleep printf test true
  false expr git
  yq jq"
TRACKER_ORIGIN_GITLAB=https://gitlab.com/acme/widget.git
TRACKER_ORIGIN_GITHUB=https://github.com/acme/widget.git
TRACKER_ORIGIN_OTHER=https://git.example.invalid/acme/widget.git
TRACKER_BACKLOG=Backlog
TRACKER_IN_PROGRESS="In progress"
TRACKER_DONE=Done
TRACKER_GITIGNORE='.workflow/specs/*/.step
.workflow/initiatives/*/.step
.workflow/.worktrees/
.workflow/.spec-worktrees/
.workflow/.handoff/
.workflow/.standards-staging/'

# ---------------------------------------------------------------- suite helpers

fake_trackers_install() {
  local dir=$1 cli tool found
  mkdir -p "$dir/bin" "$dir/bin-gh" "$dir/bin-glab" "$dir/tools"
  for cli in gh glab; do
    printf '#!/usr/bin/env bash\nFAKE_TRACKER_DIR=%q\n. %q\nfake_tracker_main %s "$@"\n' \
      "$dir" "$FAKE_TRACKERS_SOURCE" "$cli" >"$dir/bin/$cli"
    chmod +x "$dir/bin/$cli"
    cp "$dir/bin/$cli" "$dir/bin-$cli/$cli"
  done
  for tool in $FAKE_TOOL_NAMES; do
    found=$(type -P "$tool" 2>/dev/null) || continue
    ln -sf "$found" "$dir/tools/$tool"
  done
  FAKE_TRACKER_DIR=$dir
  FAKE_BIN=$dir/bin
  FAKE_BIN_GH=$dir/bin-gh
  FAKE_BIN_GLAB=$dir/bin-glab
  FAKE_TOOLS=$dir/tools
  export FAKE_TRACKER_DIR
  fake_trackers_reset
}

fake_path() {
  case ${1:-both} in
    both) printf '%s:%s' "$FAKE_BIN" "$PATH" ;;
    gh) printf '%s:%s' "$FAKE_BIN_GH" "$FAKE_TOOLS" ;;
    glab) printf '%s:%s' "$FAKE_BIN_GLAB" "$FAKE_TOOLS" ;;
    none) printf '%s' "$FAKE_TOOLS" ;;
  esac
}

fake_trackers_reset() {
  rm -rf "$FAKE_TRACKER_DIR/issues" "$FAKE_TRACKER_DIR/scratch"
  mkdir -p "$FAKE_TRACKER_DIR/issues" "$FAKE_TRACKER_DIR/scratch"
  : >"$FAKE_TRACKER_DIR/labels"
  : >"$FAKE_TRACKER_DIR/calls.log"
}

fake_label_seed() {
  local label
  for label in "$@"; do ft_project_add_label "$label"; done
}

fake_issue_seed() {
  local n=$1 title=$2 state=$3 label
  shift 3
  ft_issue_create_at "$n" "$title" "" issue
  printf '%s' "$state" >"$FAKE_TRACKER_DIR/issues/$n/state"
  for label in "$@"; do
    ft_project_add_label "$label"
    ft_issue_add_label "$n" "$label"
  done
}

fake_run() {
  local path=$1
  shift
  OUT=$(env PATH="$path" GIT_ALLOW_PROTOCOL=file GIT_TERMINAL_PROMPT=0 "$@" 2>"$FAKE_TRACKER_DIR/scratch/stderr" </dev/null)
  RC=$?
  ERR=$(cat "$FAKE_TRACKER_DIR/scratch/stderr")
}

fake_call_count() { wc -l <"$FAKE_TRACKER_DIR/calls.log" | tr -d ' '; }

fake_cli_call_count() { grep -c "^$1 " "$FAKE_TRACKER_DIR/calls.log" | tr -d ' '; }

fake_calls() { cat "$FAKE_TRACKER_DIR/calls.log"; }

fake_issue_numbers() {
  local d
  for d in "$FAKE_TRACKER_DIR"/issues/*/; do
    [[ -d $d ]] && basename "$d"
  done | sort -n
}

fake_issue() {
  local file=$FAKE_TRACKER_DIR/issues/$1/$2
  [[ -f $file ]] || return 0
  case $2 in
    labels | links) LC_ALL=C sort "$file" ;;
    *) cat "$file" ;;
  esac
}

fake_label_names() { LC_ALL=C sort "$FAKE_TRACKER_DIR/labels"; }

fake_url() {
  case $1 in
    gh) printf '%s/issues/%s' "$FAKE_GH_BASE" "$2" ;;
    glab) printf '%s/-/issues/%s' "$FAKE_GLAB_BASE" "$2" ;;
  esac
}

tracker_project() {
  local dir=$1
  git_init_repo "$dir"
  copy_agents "$dir"
  printf '%s\n' "$TRACKER_GITIGNORE" >"$dir/.gitignore"
  mkdir -p "$dir/.workflow/specs"
  case ${2:-gitlab} in
    gitlab) git -C "$dir" remote add origin "$TRACKER_ORIGIN_GITLAB" ;;
    github) git -C "$dir" remote add origin "$TRACKER_ORIGIN_GITHUB" ;;
    other) git -C "$dir" remote add origin "$TRACKER_ORIGIN_OTHER" ;;
  esac
  git_commit_all "$dir" "fixture: tracker project"
}

tracker_settings() {
  mkdir -p "$1/.workflow"
  if [[ $2 == none ]]; then
    printf 'issue_tracker: none\n' >"$1/.workflow/issue-tracking.yaml"
  else
    printf 'issue_tracker: %s\nissue_flow:\n  backlog: "%s"\n  in_progress: "%s"\n  done: "%s"\n' \
      "$2" "$TRACKER_BACKLOG" "$TRACKER_IN_PROGRESS" "$TRACKER_DONE" >"$1/.workflow/issue-tracking.yaml"
  fi
}

# ---------------------------------------------------------------- tracker state

# ft_issue_create_at N TITLE BODY KIND : issue N exists, open, with no labels.
ft_issue_create_at() {
  local dir=$FAKE_TRACKER_DIR/issues/$1
  mkdir -p "$dir"
  printf '%s' "$2" >"$dir/title"
  printf '%s' "$3" >"$dir/body"
  printf '%s' "$4" >"$dir/kind"
  printf open >"$dir/state"
  : >"$dir/labels"
  : >"$dir/links"
  : >"$dir/parent"
}

# ft_next_number : the number the next new issue takes.
ft_next_number() {
  local highest first=${FAKE_ISSUE_NUMBER:-1}
  highest=$(fake_issue_numbers | tail -1)
  highest=${highest:-0}
  [[ $highest -ge $((first - 1)) ]] || highest=$((first - 1))
  echo $((highest + 1))
}

# ft_issue_exists N : true when issue N is on the tracker.
ft_issue_exists() { [[ -n $1 && -d $FAKE_TRACKER_DIR/issues/$1 ]]; }

# ft_has_line FILE LINE : true when FILE holds LINE exactly.
ft_has_line() { [[ -f $1 ]] && grep -Fxq -- "$2" "$1"; }

ft_project_add_label() { ft_has_line "$FAKE_TRACKER_DIR/labels" "$1" || printf '%s\n' "$1" >>"$FAKE_TRACKER_DIR/labels"; }

ft_issue_add_label() {
  local file=$FAKE_TRACKER_DIR/issues/$1/labels
  ft_has_line "$file" "$2" || printf '%s\n' "$2" >>"$file"
}

ft_issue_remove_label() {
  local file=$FAKE_TRACKER_DIR/issues/$1/labels
  grep -Fxv -- "$2" "$file" >"$file.new" || true
  mv "$file.new" "$file"
}

# ft_issue_link N M TYPE : N and M are linked, each naming the other.
ft_issue_link() {
  printf '%s %s\n' "$3" "$2" >>"$FAKE_TRACKER_DIR/issues/$1/links"
  printf '%s %s\n' "$3" "$1" >>"$FAKE_TRACKER_DIR/issues/$2/links"
}

# ft_issue_ref REF : the issue number in REF (N, #N or a URL ending in the number); empty when there is none.
ft_issue_ref() {
  local ref=${1%%[?]*}
  ref=${ref%/}
  ref=${ref##*/}
  ref=${ref##*#}
  [[ $ref =~ ^[0-9]+$ ]] && echo "$ref"
}

# ft_labels_json N : the labels of issue N as a JSON array of names.
ft_labels_json() { jq -Rn '[inputs | select(length > 0)]' <"$FAKE_TRACKER_DIR/issues/$1/labels"; }

# ft_issue_json HOST N : issue N as that host's REST API returns it.
ft_issue_json() {
  local dir=$FAKE_TRACKER_DIR/issues/$2 labels
  labels=$(ft_labels_json "$2")
  if [[ $1 == gh ]]; then
    jq -n --argjson n "$2" --rawfile title "$dir/title" --rawfile body "$dir/body" --rawfile state "$dir/state" \
      --argjson labels "$labels" --arg url "$(fake_url gh "$2")" \
      '{number: $n, id: (1000000 + $n), node_id: "I_kwFAKE\($n)", title: $title, body: $body, state: $state,
        labels: [$labels[] | {name: .}], html_url: $url, url: "https://api.github.com/repos/acme/widget/issues/\($n)"}'
  else
    jq -n --argjson n "$2" --rawfile title "$dir/title" --rawfile body "$dir/body" --rawfile state "$dir/state" \
      --argjson labels "$labels" --arg url "$(fake_url glab "$2")" \
      '{iid: $n, id: (5000 + $n), project_id: 77, title: $title, description: $body,
        state: (if $state == "closed" then "closed" else "opened" end), labels: $labels, web_url: $url,
        references: {short: "#\($n)"}}'
  fi
}

# ---------------------------------------------------------------- the fake CLIs

# fake_tracker_main CLI ARGS... : answer one gh or glab call against the tracker state in FAKE_TRACKER_DIR.
fake_tracker_main() {
  FT_CLI=$1
  shift
  FT_SCRATCH=$(mktemp -d "$FAKE_TRACKER_DIR/scratch/call.XXXXXX") || exit 1
  {
    printf '%s' "$FT_CLI"
    printf ' %q' "$@"
    printf '\n'
  } >>"$FAKE_TRACKER_DIR/calls.log"
  case ${1:-} in
    --version | version)
      ft_version
      return
      ;;
  esac
  ft_injected_failure
  if [[ $FT_CLI == gh ]]; then ft_gh "$@"; else ft_glab "$@"; fi
}

ft_version() {
  if [[ $FT_CLI == gh ]]; then
    printf 'gh version %s (2026-10-01)\nhttps://github.com/cli/cli/releases/tag/v%s\n' "${FAKE_GH_VERSION:-2.99.0}" \
      "${FAKE_GH_VERSION:-2.99.0}"
  else
    printf 'glab %s (2026-11-02)\n' "${FAKE_GLAB_VERSION:-1.127.0}"
  fi
}

# ft_injected_failure : exit 1 with a network or auth error when FAKE_FAIL asks for one.
ft_injected_failure() {
  case ${FAKE_FAIL:-} in
    network)
      if [[ $FT_CLI == gh ]]; then
        printf 'error connecting to api.github.com\ncheck your internet connection or https://githubstatus.com\n' >&2
      else
        printf 'dial tcp: lookup gitlab.com: no such host\n' >&2
      fi
      exit 1
      ;;
    auth)
      if [[ $FT_CLI == gh ]]; then
        printf 'HTTP 401: Bad credentials (https://api.github.com/graphql)\nTry authenticating with:  gh auth login\n' >&2
      else
        printf '401 Unauthorized: the token is invalid or expired; run glab auth login\n' >&2
      fi
      exit 1
      ;;
  esac
}

ft_not_found() {
  printf '%s: Not Found (HTTP 404): %s\n' "$FT_CLI" "$*" >&2
  exit 1
}

ft_fail() {
  printf '%s: %s\n' "$FT_CLI" "$1" >&2
  exit 1
}

# ft_parse VALUE_FLAGS ARGS... : split ARGS into FT_POS and the parallel FT_FLAG_NAMES / FT_FLAG_VALUES; a flag named in
#   the space-separated VALUE_FLAGS takes the next argument, `--name=value` always carries its value.
ft_parse() {
  local value_flags=" $1 "
  shift
  FT_POS=() FT_FLAG_NAMES=() FT_FLAG_VALUES=()
  while [[ $# -gt 0 ]]; do
    case $1 in
      --*=*)
        FT_FLAG_NAMES+=("${1%%=*}")
        FT_FLAG_VALUES+=("${1#*=}")
        ;;
      -?*)
        if [[ $value_flags == *" $1 "* ]]; then
          FT_FLAG_NAMES+=("$1")
          FT_FLAG_VALUES+=("${2:-}")
          shift
        else
          FT_FLAG_NAMES+=("$1")
          FT_FLAG_VALUES+=("")
        fi
        ;;
      *) FT_POS+=("$1") ;;
    esac
    shift
  done
}

# ft_flag NAME... : the last value given to any of the flag NAMEs; status 1 when none was given.
ft_flag() {
  local i found=1 value="" name
  for ((i = 0; i < ${#FT_FLAG_NAMES[@]}; i++)); do
    for name in "$@"; do
      if [[ ${FT_FLAG_NAMES[i]} == "$name" ]]; then
        value=${FT_FLAG_VALUES[i]}
        found=0
      fi
    done
  done
  printf '%s' "$value"
  return $found
}

# ft_flag_all NAME... : every value given to the flag NAMEs, split on commas, one per line.
ft_flag_all() {
  local i name
  for ((i = 0; i < ${#FT_FLAG_NAMES[@]}; i++)); do
    for name in "$@"; do
      [[ ${FT_FLAG_NAMES[i]} == "$name" ]] && printf '%s\n' "${FT_FLAG_VALUES[i]}" | tr ',' '\n'
    done
  done | sed -e 's/^ *//' -e 's/ *$//' | grep -v '^$' || true
}

# ft_has_flag NAME... : true when any of the flag NAMEs was given.
ft_has_flag() { ft_flag "$@" >/dev/null; }

# ft_read_into FILE SOURCE : copy SOURCE (a path, or - for stdin) into FILE; a missing path fails like the real CLI.
ft_read_into() {
  if [[ $2 == - ]]; then
    cat >"$1"
    cp "$1" "$FT_SCRATCH/stdin"
  else
    [[ -f $2 ]] || ft_fail "open $2: no such file or directory"
    cat "$2" >"$1"
  fi
}

# ft_output JSON : print JSON, through the --jq / -q filter when one was given.
ft_output() {
  local filter
  if filter=$(ft_flag --jq -q); then
    jq -r "$filter" <<<"$1"
  else
    printf '%s\n' "$1"
  fi
}

# ft_issue_arg : the issue number named by the first positional argument after the subcommand; fails when it is absent.
ft_issue_arg() {
  local n
  n=$(ft_issue_ref "${FT_POS[0]:-}")
  ft_issue_exists "$n" || ft_fail "issue ${FT_POS[0]:-<none>} not found"
  echo "$n"
}

ft_auth_status() {
  if [[ ${FAKE_AUTH:-} == logged-out ]]; then
    if [[ $FT_CLI == gh ]]; then
      printf 'You are not logged into any GitHub hosts. To log in, run: gh auth login\n' >&2
    else
      printf 'gitlab.com\n  x gitlab.com: no token found; run glab auth login\n' >&2
    fi
    exit 1
  fi
  if [[ $FT_CLI == gh ]]; then
    printf 'github.com\n  - Logged in to github.com account tester (keyring)\n'
  else
    printf 'gitlab.com\n  - Logged in to gitlab.com as tester\n' >&2
  fi
}

# ft_new_issue TITLE BODY_FILE KIND : create the next issue and print its number.
ft_new_issue() {
  local n
  [[ -n $1 ]] || ft_fail "title can't be blank"
  n=$(ft_next_number)
  ft_issue_create_at "$n" "$1" "" "$3"
  cat "$2" >"$FAKE_TRACKER_DIR/issues/$n/body"
  echo "$n"
}

# ft_add_labels N STRICT LABEL... : add each label to issue N; with STRICT=1 a label the project lacks fails the call,
#   otherwise it is created.
ft_add_labels() {
  local n=$1 strict=$2 label
  shift 2
  for label in "$@"; do
    if ! ft_has_line "$FAKE_TRACKER_DIR/labels" "$label"; then
      [[ $strict -eq 0 ]] || ft_fail "could not add label: '$label' not found"
      ft_project_add_label "$label"
    fi
    ft_issue_add_label "$n" "$label"
  done
}

# ft_lines_to_args : read lines on stdin into FT_LINES.
ft_lines_to_args() {
  local line
  FT_LINES=()
  while IFS= read -r line; do FT_LINES+=("$line"); done
}

# ft_label_list_output JSON_WANTED : print the project's labels as JSON names or as plain lines.
ft_label_list_output() {
  if [[ $1 -eq 1 ]]; then
    ft_output "$(jq -Rn '[inputs | select(length > 0) | {name: .}]' <"$FAKE_TRACKER_DIR/labels")"
  elif [[ $FT_CLI == gh ]]; then
    awk 'length { printf "%s\t\t#ededed\n", $0 }' "$FAKE_TRACKER_DIR/labels"
  else
    cat "$FAKE_TRACKER_DIR/labels"
  fi
}

ft_label_create() {
  [[ -n $1 ]] || ft_fail "label name required"
  if ft_has_line "$FAKE_TRACKER_DIR/labels" "$1"; then
    ft_fail "label with name \"$1\" already exists"
  fi
  ft_project_add_label "$1"
}

# ---------------------------------------------------------------- gh

ft_gh() {
  local group=${1:-} sub=${2:-}
  case "$group $sub" in
    "auth status") ft_auth_status ;;
    "auth token") echo gho_fake ;;
    "repo view")
      shift 2
      ft_parse "--json -q --jq -R --repo" "$@"
      ft_gh_repo_view
      ;;
    "issue create" | "issue edit" | "issue close" | "issue reopen" | "issue view")
      shift 2
      ft_parse "-t --title -b --body -F --body-file -l --label --add-label --remove-label --parent -R --repo --json -q
        --jq -c --comment -r --reason -a --assignee -m --milestone" "$@"
      "ft_gh_issue_$sub"
      ;;
    "label list" | "label create")
      shift 2
      ft_parse "--json -q --jq -L --limit -c --color -d --description -R --repo" "$@"
      if [[ $sub == list ]]; then
        if ft_has_flag --json; then ft_label_list_output 1; else ft_label_list_output 0; fi
      else
        ft_label_create "${FT_POS[0]:-}"
      fi
      ;;
    api*)
      shift
      ft_parse "-X --method -f --raw-field -F --field -H --header --input -q --jq --hostname -p --preview" "$@"
      ft_gh_api
      ;;
    *) ft_not_found "gh $*" ;;
  esac
}

ft_gh_repo_view() {
  local enabled=true json fields
  [[ ${FAKE_ISSUES:-} != disabled ]] || enabled=false
  json=$(jq -n --argjson enabled "$enabled" \
    '{hasIssuesEnabled: $enabled, nameWithOwner: "acme/widget", name: "widget", owner: {login: "acme"},
      url: "https://github.com/acme/widget"}')
  if fields=$(ft_flag --json); then
    json=$(jq --arg f "$fields" '. as $all | reduce ($f | split(",")[]) as $k ({}; .[$k] = $all[$k])' <<<"$json")
    ft_output "$json"
  else
    printf 'acme/widget\n'
  fi
}

ft_gh_issue_create() {
  local title body=$FT_SCRATCH/body n parent source
  title=$(ft_flag -t --title) || ft_fail "must provide --title when not running interactively"
  : >"$body"
  if source=$(ft_flag -F --body-file); then
    ft_read_into "$body" "$source"
  else
    ft_flag -b --body >"$body" || true
  fi
  ft_lines_to_args < <(ft_flag_all -l --label)
  if parent=$(ft_flag --parent); then
    parent=$(ft_issue_ref "$parent")
    ft_issue_exists "$parent" || ft_fail "parent issue not found"
  fi
  n=$(ft_new_issue "$title" "$body" issue) || exit 1
  [[ -z $parent ]] || printf '%s' "$parent" >"$FAKE_TRACKER_DIR/issues/$n/parent"
  [[ ${#FT_LINES[@]} -eq 0 ]] || ft_add_labels "$n" 1 "${FT_LINES[@]}"
  printf 'Creating issue in acme/widget\n\n' >&2
  fake_url gh "$n"
  echo
}

ft_gh_issue_edit() {
  local n value source label
  n=$(ft_issue_arg) || exit 1
  if value=$(ft_flag -t --title); then printf '%s' "$value" >"$FAKE_TRACKER_DIR/issues/$n/title"; fi
  if source=$(ft_flag -F --body-file); then
    ft_read_into "$FAKE_TRACKER_DIR/issues/$n/body" "$source"
  elif value=$(ft_flag -b --body); then
    printf '%s' "$value" >"$FAKE_TRACKER_DIR/issues/$n/body"
  fi
  while IFS= read -r label; do ft_issue_remove_label "$n" "$label"; done < <(ft_flag_all --remove-label)
  ft_lines_to_args < <(ft_flag_all --add-label)
  [[ ${#FT_LINES[@]} -eq 0 ]] || ft_add_labels "$n" 1 "${FT_LINES[@]}"
  fake_url gh "$n"
  echo
}

ft_gh_issue_close() {
  local n
  n=$(ft_issue_arg) || exit 1
  printf closed >"$FAKE_TRACKER_DIR/issues/$n/state"
  printf 'Closed issue acme/widget#%s\n' "$n" >&2
}

ft_gh_issue_reopen() {
  local n
  n=$(ft_issue_arg) || exit 1
  printf open >"$FAKE_TRACKER_DIR/issues/$n/state"
  printf 'Reopened issue acme/widget#%s\n' "$n" >&2
}

ft_gh_issue_view() {
  local n json
  n=$(ft_issue_arg) || exit 1
  json=$(ft_issue_json gh "$n" | jq '{number, title, body, url: .html_url, labels: [.labels[] | {name}],
    state: (.state | ascii_upcase)}')
  ft_output "$json"
}

# ft_request_json : the request body of an api call as JSON, from --input or from the -f / -F fields.
ft_request_json() {
  local i name field key value req=$FT_SCRATCH/request.json source
  if source=$(ft_flag --input); then
    ft_read_into "$req" "$source"
    jq . "$req" >/dev/null 2>&1 || ft_fail "--input is not JSON"
    cat "$req"
    return
  fi
  echo '{}' >"$req"
  for ((i = 0; i < ${#FT_FLAG_NAMES[@]}; i++)); do
    name=${FT_FLAG_NAMES[i]}
    field=${FT_FLAG_VALUES[i]}
    [[ $name == -f || $name == --raw-field || $name == -F || $name == --field ]] || continue
    key=${field%%=*}
    value=${field#*=}
    if [[ ($name == -F || $name == --field) && $value == @* ]]; then
      ft_read_into "$FT_SCRATCH/value" "${value#@}"
      jq --arg k "$key" --rawfile v "$FT_SCRATCH/value" 'if ($k | endswith("[]")) then .[$k[:-2]] += [$v] else .[$k] = $v end' \
        "$req" >"$req.new"
    elif [[ ($name == -F || $name == --field) && $value =~ ^(-?[0-9]+|true|false|null)$ ]]; then
      jq --arg k "$key" --argjson v "$value" 'if ($k | endswith("[]")) then .[$k[:-2]] += [$v] else .[$k] = $v end' \
        "$req" >"$req.new"
    else
      jq --arg k "$key" --arg v "$value" 'if ($k | endswith("[]")) then .[$k[:-2]] += [$v] else .[$k] = $v end' \
        "$req" >"$req.new"
    fi
    mv "$req.new" "$req"
  done
  cat "$req"
}

# ft_api_method REQUEST_JSON : the HTTP method of an api call: -X / --method, else POST when it carries a body, else GET.
ft_api_method() {
  local method
  if method=$(ft_flag -X --method); then
    printf '%s' "$method" | tr '[:lower:]' '[:upper:]'
  elif [[ $1 != '{}' ]]; then
    printf POST
  else
    printf GET
  fi
}

# ft_endpoint PATH : the API path with its leading slash, query string and API prefix removed.
ft_endpoint() {
  local path=${1#/}
  path=${path%%\?*}
  path=${path#api/v4/}
  printf '%s' "$path"
}

# ft_json_string REQUEST KEY : the request's string KEY, raw; status 1 when it is absent.
ft_json_string() { jq -e -j --arg k "$2" 'if has($k) and .[$k] != null then .[$k] | tostring else error("absent") end' <<<"$1" 2>/dev/null; }

ft_gh_api() {
  local endpoint method req n label json
  endpoint=$(ft_endpoint "${FT_POS[0]:-}")
  req=$(ft_request_json) || exit 1
  method=$(ft_api_method "$req")
  case $endpoint in
    user) ft_output '{"login": "tester"}' ;;
    repos/*/*/issues/*/sub_issues)
      n=$(ft_issue_ref "${endpoint%/sub_issues}")
      ft_issue_exists "$n" || ft_not_found "$endpoint"
      [[ $method == POST ]] || ft_not_found "$method $endpoint"
      json=$(jq -r '.sub_issue_id // empty' <<<"$req")
      if ! [[ $json =~ ^[0-9]+$ ]] || ! ft_issue_exists $((json - 1000000)); then
        ft_fail "sub_issue_id must be the REST id of an issue"
      fi
      printf '%s' "$n" >"$FAKE_TRACKER_DIR/issues/$((json - 1000000))/parent"
      ft_output "$(ft_issue_json gh "$n")"
      ;;
    repos/*/*/issues/*/labels/*)
      n=$(ft_issue_ref "${endpoint%/labels/*}")
      ft_issue_exists "$n" || ft_not_found "$endpoint"
      [[ $method == DELETE ]] || ft_not_found "$method $endpoint"
      label=$(printf '%s' "${endpoint##*/labels/}" | sed -e 's/%20/ /g' -e 's/+/ /g' -e 's/%3A/:/g')
      ft_issue_remove_label "$n" "$label"
      ft_output "$(ft_labels_json "$n" | jq '[.[] | {name: .}]')"
      ;;
    repos/*/*/issues/*/labels)
      n=$(ft_issue_ref "${endpoint%/labels}")
      ft_issue_exists "$n" || ft_not_found "$endpoint"
      [[ $method != PUT ]] || : >"$FAKE_TRACKER_DIR/issues/$n/labels"
      if [[ $method == POST || $method == PUT ]]; then
        ft_lines_to_args < <(jq -r '.labels // [] | .[]' <<<"$req")
        [[ ${#FT_LINES[@]} -eq 0 ]] || ft_add_labels "$n" 0 "${FT_LINES[@]}"
      fi
      ft_output "$(ft_labels_json "$n" | jq '[.[] | {name: .}]')"
      ;;
    repos/*/*/issues/*)
      n=$(ft_issue_ref "$endpoint")
      ft_issue_exists "$n" || ft_not_found "$endpoint"
      if [[ $method == PATCH || $method == POST ]]; then ft_gh_api_update "$n" "$req"; fi
      ft_output "$(ft_issue_json gh "$n")"
      ;;
    repos/*/*/issues)
      [[ $method == POST ]] || ft_not_found "$method $endpoint"
      jq -j '.body // ""' <<<"$req" >"$FT_SCRATCH/body"
      n=$(ft_new_issue "$(jq -j '.title // ""' <<<"$req")" "$FT_SCRATCH/body" issue) || exit 1
      ft_lines_to_args < <(jq -r '.labels // [] | .[]' <<<"$req")
      [[ ${#FT_LINES[@]} -eq 0 ]] || ft_add_labels "$n" 0 "${FT_LINES[@]}"
      ft_output "$(ft_issue_json gh "$n")"
      ;;
    repos/*/*/labels)
      if [[ $method == POST ]]; then ft_label_create "$(jq -j '.name // ""' <<<"$req")"; fi
      ft_label_list_output 1
      ;;
    repos/*/*)
      json=$(jq -n --argjson on "$([[ ${FAKE_ISSUES:-} == disabled ]] && echo false || echo true)" \
        '{full_name: "acme/widget", name: "widget", has_issues: $on, html_url: "https://github.com/acme/widget"}')
      ft_output "$json"
      ;;
    *) ft_not_found "$method $endpoint" ;;
  esac
}

# ft_gh_api_update N REQUEST : apply a REST issue update (title, body, state, labels) to issue N.
ft_gh_api_update() {
  local n=$1 req=$2 value
  if value=$(ft_json_string "$req" title); then printf '%s' "$value" >"$FAKE_TRACKER_DIR/issues/$n/title"; fi
  if jq -e 'has("body")' <<<"$req" >/dev/null; then jq -j '.body // ""' <<<"$req" >"$FAKE_TRACKER_DIR/issues/$n/body"; fi
  if value=$(ft_json_string "$req" state); then printf '%s' "$value" >"$FAKE_TRACKER_DIR/issues/$n/state"; fi
  if jq -e 'has("labels")' <<<"$req" >/dev/null; then
    : >"$FAKE_TRACKER_DIR/issues/$n/labels"
    ft_lines_to_args < <(jq -r '.labels[] | if type == "object" then .name else . end' <<<"$req")
    [[ ${#FT_LINES[@]} -eq 0 ]] || ft_add_labels "$n" 0 "${FT_LINES[@]}"
  fi
}

# ---------------------------------------------------------------- glab

ft_glab() {
  local group=${1:-} sub=${2:-}
  case "$group $sub" in
    "auth status") ft_auth_status ;;
    "issue create" | "issue update" | "issue close" | "issue reopen" | "issue view")
      shift 2
      ft_parse "-t --title -d --description --description-file -l --label -u --unlabel --linked-issues --link-type -R
        --repo -F --output -a --assignee -m --milestone" "$@"
      "ft_glab_issue_$sub"
      ;;
    "label list" | "label create")
      shift 2
      ft_parse "-n --name -c --color -d --description -F --output -R --repo -P --per-page" "$@"
      if [[ $sub == list ]]; then
        if [[ $(ft_flag -F --output) == json ]]; then ft_label_list_output 1; else ft_label_list_output 0; fi
      else
        ft_label_create "$(ft_flag -n --name || printf '%s' "${FT_POS[0]:-}")"
      fi
      ;;
    api*)
      shift
      ft_parse "-X --method -f --raw-field -F --field -H --header --input --hostname" "$@"
      ft_glab_api
      ;;
    *) ft_not_found "glab $*" ;;
  esac
}

# ft_glab_description_into FILE : write the issue description the call gives into FILE; status 1 when it gives none.
ft_glab_description_into() {
  local source value
  if source=$(ft_flag --description-file); then
    ft_read_into "$1" "$source"
  elif value=$(ft_flag -d --description); then
    printf '%s' "$value" >"$1"
  else
    return 1
  fi
}

ft_glab_issue_create() {
  local title body=$FT_SCRATCH/body n target link_type
  title=$(ft_flag -t --title) || ft_fail "title is required"
  : >"$body"
  ft_glab_description_into "$body" || true
  n=$(ft_new_issue "$title" "$body" issue) || exit 1
  ft_lines_to_args < <(ft_flag_all -l --label)
  [[ ${#FT_LINES[@]} -eq 0 ]] || ft_add_labels "$n" 0 "${FT_LINES[@]}"
  link_type=$(ft_flag --link-type || echo relates_to)
  while IFS= read -r target; do
    target=$(ft_issue_ref "$target")
    ft_issue_exists "$target" || ft_fail "linked issue $target not found"
    ft_issue_link "$n" "$target" "$link_type"
  done < <(ft_flag_all --linked-issues)
  printf -- '- Creating issue in acme/widget\n#%s %s (just now)\n %s\n' "$n" "$title" "$(fake_url glab "$n")"
}

ft_glab_issue_update() {
  local n value label
  n=$(ft_issue_arg) || exit 1
  if value=$(ft_flag -t --title); then printf '%s' "$value" >"$FAKE_TRACKER_DIR/issues/$n/title"; fi
  ft_glab_description_into "$FAKE_TRACKER_DIR/issues/$n/body" || true
  while IFS= read -r label; do ft_issue_remove_label "$n" "$label"; done < <(ft_flag_all -u --unlabel)
  ft_lines_to_args < <(ft_flag_all -l --label)
  [[ ${#FT_LINES[@]} -eq 0 ]] || ft_add_labels "$n" 0 "${FT_LINES[@]}"
  printf -- '- Updating issue #%s\n#%s %s\n %s\n' "$n" "$n" "$(cat "$FAKE_TRACKER_DIR/issues/$n/title")" "$(fake_url glab "$n")"
}

ft_glab_issue_close() {
  local n
  n=$(ft_issue_arg) || exit 1
  printf closed >"$FAKE_TRACKER_DIR/issues/$n/state"
  printf -- '- Closing issue...\n✓ Closed issue #%s\n' "$n"
}

ft_glab_issue_reopen() {
  local n
  n=$(ft_issue_arg) || exit 1
  printf open >"$FAKE_TRACKER_DIR/issues/$n/state"
  printf -- '- Reopening issue...\n✓ Reopened issue #%s\n' "$n"
}

ft_glab_issue_view() {
  local n
  n=$(ft_issue_arg) || exit 1
  if [[ $(ft_flag -F --output) == json ]]; then
    ft_issue_json glab "$n"
  else
    printf 'title:\t%s\nstate:\t%s\nlabels:\t%s\n' "$(cat "$FAKE_TRACKER_DIR/issues/$n/title")" \
      "$(cat "$FAKE_TRACKER_DIR/issues/$n/state")" "$(paste -sd, "$FAKE_TRACKER_DIR/issues/$n/labels")"
  fi
}

ft_glab_api() {
  local endpoint method req n value target
  endpoint=$(ft_endpoint "${FT_POS[0]:-}")
  req=$(ft_request_json) || exit 1
  method=$(ft_api_method "$req")
  case $endpoint in
    graphql) ft_glab_graphql "$req" ;;
    user) echo '{"username": "tester"}' ;;
    projects/*/issues/*/links)
      n=$(ft_issue_ref "${endpoint%/links}")
      ft_issue_exists "$n" || ft_not_found "$endpoint"
      [[ $method == POST ]] || ft_not_found "$method $endpoint"
      target=$(jq -j '.target_issue_iid // ""' <<<"$req")
      ft_issue_exists "$target" || ft_fail "target issue $target not found"
      ft_issue_link "$n" "$target" "$(jq -j '.link_type // "relates_to"' <<<"$req")"
      ft_issue_json glab "$n"
      ;;
    projects/*/issues/*)
      n=$(ft_issue_ref "$endpoint")
      ft_issue_exists "$n" || ft_not_found "$endpoint"
      [[ $method != PUT ]] || ft_glab_api_update "$n" "$req"
      ft_issue_json glab "$n"
      ;;
    projects/*/issues)
      [[ $method == POST ]] || ft_not_found "$method $endpoint"
      jq -j '.description // ""' <<<"$req" >"$FT_SCRATCH/body"
      n=$(ft_new_issue "$(jq -j '.title // ""' <<<"$req")" "$FT_SCRATCH/body" "$(jq -j '.issue_type // "issue"' <<<"$req")") || exit 1
      value=$(jq -j '.labels // "" | if type == "array" then join(",") else . end' <<<"$req")
      ft_lines_to_args < <(printf '%s\n' "$value" | tr ',' '\n' | grep -v '^$' || true)
      [[ ${#FT_LINES[@]} -eq 0 ]] || ft_add_labels "$n" 0 "${FT_LINES[@]}"
      ft_issue_json glab "$n"
      ;;
    projects/*/labels)
      if [[ $method == POST ]]; then ft_label_create "$(jq -j '.name // ""' <<<"$req")"; fi
      ft_label_list_output 1
      ;;
    projects/*)
      value=enabled
      [[ ${FAKE_ISSUES:-} != disabled ]] || value=disabled
      jq -n --arg level "$value" \
        '{id: 77, path_with_namespace: "acme/widget", web_url: "https://gitlab.com/acme/widget",
          issues_access_level: $level, issues_enabled: ($level != "disabled")}'
      ;;
    *) ft_not_found "$method $endpoint" ;;
  esac
}

# ft_glab_api_update N REQUEST : apply a REST issue update (title, description, labels, state_event) to issue N.
ft_glab_api_update() {
  local n=$1 req=$2 value
  if value=$(ft_json_string "$req" title); then printf '%s' "$value" >"$FAKE_TRACKER_DIR/issues/$n/title"; fi
  if jq -e 'has("description")' <<<"$req" >/dev/null; then
    jq -j '.description // ""' <<<"$req" >"$FAKE_TRACKER_DIR/issues/$n/body"
  fi
  if jq -e 'has("labels")' <<<"$req" >/dev/null; then : >"$FAKE_TRACKER_DIR/issues/$n/labels"; fi
  while IFS= read -r value; do
    [[ -z $value ]] || ft_issue_remove_label "$n" "$value"
  done < <(jq -r '.remove_labels // "" | if type == "array" then .[] else split(",")[] end' <<<"$req")
  ft_lines_to_args < <(jq -r '[.labels, .add_labels] | map(select(. != null) | if type == "array" then .[] else
    split(",")[] end) | .[] | select(length > 0)' <<<"$req")
  [[ ${#FT_LINES[@]} -eq 0 ]] || ft_add_labels "$n" 0 "${FT_LINES[@]}"
  case $(jq -j '.state_event // ""' <<<"$req") in
    close) printf closed >"$FAKE_TRACKER_DIR/issues/$n/state" ;;
    reopen) printf open >"$FAKE_TRACKER_DIR/issues/$n/state" ;;
  esac
}

# ft_graphql_find VARIABLES QUERY KEY : the first string or number under KEY anywhere in the variables; else, when the
#   query writes `KEY: $name`, the variable name; else the quoted value written after `KEY:` in the query text.
ft_graphql_find() {
  local found query_text variable
  found=$(jq -j --arg k "$3" '[.. | objects | .[$k]? | select(type == "string" or type == "number") | tostring][0] // empty' \
    <<<"$1" 2>/dev/null)
  query_text=$(printf '%s' "$2" | tr '\n' ' ')
  if [[ -z $found ]]; then
    variable=$(printf '%s' "$query_text" | sed -nE "s/.*[^A-Za-z]$3: *\\\$([A-Za-z_][A-Za-z0-9_]*).*/\\1/p" | head -1)
    [[ -z $variable ]] || found=$(jq -j --arg k "$variable" '.[$k] // empty | tostring' <<<"$1" 2>/dev/null)
  fi
  if [[ -z $found ]]; then
    found=$(printf '%s' "$query_text" | sed -nE "s/.*[^A-Za-z]$3: *\"(([^\"\\\\]|\\\\.)*)\".*/\\1/p" | head -1)
  fi
  printf '%s' "$found"
}

# ft_gid_issue GID : the issue number a gid://gitlab/<Type>/<5000+N> names; empty when it names none.
ft_gid_issue() {
  local id=${1##*/}
  [[ $id =~ ^[0-9]+$ && $id -gt 5000 ]] && ft_issue_exists $((id - 5000)) && echo $((id - 5000))
}

# ft_work_item_json N : issue N as a GraphQL work item node.
ft_work_item_json() {
  jq -n --argjson n "$1" --arg url "$(fake_url glab "$1")" --rawfile title "$FAKE_TRACKER_DIR/issues/$1/title" \
    '{id: "gid://gitlab/WorkItem/\(5000 + $n)", iid: "\($n)", webUrl: $url, title: $title}'
}

ft_glab_graphql() {
  local req=$1 query vars n parent child id gid
  if ft_has_flag --input; then
    query=$(jq -j '.query // ""' <<<"$req")
    vars=$(jq -c '.variables // {}' <<<"$req")
  else
    query=$(jq -j '.query // ""' <<<"$req")
    vars=$(jq -c 'del(.query)' <<<"$req")
  fi
  if [[ $query == *workItemCreate* || ($query == *workItemUpdate* && $query$vars == *hierarchyWidget*) ]] &&
    [[ ${FAKE_GRAPHQL:-} == refuse ]]; then
    echo '{"errors": [{"message": "The resource that you are attempting to access does not exist or you do not have permission to perform this action"}], "data": null}'
    printf 'glab: GraphQL error: the resource does not exist or you do not have permission\n' >&2
    exit 1
  fi
  if [[ $query == *workItemCreate* ]]; then
    printf '%s' "$(ft_graphql_find "$vars" "$query" description)" >"$FT_SCRATCH/body"
    n=$(ft_new_issue "$(ft_graphql_find "$vars" "$query" title)" "$FT_SCRATCH/body" task) || exit 1
    parent=$(ft_gid_issue "$(ft_graphql_find "$vars" "$query" parentId)")
    [[ -z $parent ]] || printf '%s' "$parent" >"$FAKE_TRACKER_DIR/issues/$n/parent"
    jq -n --argjson item "$(ft_work_item_json "$n")" '{data: {workItemCreate: {workItem: $item, errors: []}}}'
  elif [[ $query == *workItemUpdate* ]]; then
    id=$(jq -j '.input.id // .id // empty' <<<"$vars" 2>/dev/null)
    [[ -n $id ]] || id=$(printf '%s' "$query" | tr '\n' ' ' | sed -nE 's/.*workItemUpdate *\( *input: *\{ *id: *"([^"]+)".*/\1/p')
    if [[ -z $id ]]; then
      # shellcheck disable=SC2016 # the $ matches a GraphQL variable name, not a shell expansion
      id=$(printf '%s' "$query" | tr '\n' ' ' | sed -nE 's/.*workItemUpdate *\( *input: *\{ *id: *\$([A-Za-z_][A-Za-z0-9_]*).*/\1/p')
      [[ -z $id ]] || id=$(jq -j --arg k "$id" '.[$k] // empty' <<<"$vars" 2>/dev/null)
    fi
    n=$(ft_gid_issue "$id")
    [[ -n $n ]] || ft_fail "GraphQL error: work item $id not found"
    parent=$(ft_gid_issue "$(ft_graphql_find "$vars" "$query" parentId)")
    [[ -z $parent ]] || printf '%s' "$parent" >"$FAKE_TRACKER_DIR/issues/$n/parent"
    for gid in $({
      jq -r '[.. | objects | .childrenIds? // empty | .[]][]' <<<"$vars" 2>/dev/null
      printf '%s' "$query" | tr '\n' ' ' | sed -nE 's/.*childrenIds: *\[([^]]*)\].*/\1/p' | tr ',"' '  '
    }); do
      child=$(ft_gid_issue "$gid")
      [[ -z $child ]] || printf '%s' "$n" >"$FAKE_TRACKER_DIR/issues/$child/parent"
    done
    jq -n --argjson item "$(ft_work_item_json "$n")" '{data: {workItemUpdate: {workItem: $item, errors: []}}}'
  elif [[ $query == *workItemTypes* ]]; then
    jq -n '{nodes: [{id: "gid://gitlab/WorkItems::Type/1", name: "Issue"}, {id: "gid://gitlab/WorkItems::Type/5", name: "Task"}]}
      | {data: {project: {workItemTypes: .}, namespace: {workItemTypes: .}}}'
  else
    n=$(ft_graphql_find "$vars" "$query" iid)
    [[ -n $n ]] || n=$(printf '%s' "$query" | tr '\n' ' ' | sed -nE 's/.*iids?: *\[? *"?([0-9]+).*/\1/p')
    if ft_issue_exists "$n"; then
      jq -n --argjson item "$(ft_work_item_json "$n")" \
        '($item | .id |= sub("WorkItem"; "Issue")) as $issue
         | {data: {project: {id: "gid://gitlab/Project/77", workItem: $item, workItems: {nodes: [$item]}, issue: $issue,
             issues: {nodes: [$issue]}}, namespace: {workItem: $item, workItems: {nodes: [$item]}}}}'
    else
      echo '{"data": {"project": {"id": "gid://gitlab/Project/77"}}}'
    fi
  fi
}
