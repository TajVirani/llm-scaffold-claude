#!/usr/bin/env bash
# Suite: lint over the step files that call the issue-tracking scripts, and the packaging of the issue-tracking skill.
# Covers: spec 00014. Each call is matched by its script name and command, in the text of the step that holds it, never by
#   prose wording. JRN-001: discovery 0.1.1 calls next-spec-number.sh and 0.1.4 names `tracker_issue`. JRN-005: an
#   `issue-tracker.sh fill` call at 0.3.19, at 0.6 (ready-for-dev on the full path), at 0.3.20 (ready-for-dev on the light
#   path) and in a sign-off step (5.1-5.9).
#   JRN-006: 2.6 and 0.3.20 each file the task issues with `issue-tracker.sh create-task` and record them with
#   `set-task ... --issue`. JRN-007: `issue-tracker.sh move ... in_progress` at 3.1 (the spec's issue) and 3.3 (a task's),
#   `move ... done` at 3.16 (a merged task) and 5.8 (the spec, on a local merge), and the reopen `move ... in_progress` at
#   3.9, 3.11 and 4.7, where a task goes back to work. JRN-014: project-setup's SKILL.md or modules run
#   `tracker-setup.sh check` and `tracker-setup.sh save`; .agents/skills/issue-tracking/SKILL.md exists and its frontmatter
#   name is issue-tracking; .agents/install-manifest.txt lists skills/issue-tracking and PROVENANCE.md names it.
# Step text: a step id's text, in any modules/*.md file, starts at a heading whose title opens with the id or an id range
#   ending in it ("## 3.10-3.11 ...") or names it in parentheses ("### 6.3 Rework attempts remain (4.7 Yes)"), and runs to
#   the next heading of the same or a higher level; or it starts at a bold label opening a line or list item with the id
#   ("1. **0.1.1 Scan.**", "- **3.11 Yes, ...**") and runs to the next heading or the next such label of any step. Fenced
#   code inside the text counts, since that is where calls are written. A step held in several places is the union of them.
#   The scripts the calls name are shellcheck-clean. Reads the repo; writes nothing.
# shellcheck disable=SC2016,SC2034,SC2329  # check expressions are single-quoted and eval'd on purpose, and read variables and call helpers shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

MODULES_DIR=$FW_SKILL/modules
SETUP_DIR=$AGENTS_SRC/skills/project-setup
ISSUE_TRACKING_DIR=$AGENTS_SRC/skills/issue-tracking

# step_text ID : print the text of step ID from every step file that holds it, by the rule in the header.
step_text() {
  local file
  for file in "$MODULES_DIR"/*.md; do
    awk -v id="$1" '
      function starts_with_id(text,    rest) {
        if (index(text, id) != 1) return 0
        rest = substr(text, length(id) + 1)
        return rest == "" || rest ~ /^[ :*)]/ || rest ~ /^\.([^0-9]|$)/
      }
      function heading_holds(title,    lead, ends, n) {
        if (starts_with_id(title)) return 1
        if (match(title, /^[0-9]+(\.[0-9]+)+(-|–)[0-9]+(\.[0-9]+)+/)) {
          lead = substr(title, 1, RLENGTH)
          gsub(/–/, "-", lead)
          n = split(lead, ends, "-")
          if (ends[1] "" == id "" || ends[n] "" == id "") return 1
        }
        return index(title, "(" id " ") > 0 || index(title, "(" id ")") > 0
      }
      /^[[:space:]]*```/ { if (insec) print; fenced = !fenced; next }
      fenced { if (insec) print; next }
      /^#+ / {
        match($0, /^#+/); lvl = RLENGTH
        title = substr($0, lvl + 2)
        if (insec == "bold" || (insec == "heading" && lvl <= seclvl)) insec = ""
        if (!insec && heading_holds(title)) { insec = "heading"; seclvl = lvl }
        if (insec) print
        next
      }
      {
        label = $0
        if (match(label, /^[[:space:]]*([0-9]+\.[[:space:]]+|[-*][[:space:]]+)?\*\*[0-9]+(\.[0-9]+)+/)) {
          sub(/^[[:space:]]*([0-9]+\.[[:space:]]+|[-*][[:space:]]+)?\*\*/, "", label)
          if (insec == "bold") insec = ""
          if (!insec && starts_with_id(label)) insec = "bold"
        }
        if (insec) print
      }
    ' "$file"
  done
}

# calls_in TEXT REGEX : true when a line of TEXT matches the extended REGEX.
calls_in() { grep -Eq -- "$2" <<<"$1"; }

FILL='issue-tracker\.sh.*[[:space:]]fill([[:space:]]|$)'
CREATE_TASK='issue-tracker\.sh.*[[:space:]]create-task([[:space:]]|$)'
SET_ISSUE='status-transition\.sh.*[[:space:]]set-task[[:space:]].*--issue([[:space:]=]|$)'
MOVE_IN_PROGRESS='issue-tracker\.sh.*[[:space:]]move[[:space:]].*[[:space:]]in_progress([^A-Za-z_]|$)'
MOVE_DONE='issue-tracker\.sh.*[[:space:]]move[[:space:]].*[[:space:]]done([^A-Za-z_]|$)'

