#!/usr/bin/env bash
# File: Helper script (not a hook): check the shape of one Phase 4 lens's review-findings file and print a bounded table of it.
# Purpose: Triage (4.4) reads each lens's findings through this script instead of reading the whole block, so a malformed block is
#   caught before triage and the orchestrator sees one header line and one row per finding. The script only reads the file.
#   Lens: the file's `lens` field, which is required and must be review-standards, review-end-state or review-targets; when the file
#   name is a lens name (`<lens>.yaml`), the two must agree. The lens sets the id prefix (RS, RE, RT) and the allowed categories.
#   Pass: the file's `pass` field when present, else the `pass-<n>` directory the file sits in
#   (`.workflow/specs/NNN-slug/artifacts/review/pass-<n>/<lens>.yaml`); when both are present they must agree.
# Usage:
#   check-review-findings.sh <file>
#     <file>   a review-findings YAML file; needs no spec dir.
# Shape rules (each failure is one line on stdout, `<field>: <problem>`, the field written as `findings[<i>].<key>`,
#   `measurements[<i>].<key>` or a top-level key):
#   - lens as above; status is done or blocked; findings is a list.
#   - findings ids are unique and match <PFX>-<n> (RS for review-standards, RE for review-end-state, RT for review-targets).
#   - category is one the lens may use: review-standards standard, rule, profile, placement, naming, smell; review-end-state
#     missing, unasked, wrong; review-targets target; any lens discovered-work.
#   - a discovered-work finding has kind (bug, requirement, refactor, scope-expansion, decision), summary, evidence,
#     blocker_assessment (blocks-this-task, can-wait) and reason, all non-empty.
#   - any other finding has severity (high, medium, low), confidence an integer from 80 to 100 (lower is never reported),
#     and a non-empty location and claim.
#   - checked, not_checked and not_verifiable, when present, are lists.
#   - review-targets only: measurements is a list; each row has a non-empty target, a result of pass, fail or not_measurable,
#     a non-empty measured unless not_measurable, and a non-empty reason when not_measurable.
# stdout on exit 0, the header line then tab-separated rows:
#   lens: <name>  pass: <n>  findings: <t> (high <h>, medium <m>, low <l>)  discovered_work: <k>  checked: <c>  not_checked: <nc>  not_verifiable: <nv>
#   id  category  severity  confidence  location  claim          (column names, then one row per finding, in file order)
#   findings counts only the graded findings (t = h + m + l); discovered-work findings are counted apart and their rows show
#   severity, confidence and location as "-" and the claim as "<kind>, <blocker_assessment>: <summary>". The claim is cut to
#   120 characters; tabs and line breaks inside a value become spaces.
#   review-targets also prints the column names target, measured, verdict and one row per measurements entry (verdict is its
#   result; measured is cut to 120 characters).
# Exit: 0 the shape is valid and the table was printed; 1 one or more shape errors (one line each on stdout, nothing else);
#   2 usage error, missing or unreadable file, YAML that does not parse, or missing jq or mikefarah yq v4 (message on stderr).
# Called by: modules/review-triage.md (step 3, after the lenses return).
# Notes: bash 3.2 compatible; needs jq and mikefarah yq v4.
# Sources: first-party.

set -euo pipefail

PROG=check-review-findings.sh

# die MSG : print "<prog>: MSG" to stderr and exit 2.
die() { printf '%s: %s\n' "$PROG" "$1" >&2; exit 2; }

# usage : print the usage line to stderr and exit 2.
usage() {
  echo "usage: $PROG <file>" >&2
  exit 2
}

# path_lens FILE : print the file name without its .yaml or .yml extension.
path_lens() {
  local name
  name=$(basename "$1")
  name=${name%.yaml}
  printf '%s\n' "${name%.yml}"
}

