#!/usr/bin/env bash
# File: Helper script (not a hook): check a review-lessons file against its entry rules, or print the id its next entry takes.
# Purpose: The lessons file holds one fenced yaml block with a `lessons` list. Its entry rules are stated in plain words in the
#   header of the template, assets/review-lessons.md, and only there; this script is their executable form, so a change to
#   the rules changes both.
#   validate: the block parses and every rule in the template header holds.
#   next-id: the highest RL- number in the list plus one, retired entries included, so an id is never reused; RL-001 when the
#   list is empty. Numbers below 100 are padded to three digits.
# Usage:
#   review-lessons.sh validate <file>   stdout empty; on a broken rule one line on stderr naming the field, e.g.
#                                       `review-lessons.sh: <file>: lessons[0].enforced_by: required once retired is set`
#   review-lessons.sh next-id <file>    prints the next id, e.g. RL-002
# Exit: 0 the file meets the rules (validate) or the id was printed (next-id); 1 the file breaks a rule or its block does not
#   parse (one reason line on stderr); 2 usage error, missing or unreadable file, or missing jq or mikefarah yq v4.
# Called by: the validate: and next-id: lines in the header of assets/review-lessons.md, which the retrospective runs
#   (retrospective/modules/routing.md) when it adds or retires a lesson.
# Notes: bash 3.2 compatible; needs awk, jq and mikefarah yq v4. Reads the file only.
# Sources: first-party.

set -euo pipefail

PROG=review-lessons.sh

# die MSG : print "<prog>: MSG" to stderr and exit 2.
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

# refuse FILE MSG : print "<prog>: FILE: MSG" to stderr and exit 1.
refuse() { printf '%s: %s: %s\n' "$PROG" "$1" "$2" >&2; exit 1; }

# usage : print the usage lines to stderr and exit 2.
usage() {
  printf 'usage: %s validate <file>\n       %s next-id <file>\n' "$PROG" "$PROG" >&2
  exit 2
}

# require_tools : exit 2 unless jq and mikefarah yq v4 are on PATH.
require_tools() {
  command -v jq >/dev/null 2>&1 || die "jq not found on PATH"
  command -v yq >/dev/null 2>&1 || die "yq not found on PATH (needs mikefarah yq v4)"
  case "$(yq --version 2>&1)" in
    *mikefarah*version\ v4.* | *mikefarah*version\ 4.*) ;;
    *) die "yq on PATH is not mikefarah yq v4" ;;
  esac
}

# lessons_json FILE : print the file's first fenced yaml block as JSON (null when there is none); exit 1 when it does not parse.
lessons_json() {
  local json
  # yq's own parse message is dropped on purpose: the refusal below must be the only line on stderr.
  json=$(awk '/^```yaml$/{inside=1; next} /^```$/{if (inside) exit} inside' "$1" | yq -o=json '.' - 2>/dev/null) ||
    refuse "$1" "the fenced yaml block does not parse"
  printf '%s\n' "$json"
}

# Prints one line per broken rule, in file order; the first is the one reported.
# shellcheck disable=SC2016 # $i, $e, $all and $j are jq variables, not shell ones
BROKEN_RULES='
def iso_date: type == "string" and test("^[0-9]{4}-[0-9]{2}-[0-9]{2}$");
def non_empty_string: type == "string" and length > 0;
def path_errors($at):
  if (type != "array") or length == 0 then "\($at): needs a list of at least one glob"
  else to_entries[] | .key as $j | .value
    | if (non_empty_string | not) then "\($at)[\($j)]: must be a non-empty glob"
      elif startswith("/") then "\($at)[\($j)]: \(.) is absolute; write it relative to the repo root"
      elif (split("/") | any(. == "..")) then "\($at)[\($j)]: \(.) contains .."
      else empty end
  end;
if type != "object" or (.lessons | type) != "array" then
  "lessons: the fenced yaml block needs a lessons list"
else
  .lessons as $all
  | $all | to_entries[] | .key as $i | .value as $e | "lessons[\($i)]" as $at
  | if ($e | type) != "object" then "\($at): not a mapping"
    else
      (if ($e.id | type == "string" and test("^RL-[0-9]{3,}$")) then empty
       else "\($at).id: must be RL- and at least three digits" end),
      (if any($all[0:$i][]; type == "object" and .id == $e.id) then "\($at).id: \($e.id) is used more than once" else empty end),
      (if ($e.symptom | non_empty_string) then empty else "\($at).symptom: must not be empty" end),
      ($e.paths | path_errors("\($at).paths")),
      (if ($e.origin_spec | type == "string" and test("^\\.workflow/specs/[0-9]{3}-[a-z0-9-]+$")) then empty
       else "\($at).origin_spec: must be .workflow/specs/ then a three-digit number and a lowercase slug" end),
      (if ($e.date | iso_date) then empty else "\($at).date: must be a YYYY-MM-DD date" end),
      (if ($e | has("retired")) then
         (if ($e.retired | iso_date) then empty else "\($at).retired: must be a YYYY-MM-DD date" end),
         (if ($e.enforced_by | non_empty_string) then empty else "\($at).enforced_by: required once retired is set" end)
       else empty end)
    end
end'

# validate FILE : exit 0 when FILE meets the entry rules, else refuse with the first broken rule.
validate() {
  local json first
  json=$(lessons_json "$1")
  first=$(jq -r "[$BROKEN_RULES] | first // empty" <<<"$json") || die "jq failed on $1"
  [[ -z $first ]] || refuse "$1" "$first"
}

# next_id FILE : print the id the next entry in FILE takes.
next_id() {
  local json
  json=$(lessons_json "$1")
  jq -r '
    [.lessons[]? | objects | .id | strings | select(test("^RL-[0-9]+$")) | ltrimstr("RL-") | tonumber]
    | (max // 0) + 1 | tostring
    | if length < 3 then ("00" + .)[-3:] else . end
    | "RL-" + .' <<<"$json" || die "jq failed on $1"
}

[[ $# -eq 2 ]] || usage
command=$1
file=$2
case "$command" in
  validate | next-id) ;;
  *) usage ;;
esac
[[ -f $file && -r $file ]] || die "no readable file: $file"
require_tools

case "$command" in
  validate) validate "$file" ;;
  next-id) next_id "$file" ;;
esac
