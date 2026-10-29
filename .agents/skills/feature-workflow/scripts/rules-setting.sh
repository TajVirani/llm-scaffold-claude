#!/usr/bin/env bash
# File: Helper script (not a hook): read one workflow setting from the optional `## Workflow settings` section of .workflow/rules.md.
# Purpose: One reader for project-wide workflow switches, so modules never parse rules.md themselves. The section is optional: absent
#   section, absent block or absent key prints the default. generate-boundary-config.sh reads only Ownership and Shared core and ignores it.
# Usage:
#   rules-setting.sh <key> [--cwd <dir>] [--rules <path>]
#     <key>    a known setting (table below).
#     --cwd    any directory in the project or one of its worktrees; rules.md is read from the MAIN checkout (git rev-parse --git-common-dir),
#              and a pr_template path is checked against that checkout. Default: $PWD.
#     --rules  read this file instead (tests and drafts). No git is needed, except that a pr_template path is still checked against the
#              main checkout found from --cwd.
# Section format: the first fenced ```yaml block under the heading `## Workflow settings` (exact text, trailing spaces allowed); the
#   block is a YAML map of setting -> scalar.
# Settings:
#   key           values                    default   used by
#   task_review   pr | pr-blocking | local  pr        implementation-orchestrator 3.16 (task PR/MR as a non-blocking review record, a
#                                                     blocking review, or no PR); large-path 6.11 and 6.13 (the initiative
#                                                     PR/MR into main, or a local merge); scripts/open-task-pr.sh
#   main_branch   a branch name             see below the branch spec branches fork from (1.1, 0.3.20) and merge into at sign-off (5.8):
#                                                     the target of the feature's PR/MR; scripts/budget-check.sh (3.15 count)
#   pr_template   workflow | a path         workflow  sign-off 5.2 and 5.4: the body the feature's PR/MR is written from, the
#                                                     workflow's own template or the project's (path below)
#   main_branch default: the branch `origin/HEAD` points at (`git symbolic-ref refs/remotes/origin/HEAD`, `origin/` dropped), else main.
#     With --rules (no git) the default is main.
#   pr_template path: repo-relative, ends in .md, holds no `..`, starts with neither / nor -, and names a file that exists under the
#     main checkout root; e.g. .github/pull_request_template.md.
# stdout: the value, one line. stderr: a note when the default is used because rules.md, the section or the key is absent.
# Exit codes: 0 value printed; 1 usage or environment error (unknown key, missing yq, not a git repo, unparsable block, value outside the
#   allowed set, a pr_template file missing from the main checkout).
# Called by: modules/implementation-orchestrator.md (3.16), modules/large-path.md (main_branch for the main ref; task_review for the
#   initiative branch push and the 6.11 / 6.13 merge into main), modules/verification-setup.md (1.1), modules/discovery.md (0.3.20),
#   modules/sign-off.md (5.8; pr_template at 5.2 and 5.4), scripts/open-task-pr.sh, scripts/budget-check.sh.
# Notes: Requires mikefarah yq v4. bash 3.2 compatible. Section parse pattern from budget-check.sh (Size budget block).
# Sources: first-party.

set -euo pipefail

# shellcheck source=../../../lib/workflow-paths.sh
. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../../../lib/workflow-paths.sh"

PROG=rules-setting.sh
HEADING="Workflow settings"
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 1; }
usage() { echo "usage: rules-setting.sh <key> [--cwd <dir>] [--rules <path>]   (keys: task_review, main_branch, pr_template)" >&2; exit 1; }

# setting_spec <key> -> "<default> <allowed values...>"; the allowed value "@branch" accepts any valid branch name, "@template_path"
#   any valid template path whose file exists in the main checkout.
setting_spec() {
  case "$1" in
    task_review) echo "pr pr pr-blocking local" ;;
    main_branch) echo "main @branch" ;;
    pr_template) echo "workflow workflow @template_path" ;;
    *) return 1 ;;
  esac
}

valid_branch_name() {
  [[ "$1" =~ ^[A-Za-z0-9._/-]+$ && "$1" != *..* && "$1" != /* && "$1" != */ && "$1" != -* && "$1" != *.lock ]]
}

