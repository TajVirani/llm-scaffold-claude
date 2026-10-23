#!/usr/bin/env bash
# File: Helper script (not a hook): check the shape of one Phase 3 result file and print a bounded table of it.
# Purpose: The implementation, integration and profile-mini-review agents write their full result block to a file under the
#   spec's artifacts/ folder. The orchestrator reads each one through this script instead of retyping or reading the whole
#   block, so a malformed block is caught at once and the orchestrator sees one header line and a few rows. The script only
#   reads the file.
#   Kind: from the file name (implementation*.yaml, integration*.yaml, mini-review*.yaml), or from --kind, which wins.
#   The result files live at <spec_dir>/artifacts/<task_id>/implementation.yaml, artifacts/phase-1-<work_type>/implementation.yaml,
#   artifacts/integration-<work_type>/integration.yaml and artifacts/<task_id>/mini-review.yaml; an older round keeps the
#   same stem with an -r<k> suffix.
# Usage:
#   check-task-result.sh <file> [--kind implementation|integration|mini-review]
# Shape rules (each failure is one line on stdout, `<field>: <problem>`, the field written as a top-level key or
#   `<list>[<i>].<key>`; a file with more than one YAML document, or whose root is not a mapping, fails as `root`):
#   discovered-work entries (implementation and integration discovered_work, mini-review out_of_scope_noticed) each have
#     kind (bug, requirement, refactor, scope-expansion, decision), non-empty summary, evidence and reason, and
#     blocker_assessment (blocks-this-task, can-wait).
#   head_commit is 7 to 40 hex characters; it may be null only when status is blocked or profile-wrong.
#   implementation:
#   - status is done, profile-wrong, scope-expansion, discovered-work or blocked; summary, task_id, worktree and base_commit
#     are non-empty strings; branch is a string or null; head_commit as above.
#   - task_id equals the folder name when the file sits in artifacts/<folder>/.
#   - files_changed is a list of strings; tests_added is a list of {file, test, kind}, kind behaviour, negative or edge;
#     evidence is a mapping with a non-empty toolchain; considered_not_built is a list; profile_wrong, scope_expansion and
#     blocked are each null or a mapping; discovered_work is a list of discovered-work entries.
#   - profile-wrong needs profile_wrong.line; scope-expansion needs a non-empty scope_expansion.requested_paths list;
#     blocked needs blocked.reason; discovered-work needs a non-empty discovered_work.
#   integration:
#   - status is done, partial, profile-wrong, discovered-work or blocked; summary, work_type, worktree and base_commit are
#     non-empty strings; branch is a string or null; head_commit as above.
#   - requests is a list of {n, verdict, reason}: n an integer, verdict applied, reject-not-shared-core,
#     reject-other-work-type, conflict or blocked, reason non-empty; partial needs at least one verdict other than applied.
#   - files_changed is a list; evidence.toolchain is non-empty; profile_wrong and blocked are each null or a mapping;
#     discovered_work is a list of discovered-work entries.
#   mini-review:
#   - verdict is pass or fail, and is fail exactly when an item is fail; task_id, work_type, diff and tool_output are
#     non-empty strings; mode is full or re-check; previous is a non-empty string in re-check mode, else null.
#   - items is a non-empty list of {n, verdict, location}: n an integer or R1 to R5; verdict pass, fail, tool-covered or
#     not-applicable; location a string; a non-empty note on fail and tool-covered; carried_from, when present, is r<k>
#     and is allowed only in re-check mode.
#   - read_outside_diff is a list; out_of_scope_noticed is a list of discovered-work entries.
# stdout on exit 0, a header line, then tab-separated rows (values cut to 120 characters, tabs and line breaks become spaces):
#   implementation: status: <s>  task: <id>  head: <sha7>  files: <n>  tests: <n> (behaviour <b>, negative <n>, edge <e>)  discovered_work: <k>
#     then `summary: <text>` (cut to 240 characters); one row per discovered-work entry
#     (kind, blocker_assessment, evidence, summary); for a stop status one line naming the stop field and its content:
#     `profile_wrong.line: <line>`, `scope_expansion.requested_paths: <a, b>` or `blocked.reason: <reason>`.
#   integration: status: <s>  work_type: <wt>  head: <sha7>  requests: <n> (applied <a>, rejected <r>, conflict <c>, blocked <b>)  discovered_work: <k>
#     then one row per request (n, verdict, reason); then the discovered-work rows.
#   mini-review: verdict: <v>  task: <id>  mode: <m>  items: <n> (pass <p>, fail <f>, tool-covered <t>, not-applicable <na>, carried <c>)  out_of_scope: <k>
#     then one row per fail and tool-covered item (n, verdict, location, note); then one discovered-work row per
#     out_of_scope_noticed entry.
#   A null head_commit prints as "-".
# Exit: 0 the shape is valid and the table was printed; 1 one or more shape errors (one line each on stdout, nothing else);
#   2 usage error, missing or unreadable file, YAML that does not parse, unknown kind, or missing jq or mikefarah yq v4
#   (message on stderr).
# Called by: modules/implementation-orchestrator.md (after each implementation, integration and mini-review agent returns)
#   and modules/verification-setup.md (after the Phase 1 implementation agents return).
# Notes: bash 3.2 compatible; needs jq and mikefarah yq v4.
# Sources: first-party.