# expect_call NAME ID REGEX : step ID's text holds a line matching REGEX.
expect_call() {
  local text
  text=$(step_text "$2")
  if [[ -z $text ]]; then
    ko "$1" "no step file holds step $2"
  elif calls_in "$text" "$3"; then
    ok "$1"
  else
    ko "$1" "step $2 has no line matching $3"
  fi
}

echo "== fixture: the step text reader finds known steps"
check "fixture: step 0.1.1's text stops before the 0.1.2 label" \
  '[[ -n $(step_text 0.1.1) ]] && ! grep -q "0.1.2 Slug" <<<"$(step_text 0.1.1)"' "$(step_text 0.1.1 | head -3)"
check "fixture: step 3.16 holds today's set-task --status done call" \
  'grep -q "set-task .* --status done --step 3.16" <<<"$(step_text 3.16)"' "$(step_text 3.16 | head -3)"
check "fixture: step 4.7 is read from its parenthesised headings" \
  'grep -q "status in-progress --step 4.7" <<<"$(step_text 4.7)"' "$(step_text 4.7 | head -3)"
check "fixture: step 3.11 is read from the 3.10-3.11 range heading and its label" '[[ -n $(step_text 3.11) ]]'

echo "== JRN-001: discovery numbers a spec with one script call"
expect_call "JRN-001 discovery 0.1.1 calls next-spec-number.sh" 0.1.1 'next-spec-number\.sh'
expect_call "JRN-001 discovery 0.1.4 writes the issue URL into tracker_issue" 0.1.4 'tracker_issue'

echo "== JRN-005: the spec is copied into its issue at each sync point"
expect_call "JRN-005 0.3.19 calls issue-tracker.sh fill" 0.3.19 "$FILL"
expect_call "JRN-005 0.6 (ready-for-dev on the full path) calls issue-tracker.sh fill" 0.6 "$FILL"
expect_call "JRN-005 0.3.20 (ready-for-dev on the light path) calls issue-tracker.sh fill" 0.3.20 "$FILL"
SIGN_OFF_TEXT=$(for id in 5.1 5.2 5.3 5.4 5.5 5.6 5.7 5.8 5.9; do step_text "$id"; done)
check "JRN-005 a sign-off step (5.1-5.9) calls issue-tracker.sh fill" 'calls_in "$SIGN_OFF_TEXT" "$FILL"' \
  "no sign-off step has a line matching $FILL"

echo "== JRN-006: task issues are filed and recorded once the breakdown is within budget"
for id in 2.6 0.3.20; do
  expect_call "JRN-006 $id files each task issue with issue-tracker.sh create-task" "$id" "$CREATE_TASK"
  expect_call "JRN-006 $id records each task issue with set-task --issue" "$id" "$SET_ISSUE"
done

echo "== JRN-007: issues move through the issue flow"
expect_call "JRN-007 3.1 moves the spec's issue to in_progress" 3.1 "$MOVE_IN_PROGRESS"
expect_call "JRN-007 3.3 moves each launched task's issue to in_progress" 3.3 "$MOVE_IN_PROGRESS"
expect_call "JRN-007 3.16 moves each merged task's issue to done" 3.16 "$MOVE_DONE"
expect_call "JRN-007 5.8 moves the spec's issue to done" 5.8 "$MOVE_DONE"
for id in 3.9 3.11 4.7; do
  expect_call "JRN-007 $id moves a reopened task's issue back to in_progress" "$id" "$MOVE_IN_PROGRESS"
done

echo "== JRN-014: project-setup's tracker step and the skill's packaging"
SETUP_TEXT=$(cat "$SETUP_DIR/SKILL.md" "$SETUP_DIR"/modules/*.md)
check "JRN-014 project-setup runs tracker-setup.sh check" 'calls_in "$SETUP_TEXT" "tracker-setup\.sh.*[[:space:]]check([[:space:]]|$)"'
check "JRN-014 project-setup runs tracker-setup.sh save" 'calls_in "$SETUP_TEXT" "tracker-setup\.sh.*[[:space:]]save([[:space:]]|$)"'
eq "JRN-014 the issue-tracking skill has a SKILL.md named issue-tracking" \
  "$(yq --front-matter=extract '.name' "$ISSUE_TRACKING_DIR/SKILL.md" 2>/dev/null)" issue-tracking
check "JRN-014 the install manifest lists skills/issue-tracking" \
  'grep -qx "skills/issue-tracking/\{0,1\}" "$AGENTS_SRC/install-manifest.txt"'
check "JRN-014 PROVENANCE.md names skills/issue-tracking" 'grep -qF "skills/issue-tracking" "$REPO_ROOT/PROVENANCE.md"'

shellcheck_files "shellcheck: the scripts the step files call" "$FW_SKILL/scripts/next-spec-number.sh" \
  "$ISSUE_TRACKING_DIR/scripts/issue-tracker.sh" "$ISSUE_TRACKING_DIR/scripts/tracker-setup.sh"
finish
