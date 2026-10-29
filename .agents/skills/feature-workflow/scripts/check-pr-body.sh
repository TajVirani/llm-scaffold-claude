#!/usr/bin/env bash
# File: Helper script (not a hook): check the shape of a filled Sign-off PR description (`pr-body.md`).
# Purpose: Sign-off fills `.workflow/specs/NNN-slug/pr-body.md` at 5.4 and publishes it unchanged at 5.8. This script checks
#   its shape both times, so a body with a missing, misplaced or empty section, or a risk score off its scale, never
#   reaches the PR. The script only reads files.
#   Workflow mode (the default): the body follows assets/pr-template.md, whose `##` headings are read from the template
#   itself: the ten sections in order (Link to issue, What changed, Why the change, Why this approach, Special things to
#   note, How to test, Blast radius, Risk and reversibility, Areas, concepts and seams changed, How to undo this PR), each
#   non-empty; the Risk and reversibility section holds `Risk: Low|Medium|High` and
#   `Reversibility: Easy|Moderate|Hard|Irreversible`, and Irreversible needs Risk: High.
#   Project mode (--project-template): every `##` heading of the project's own PR/MR template is present in the body and
#   non-empty; no order or score checks.
#   A section's content is its non-blank lines up to the next `##` heading, with HTML comments removed, so a section that
#   still holds only the template's guidance comment counts as empty. Lines before the first heading are not checked, and
#   headings the template does not name are ignored.
#   A score is the first word after `Risk:` or `Reversibility:` (`Risk: Medium - <reason>` reads Medium), taken from the
#   first such line at the start of a line in the Risk and reversibility section.
# Usage:
#   check-pr-body.sh <file> [--project-template <template file>]
#     <file>                a filled PR body.
#     --project-template    the project's PR/MR template (e.g. .github/pull_request_template.md) when `pr_template` is a path.
# stdout: nothing when the body is valid; otherwise one `<field>: <problem>` line per fault, every fault reported, the field
#   being the section heading (problem "missing", "empty" or "out of order"), `Risk` or `Reversibility`.
# Exit: 0 the body is valid; 1 one or more faults (one line each on stdout, nothing else); 2 usage error, missing or
#   unreadable body or template, or a template with no `##` headings (message on stderr).
# Called by: modules/sign-off.md (5.4 after filling pr-body.md, 5.8 before publishing it).
# Notes: bash 3.2 compatible; needs only awk, grep and sed.
# Sources: first-party.

set -euo pipefail

PROG=check-pr-body.sh
SCRIPT_DIR=$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)
WORKFLOW_TEMPLATE=$SCRIPT_DIR/../assets/pr-template.md
RISK_SECTION='Risk and reversibility'
RISK_SCALE='Low Medium High'
REVERSIBILITY_SCALE='Easy Moderate Hard Irreversible'

# die MSG : print "<prog>: MSG" to stderr and exit 2.
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

# usage : print the usage line to stderr and exit 2.
usage() {
  echo "usage: $PROG <file> [--project-template <template file>]" >&2
  exit 2
}

# require_readable FILE : exit 2 unless FILE is a readable regular file.
require_readable() {
  [[ -f $1 ]] || die "no such file: $1"
  [[ -r $1 ]] || die "cannot read: $1"
}

# outline FILE : print FILE's `##` headings as `## <heading>` (trailing spaces trimmed) and its content lines, with HTML
#   comments removed and blank lines dropped. A `##` line that starts inside a comment is not a heading.
outline() {
  awk '
    {
      starts_in_comment = in_comment
      rest = $0
      kept = ""
      while (rest != "") {
        if (in_comment) {
          end = index(rest, "-->")
          if (!end) { rest = ""; break }
          rest = substr(rest, end + 3)
          in_comment = 0
        } else {
          open = index(rest, "<!--")
          if (!open) { kept = kept rest; break }
          kept = kept substr(rest, 1, open - 1)
          rest = substr(rest, open + 4)
          in_comment = 1
        }
      }
      if (!starts_in_comment && $0 ~ /^## /) {
        heading = $0
        sub(/[[:space:]]+$/, "", heading)
        print heading
      } else if (kept ~ /[^[:space:]]/) {
        print kept
      }
    }
  ' "$1"
}

# headings_of OUTLINE : print the heading text of each `##` line in OUTLINE, one per line.
headings_of() { sed -n 's/^## //p' <<<"$1"; }