set -euo pipefail

PROG=check-task-result.sh

# die MSG : print "<prog>: MSG" to stderr and exit 2.
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

# usage : print the usage line to stderr and exit 2.
usage() {
  echo "usage: $PROG <file> [--kind implementation|integration|mini-review]" >&2
  exit 2
}

# kind_from_name FILE : print the kind the file name implies, or nothing when it implies none.
kind_from_name() {
  case "$(basename "$1")" in
    implementation*.yaml) echo implementation ;;
    integration*.yaml) echo integration ;;
    mini-review*.yaml) echo mini-review ;;
  esac
}

# artifacts_folder FILE : print the folder name when the file sits in artifacts/<folder>/, else nothing.
artifacts_folder() {
  local dir
  dir=$(dirname "$1")
  if [[ $(basename "$(dirname "$dir")") == artifacts ]]; then
    basename "$dir"
  fi
}

# The jq programs read the file as a one-element array (jq -s), so a multi-document file is caught as a shape error.
# Definitions both programs share: small value helpers and the discovered-work entry.
read -r -d '' JQ_DEFS <<'JQ' || true
def text: if . == null then "" else tostring end;
def str_filled: type == "string" and length > 0;
def one_line: text | gsub("[\t\r\n]+"; " ");
def cut: one_line | .[0:120];
def is_list: type == "array";
def list_len: if is_list then length else 0 end;
def is_int: type == "number" and . == floor;
def one_of($set): text as $v | any($set[]; . == $v);
def sha7: if . == null then "-" else text | .[0:7] end;
def dw_row: [.kind, .blocker_assessment, (.evidence | cut), (.summary | cut)] | map(one_line) | join("\t");
JQ

# Each rule emits zero or more "<field>: <problem>" lines.
read -r -d '' JQ_CHECK <<'JQ' || true
def need_str($k): if (.[$k] | str_filled) then empty else "\($k): missing or not a non-empty string" end;
def need_list($k): if (.[$k] | is_list) then empty else "\($k): not a list" end;
def null_or_map($k): if .[$k] == null or (.[$k] | type) == "object" then empty else "\($k): not null or a mapping" end;
def need_enum($k; $set):
  if (.[$k] | one_of($set)) then empty else "\($k): '\(.[$k] | text)' is not one of \($set | join(", "))" end;

def check_branch:
  if .branch == null or (.branch | type) == "string" then empty else "branch: not a string or null" end;