# path_pass FILE : print <n> when the file's directory is named pass-<n>, else nothing.
path_pass() {
  local dir
  dir=$(basename "$(dirname "$1")")
  if [[ $dir =~ ^pass-([0-9]+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
  fi
}

# The jq programs read the file as a one-element array (jq -s), so a multi-document file is caught as a shape error.
# Definitions both programs share: the lens table and small value helpers.
read -r -d '' JQ_DEFS <<'JQ' || true
def lenses: {
  "review-standards": {prefix: "RS", categories: ["standard", "rule", "profile", "placement", "naming", "smell"]},
  "review-end-state": {prefix: "RE", categories: ["missing", "unasked", "wrong"]},
  "review-targets":   {prefix: "RT", categories: ["target"]}
};
def text: if . == null then "" else tostring end;
def filled: (text | length) > 0;
def one_line: text | gsub("[\t\r\n]+"; " ");
def cut: one_line | .[0:120];
def file_lens: (.lens // "") | text;
def is_list: type == "array";
def list_len: if is_list then length else 0 end;
def dw: .category == "discovered-work";
def one_of($set): text as $v | any($set[]; . == $v);
JQ

# Each rule emits zero or more "<field>: <problem>" lines.
read -r -d '' JQ_CHECK <<'JQ' || true
def check_root($path_lens; $path_pass):
  (file_lens as $lens
   | if $lens == "" then "lens: missing"
     elif (lenses | has($lens)) | not then "lens: '\($lens)' is not review-standards, review-end-state or review-targets"
     elif (lenses | has($path_lens)) and $path_lens != $lens then "lens: '\($lens)' does not match the file name \($path_lens).yaml"
     else empty end),
  (if has("pass") then
     (if ((.pass | type) == "number" and .pass == (.pass | floor) and .pass >= 1) | not then "pass: '\(.pass | text)' is not a positive integer"
      elif $path_pass != "" and (.pass | tostring) != $path_pass then "pass: \(.pass) does not match the directory pass-\($path_pass)"
      else empty end)
   elif $path_pass == "" then "pass: no pass field and the file is not in a pass-<n> directory"
   else empty end),
  (if (.status | one_of(["done", "blocked"])) then empty
   else "status: '\(.status | text)' is not done or blocked" end),
  (if (.findings | is_list) then empty else "findings: not a list" end),
  (["checked", "not_checked", "not_verifiable"][] as $k
     | if has($k) and ((.[$k] | is_list) | not) then "\($k): not a list" else empty end);

def check_dw($at):
  (if (.kind | one_of(["bug", "requirement", "refactor", "scope-expansion", "decision"])) then empty
   else "\($at).kind: '\(.kind | text)' is not bug, requirement, refactor, scope-expansion or decision" end),
  (["summary", "evidence", "reason"][] as $k | if (.[$k] | filled) then empty else "\($at).\($k): missing or empty" end),
  (if (.blocker_assessment | one_of(["blocks-this-task", "can-wait"])) then empty
   else "\($at).blocker_assessment: '\(.blocker_assessment | text)' is not blocks-this-task or can-wait" end);

def check_graded($at):
  (if (.severity | one_of(["high", "medium", "low"])) then empty
   else "\($at).severity: '\(.severity | text)' is not high, medium or low" end),
  (.confidence as $c
   | if ($c | type) != "number" or $c != ($c | floor) or $c < 0 or $c > 100 then "\($at).confidence: '\($c | text)' is not an integer from 0 to 100"
     elif $c < 80 then "\($at).confidence: \($c) is below the 80 cutoff"
     else empty end),
  (["location", "claim"][] as $k | if (.[$k] | filled) then empty else "\($at).\($k): missing or empty" end);

def check_finding($lens; $i):
  "findings[\($i)]" as $at
  | if type != "object" then "\($at): not a mapping"
    else
      (if ((.id | text) | test("^" + $lens.prefix + "-[0-9]+$")) then empty
       else "\($at).id: '\(.id | text)' does not match \($lens.prefix)-<n>" end),
      (if dw or (.category | one_of($lens.categories)) then empty
       else "\($at).category: '\(.category | text)' is not one of \(($lens.categories + ["discovered-work"]) | join(", "))" end),
      (if dw then check_dw($at) else check_graded($at) end)
    end;

def check_findings($lens):
  if (.findings | is_list) | not then empty
  else
    (.findings | to_entries[] | .key as $i | .value | check_finding($lens; $i)),
    ([.findings[] | select(type == "object") | .id | text | select(. != "")]
       | group_by(.)[] | select(length > 1) | "findings: id \(.[0]) appears \(length) times")
  end;

def check_measurement($i):
  "measurements[\($i)]" as $at
  | if type != "object" then "\($at): not a mapping"
    else
      (if (.target | filled) then empty else "\($at).target: missing or empty" end),
      (if (.result | one_of(["pass", "fail", "not_measurable"])) then empty
       else "\($at).result: '\(.result | text)' is not pass, fail or not_measurable" end),
      (if .result == "not_measurable" then
         (if (.reason | filled) then empty else "\($at).reason: missing or empty, required when not_measurable" end)
       elif (.measured | filled) then empty
       else "\($at).measured: missing or empty" end)
    end;

def check_measurements:
  if (.measurements | is_list) | not then "measurements: not a list"
  else .measurements | to_entries[] | .key as $i | .value | check_measurement($i) end;

if length != 1 then "root: expected one YAML document, found \(length)"
else .[0]
  | if type != "object" then "root: not a mapping"
    else
      check_root($path_lens; $path_pass),
      (file_lens as $name | lenses[$name] as $lens | if $lens == null then empty
       else check_findings($lens), (if file_lens == "review-targets" then check_measurements else empty end) end)
    end
end
JQ

# Runs only on a file that passed the check, so every field it reads has the right shape.
read -r -d '' JQ_TABLE <<'JQ' || true
.[0]
| [.findings[] | select(dw | not)] as $graded
| def count($sev): [$graded[] | select(.severity == $sev)] | length;
  "lens: \(file_lens)  pass: \(if has("pass") then .pass else $path_pass end)  findings: \($graded | length) (high \(count("high")), medium \(count("medium")), low \(count("low")))  discovered_work: \([.findings[] | select(dw)] | length)  checked: \(.checked | list_len)  not_checked: \(.not_checked | list_len)  not_verifiable: \(.not_verifiable | list_len)",
  (["id", "category", "severity", "confidence", "location", "claim"] | join("\t")),
  (.findings[]
     | if dw then [.id, .category, "-", "-", "-", ("\(.kind), \(.blocker_assessment): \(.summary | text)" | cut)]
       else [.id, .category, .severity, (.confidence | tostring), (.location | one_line), (.claim | cut)] end
     | map(one_line) | join("\t")),
  (if file_lens == "review-targets" then
     (["target", "measured", "verdict"] | join("\t")),
     (.measurements[] | [(.target | one_line), (.measured | cut), .result] | join("\t"))
   else empty end)
JQ

[[ $# -eq 1 ]] || usage
file=$1
[[ -n $file ]] || usage
command -v jq >/dev/null 2>&1 || die "jq not found"
command -v yq >/dev/null 2>&1 || die "yq not found (mikefarah yq v4 required)"
yq --version 2>&1 | grep -q 'mikefarah' || die "yq is not mikefarah yq v4"
[[ -f $file ]] || die "no such file: $file"
[[ -r $file ]] || die "cannot read: $file"

json=$(yq -o=json '.' "$file" 2>&1) || die "cannot parse YAML in $file: $(printf '%s' "$json" | head -n 1)"
plens=$(path_lens "$file")
ppass=$(path_pass "$file")

errors=$(printf '%s\n' "$json" | jq -r -s --arg path_lens "$plens" --arg path_pass "$ppass" "$JQ_DEFS $JQ_CHECK") ||
  die "jq failed while checking $file"
if [[ -n $errors ]]; then
  printf '%s\n' "$errors"
  exit 1
fi
printf '%s\n' "$json" | jq -r -s --arg path_pass "$ppass" "$JQ_DEFS $JQ_TABLE" || die "jq failed while printing $file"