# section_content OUTLINE HEADING : print the content lines of the first section titled HEADING in OUTLINE.
section_content() {
  awk -v wanted="$2" '
    /^## / { if (found) exit; found = (substr($0, 4) == wanted); next }
    found
  ' <<<"$1"
}

# fault FIELD PROBLEM : record one `<field>: <problem>` line for the report.
fault() { faults="$faults$1: $2"$'\n'; }

# check_sections_present OUTLINE EXPECTED : fault each EXPECTED heading the body lacks or leaves empty.
check_sections_present() {
  local heading body_headings
  body_headings=$(headings_of "$1")
  while IFS= read -r heading; do
    if ! grep -Fxq -- "$heading" <<<"$body_headings"; then
      fault "$heading" "missing"
    elif [[ -z $(section_content "$1" "$heading") ]]; then
      fault "$heading" "empty"
    fi
  done <<<"$2"
}

# check_section_order OUTLINE EXPECTED : fault each EXPECTED heading that comes after one the template puts later.
check_section_order() {
  local misplaced
  misplaced=$(headings_of "$1" | awk '
    NR == FNR { rank[$0] = FNR; next }
    !($0 in rank) { next }
    rank[$0] < highest_rank { print $0 ": out of order; the template puts it before " latest; next }
    { highest_rank = rank[$0]; latest = $0 }
  ' <(printf '%s\n' "$2") -)
  [[ -z $misplaced ]] || faults="$faults$misplaced"$'\n'
}

# score_line CONTENT FIELD : print the first line of CONTENT that starts with "FIELD:", or nothing.
score_line() { awk -v prefix="$2:" 'index($0, prefix) == 1 { print; exit }' <<<"$1"; }

# score_word LINE FIELD : print the first word after "FIELD:" in LINE, without trailing punctuation.
score_word() {
  local word rest=${1#"$2:"}
  read -r word _ <<<"$rest" || true
  printf '%s\n' "${word%%[.,;:]*}"
}

# on_scale WORD SCALE : succeed when WORD is one of the space-separated values in SCALE.
on_scale() { [[ -n $1 && " $2 " == *" $1 "* ]]; }

# check_score CONTENT FIELD SCALE : fault a missing FIELD line or a score off SCALE; leave the score read in $score.
check_score() {
  local line
  score=
  line=$(score_line "$1" "$2")
  if [[ -z $line ]]; then
    fault "$2" "missing; the $RISK_SECTION section needs a line \`$2: ${3// /|} - <reason>\`"
    return 0
  fi
  score=$(score_word "$line" "$2")
  if [[ -z $score ]]; then
    fault "$2" "no score; expected one of ${3// /, }"
  elif ! on_scale "$score" "$3"; then
    fault "$2" "$score is not on the scale ${3// /, }"
  fi
}

# check_risk_scores OUTLINE : fault off-scale or missing Risk and Reversibility scores, and Irreversible without Risk: High.
check_risk_scores() {
  local content risk reversibility
  content=$(section_content "$1" "$RISK_SECTION")
  [[ -n $content ]] || return 0
  check_score "$content" Risk "$RISK_SCALE"
  risk=$score
  check_score "$content" Reversibility "$REVERSIBILITY_SCALE"
  reversibility=$score
  if [[ $reversibility == Irreversible && $risk != High ]]; then
    fault Reversibility "Irreversible requires Risk: High, found Risk: ${risk:-none}"
  fi
}

body=
project_template=
while [[ $# -gt 0 ]]; do
  case $1 in
    --project-template)
      [[ $# -ge 2 && -n $2 ]] || usage
      project_template=$2
      shift 2
      ;;
    -*) usage ;;
    *)
      [[ -z $body && -n $1 ]] || usage
      body=$1
      shift
      ;;
  esac
done
[[ -n $body ]] || usage

template=${project_template:-$WORKFLOW_TEMPLATE}
require_readable "$body"
require_readable "$template"

expected=$(headings_of "$(outline "$template")")
[[ -n $expected ]] || die "no ## headings in template: $template"
body_outline=$(outline "$body")

faults=
score=
check_sections_present "$body_outline" "$expected"
if [[ -z $project_template ]]; then
  check_section_order "$body_outline" "$expected"
  check_risk_scores "$body_outline"
fi

if [[ -n $faults ]]; then
  printf '%s' "$faults"
  exit 1
fi