def check_head($null_ok):
  .head_commit as $h
  | if $h == null then (if $null_ok then empty else "head_commit: missing; null is allowed only when status is blocked or profile-wrong" end)
    elif ($h | type) == "string" or ($h | type) == "number" then
      (if ($h | text | test("^[0-9a-fA-F]{7,40}$")) then empty else "head_commit: '\($h | text)' is not 7 to 40 hex characters" end)
    else "head_commit: not a string" end;

def check_dw_entry($at):
  if type != "object" then "\($at): not a mapping"
  else
    (if (.kind | one_of(["bug", "requirement", "refactor", "scope-expansion", "decision"])) then empty
     else "\($at).kind: '\(.kind | text)' is not bug, requirement, refactor, scope-expansion or decision" end),
    (["summary", "evidence", "reason"][] as $k | if (.[$k] | str_filled) then empty else "\($at).\($k): missing or empty" end),
    (if (.blocker_assessment | one_of(["blocks-this-task", "can-wait"])) then empty
     else "\($at).blocker_assessment: '\(.blocker_assessment | text)' is not blocks-this-task or can-wait" end)
  end;

def check_dw_list($k):
  if (.[$k] | is_list) | not then "\($k): not a list"
  else .[$k] | to_entries[] | .key as $i | .value | check_dw_entry("\($k)[\($i)]") end;

def check_strings_list($k):
  if (.[$k] | is_list) | not then "\($k): not a list"
  else .[$k] | to_entries[] | select((.value | type) != "string") | "\($k)[\(.key)]: not a string" end;