# valid_template_path PATH : true when PATH is shaped as a repo-relative .md path: no '..', not absolute, not read as an option.
#   Shape only; the caller then checks the file exists under the main checkout, following symlinks, so a committed symlink may
#   still point outside the repo.
valid_template_path() {
  [[ "$1" == *.md && "$1" != *..* && "$1" != /* && "$1" != -* ]]
}

# find_main_checkout_root WHY : set ROOT to the main checkout of the repo holding --cwd, or die saying WHY git is needed.
find_main_checkout_root() {
  [[ -d "$OPT_CWD" ]] || die "--cwd is not a directory: $OPT_CWD"
  ROOT=$(wf_main_root "$OPT_CWD" 2>/dev/null) || die "$1: not inside a git repository: $OPT_CWD"
}

KEY="" OPT_CWD=$PWD RULES="" ROOT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --cwd)   [[ $# -ge 2 ]] || usage; OPT_CWD=$2; shift 2 ;;
    --rules) [[ $# -ge 2 ]] || usage; RULES=$2; shift 2 ;;
    -h|--help) usage ;;
    --*) die "unknown option: $1" ;;
    *) [[ -z "$KEY" ]] || usage; KEY=$1; shift ;;
  esac
done
[[ -n "$KEY" ]] || usage
SPEC=$(setting_spec "$KEY") || die "unknown setting '$KEY' (known: task_review, main_branch, pr_template)"
# shellcheck disable=SC2086 # split the spec on purpose
set -- $SPEC
DEFAULT=$1; shift
ALLOWED="$*"

if [[ -z "$RULES" ]]; then
  find_main_checkout_root "cannot find $WF_RULES"
  RULES="$ROOT/$WF_RULES"
  if [[ "$KEY" == main_branch ]]; then
    origin_head=$(git -C "$ROOT" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)
    [[ -z "$origin_head" ]] || DEFAULT=${origin_head#origin/}
  fi
fi

default_out() { printf '%s: %s; using the default %s=%s\n' "$PROG" "$1" "$KEY" "$DEFAULT" >&2; printf '%s\n' "$DEFAULT"; exit 0; }

[[ -f "$RULES" ]] || default_out "no rules file at $RULES"
block=$(awk -v h="## $HEADING" '
  /^## /{ if (insec) exit; t = $0; sub(/[[:space:]]+$/, "", t); insec = (t == h); next }
  insec && !infence && /^```ya?ml[[:space:]]*$/ { infence = 1; next }
  insec && infence && /^```[[:space:]]*$/ { exit }
  insec && infence { print }
' "$RULES")
[[ -n "$block" ]] || default_out "no yaml block under '## $HEADING' in $RULES"

command -v yq >/dev/null 2>&1 || die "yq not found on PATH; install mikefarah yq v4 (the Python yq has different flags)"
yq --version 2>/dev/null | grep -q 'mikefarah' || die "yq on PATH is not mikefarah yq v4 (the Python yq has different flags)"
tag=$(printf '%s\n' "$block" | yq 'tag' 2>/dev/null) || die "the yaml block under '## $HEADING' in $RULES does not parse"
[[ "$tag" == "!!map" ]] || die "the yaml block under '## $HEADING' in $RULES must be a map of setting: value"
val=$(printf '%s\n' "$block" | K=$KEY yq '.[strenv(K)] // "" | select(tag != "!!map" and tag != "!!seq")' 2>/dev/null) \
  || die "cannot read $KEY from '## $HEADING' in $RULES"
[[ -n "$val" ]] || default_out "$KEY is not set under '## $HEADING' in $RULES"
for a in $ALLOWED; do
  # An @-token stands for a class of values, so a value spelled like the token itself is never a literal match.
  if [[ "$a" != @* && "$a" == "$val" ]] || { [[ "$a" == "@branch" ]] && valid_branch_name "$val"; }; then printf '%s\n' "$val"; exit 0; fi
  if [[ "$a" == "@template_path" ]] && valid_template_path "$val"; then
    [[ -n "$ROOT" ]] || find_main_checkout_root "$KEY is '$val' and its file is checked in the main checkout"
    [[ -f "$ROOT/$val" ]] || die "$KEY in '## $HEADING' of $RULES is '$val'; no such file in the main checkout $ROOT"
    printf '%s\n' "$val"; exit 0
  fi
done
[[ "$ALLOWED" != "@branch" ]] || die "$KEY in '## $HEADING' of $RULES is '$val'; expected a branch name, e.g. main"
[[ "$ALLOWED" != "workflow @template_path" ]] \
  || die "$KEY in '## $HEADING' of $RULES is '$val'; expected workflow or a repo-relative path to a .md file (no '..', not starting with / or -)"
die "$KEY in '## $HEADING' of $RULES is '$val'; expected one of: $ALLOWED"