def check_implementation($folder):
  (.status | text) as $s
  | need_enum("status"; ["done", "profile-wrong", "scope-expansion", "discovered-work", "blocked"]),
    need_str("summary"),
    (if (.task_id | str_filled) | not then "task_id: missing or not a non-empty string"
     elif $folder != "" and .task_id != $folder then "task_id: '\(.task_id)' does not match the artifacts folder \($folder)"
     else empty end),
    need_str("worktree"), need_str("base_commit"), check_branch,
    check_head($s == "blocked" or $s == "profile-wrong"),
    check_strings_list("files_changed"),
    (if (.tests_added | is_list) | not then "tests_added: not a list"
     else .tests_added | to_entries[] | .key as $i | .value
       | if type != "object" then "tests_added[\($i)]: not a mapping"
         else
           (["file", "test"][] as $k | if (.[$k] | str_filled) then empty else "tests_added[\($i)].\($k): missing or empty" end),
           (if (.kind | one_of(["behaviour", "negative", "edge"])) then empty
            else "tests_added[\($i)].kind: '\(.kind | text)' is not behaviour, negative or edge" end)
         end
     end),
    (if (.evidence | type) != "object" then "evidence: not a mapping"
     elif (.evidence.toolchain | str_filled) | not then "evidence.toolchain: missing or empty"
     else empty end),
    need_list("considered_not_built"),
    null_or_map("profile_wrong"), null_or_map("scope_expansion"), null_or_map("blocked"),
    check_dw_list("discovered_work"),
    (if $s == "profile-wrong" and ((.profile_wrong.line? // null) | str_filled | not) then
       "profile_wrong.line: missing or empty, required when status is profile-wrong"
     elif $s == "scope-expansion" and (((.scope_expansion.requested_paths? // null) | is_list and length > 0) | not) then
       "scope_expansion.requested_paths: missing or empty, required when status is scope-expansion"
     elif $s == "blocked" and ((.blocked.reason? // null) | str_filled | not) then
       "blocked.reason: missing or empty, required when status is blocked"
     elif $s == "discovered-work" and ((.discovered_work | list_len) == 0) then
       "discovered_work: empty, required when status is discovered-work"
     else empty end);

def check_integration:
  (.status | text) as $s
  | need_enum("status"; ["done", "partial", "profile-wrong", "discovered-work", "blocked"]),
    need_str("summary"), need_str("work_type"), need_str("worktree"), need_str("base_commit"), check_branch,
    check_head($s == "blocked" or $s == "profile-wrong"),
    (if (.requests | is_list) | not then "requests: not a list"
     else
       (.requests | to_entries[] | .key as $i | .value
         | if type != "object" then "requests[\($i)]: not a mapping"
           else
             (if (.n | is_int) then empty else "requests[\($i)].n: '\(.n | text)' is not an integer" end),
             (if (.verdict | one_of(["applied", "reject-not-shared-core", "reject-other-work-type", "conflict", "blocked"])) then empty
              else "requests[\($i)].verdict: '\(.verdict | text)' is not applied, reject-not-shared-core, reject-other-work-type, conflict or blocked" end),
             (if (.reason | str_filled) then empty else "requests[\($i)].reason: missing or empty" end)
           end),
       (if $s == "partial" and ([.requests[] | select(type == "object" and .verdict != "applied")] | length) == 0 then
          "requests: status is partial but every verdict is applied"
        else empty end)
     end),
    need_list("files_changed"),
    (if ((.evidence | type) == "object" and (.evidence.toolchain | str_filled)) then empty else "evidence.toolchain: missing or empty" end),
    check_dw_list("discovered_work"),
    null_or_map("profile_wrong"), null_or_map("blocked");

def check_item($recheck; $i):
  "items[\($i)]" as $at
  | if type != "object" then "\($at): not a mapping"
    else
      (if (.n | is_int) or ((.n | type) == "string" and (.n | test("^R[1-5]$"))) then empty
       else "\($at).n: '\(.n | text)' is not an integer or R1 to R5" end),
      (if (.verdict | one_of(["pass", "fail", "tool-covered", "not-applicable"])) then empty
       else "\($at).verdict: '\(.verdict | text)' is not pass, fail, tool-covered or not-applicable" end),
      (if (.location | type) == "string" then empty else "\($at).location: missing or not a string" end),
      (if (.verdict | one_of(["fail", "tool-covered"])) and ((.note | str_filled) | not) then
         "\($at).note: missing or empty, required when the verdict is \(.verdict)"
       else empty end),
      (if has("carried_from") | not then empty
       elif $recheck | not then "\($at).carried_from: allowed only when mode is re-check"
       elif (.carried_from | type) == "string" and (.carried_from | test("^r[0-9]+$")) then empty
       else "\($at).carried_from: '\(.carried_from | text)' is not r<k>" end)
    end;

def check_mini_review:
  (.mode == "re-check") as $recheck
  | need_enum("verdict"; ["pass", "fail"]),
    need_str("task_id"), need_str("work_type"), need_str("diff"), need_str("tool_output"),
    need_enum("mode"; ["full", "re-check"]),
    (if $recheck then (if (.previous | str_filled) then empty else "previous: missing or empty, required when mode is re-check" end)
     elif .previous != null then "previous: must be null when mode is not re-check"
     else empty end),
    (if ((.items | is_list) and (.items | length) > 0) | not then "items: not a non-empty list"
     else
       (.items | to_entries[] | .key as $i | .value | check_item($recheck; $i)),
       (any(.items[]; type == "object" and .verdict == "fail") as $failed
        | if .verdict == "fail" and ($failed | not) then "verdict: fail but no item is fail"
          elif .verdict == "pass" and $failed then "verdict: pass but an item is fail"
          else empty end)
     end),
    need_list("read_outside_diff"),
    check_dw_list("out_of_scope_noticed");

if length != 1 then "root: expected one YAML document, found \(length)"
else .[0]
  | if type != "object" then "root: not a mapping"
    elif $kind == "implementation" then check_implementation($folder)
    elif $kind == "integration" then check_integration
    else check_mini_review end
end
JQ

# Runs only on a file that passed the check, so every field it reads has the right shape.
read -r -d '' JQ_TABLE <<'JQ' || true
def count($list; $key; $value): [$list[] | select(.[$key] == $value)] | length;

def table_implementation:
  .tests_added as $t
  | "status: \(.status)  task: \(.task_id)  head: \(.head_commit | sha7)  files: \(.files_changed | length)  tests: \($t | length) (behaviour \(count($t; "kind"; "behaviour")), negative \(count($t; "kind"; "negative")), edge \(count($t; "kind"; "edge")))  discovered_work: \(.discovered_work | length)",
    "summary: \(.summary | one_line | .[0:240])",
    (.discovered_work[] | dw_row),
    (if .status == "profile-wrong" then "profile_wrong.line: \(.profile_wrong.line | cut)"
     elif .status == "scope-expansion" then "scope_expansion.requested_paths: \(.scope_expansion.requested_paths | map(text) | join(", ") | cut)"
     elif .status == "blocked" then "blocked.reason: \(.blocked.reason | cut)"
     else empty end);

def table_integration:
  .requests as $r
  | "status: \(.status)  work_type: \(.work_type)  head: \(.head_commit | sha7)  requests: \($r | length) (applied \(count($r; "verdict"; "applied")), rejected \([$r[] | select(.verdict | startswith("reject-"))] | length), conflict \(count($r; "verdict"; "conflict")), blocked \(count($r; "verdict"; "blocked")))  discovered_work: \(.discovered_work | length)",
    ($r[] | [(.n | tostring), .verdict, (.reason | cut)] | map(one_line) | join("\t")),
    (.discovered_work[] | dw_row);

def table_mini_review:
  .items as $i
  | "verdict: \(.verdict)  task: \(.task_id)  mode: \(.mode)  items: \($i | length) (pass \(count($i; "verdict"; "pass")), fail \(count($i; "verdict"; "fail")), tool-covered \(count($i; "verdict"; "tool-covered")), not-applicable \(count($i; "verdict"; "not-applicable")), carried \([$i[] | select(has("carried_from"))] | length))  out_of_scope: \(.out_of_scope_noticed | length)",
    ($i[] | select(.verdict == "fail" or .verdict == "tool-covered")
       | [(.n | tostring), .verdict, (.location | cut), (.note | cut)] | map(one_line) | join("\t")),
    (.out_of_scope_noticed[] | dw_row);

.[0]
| if $kind == "implementation" then table_implementation
  elif $kind == "integration" then table_integration
  else table_mini_review end
JQ

file=""
kind=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --kind)
      [[ $# -ge 2 ]] || usage
      kind=$2
      shift
      ;;
    -*) usage ;;
    *)
      [[ -z $file ]] || usage
      file=$1
      ;;
  esac
  shift
done
[[ -n $file ]] || usage
command -v jq >/dev/null 2>&1 || die "jq not found"
command -v yq >/dev/null 2>&1 || die "yq not found (mikefarah yq v4 required)"
yq --version 2>&1 | grep -q 'mikefarah' || die "yq is not mikefarah yq v4"
[[ -f $file ]] || die "no such file: $file"
[[ -r $file ]] || die "cannot read: $file"

if [[ -z $kind ]]; then
  kind=$(kind_from_name "$file")
  [[ -n $kind ]] || die "cannot tell the kind from the name $(basename "$file"); pass --kind implementation|integration|mini-review"
fi
case "$kind" in
  implementation | integration | mini-review) ;;
  *) die "unknown kind '$kind' (implementation, integration or mini-review)" ;;
esac

json=$(yq -o=json '.' "$file" 2>&1) || die "cannot parse YAML in $file: $(printf '%s' "$json" | head -n 1)"
folder=$(artifacts_folder "$file")

errors=$(printf '%s\n' "$json" | jq -r -s --arg kind "$kind" --arg folder "$folder" "$JQ_DEFS $JQ_CHECK") ||
  die "jq failed while checking $file"
if [[ -n $errors ]]; then
  printf '%s\n' "$errors"
  exit 1
fi
printf '%s\n' "$json" | jq -r -s --arg kind "$kind" "$JQ_DEFS $JQ_TABLE" || die "jq failed while printing $file"
