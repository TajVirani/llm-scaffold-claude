#!/usr/bin/env bash
# Suite: lint over the feature-workflow text that wires the Done folder into sign-off: modules/sign-off.md 5.4, 5.7 and 5.8,
#   modules/large-path.md 6.13, references/conventions.md, the check-pr-body.sh header, the PR template and review-lessons
#   template headers.
# Covers: JRN-001: 5.7 runs `move-to-done.sh --check .workflow/specs/NNN-slug` before the `status ... done --step 5.7` call and
#   says to stop, listing what is open, when it fails. JRN-006: 5.8 runs, in this order, the commit of what is left, the
#   check-pr-body.sh run on the top-level pr-body.md, the move (`move-to-done.sh .workflow/specs/NNN-slug`), check-pr-body.sh on
#   `.workflow/specs/done/NNN-slug/pr-body.md`, and the `<!-- 5.8 publish commands -->` marker; it publishes on the 5.5
#   approval and asks for no go-ahead; a paragraph says a fault on the moved body stops sign-off unpublished as a move bug;
#   between the post-move check and the marker no line tells the main session to fix, Edit or log anything; the marker stays
#   directly above the fenced publish block. 5.4 says 5.8 publishes the body unchanged apart from the spec path, and no line in
#   sign-off.md, the check-pr-body.sh header or the PR template still says the body is published unchanged without naming the
#   spec path. The conventions name move-to-done.sh; large-path 6.13 names the Done folder; the review-lessons template's
#   origin_spec rule names the Done folder. The checks match the design's intent, not exact prose. Reads the repo; writes
#   nothing.
# shellcheck disable=SC2016,SC2034,SC2329  # check expressions are single-quoted and eval'd on purpose, and read variables and call helpers shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

SIGN_OFF=$FW_SKILL/modules/sign-off.md
LARGE_PATH=$FW_SKILL/modules/large-path.md
MARKER='<!-- 5.8 publish commands -->'

# step_section FILE HEADING : print the text of the `## <HEADING>` or `### <HEADING>` section (the heading alone or followed
#   by more words), up to the next heading of the same or a higher level.
step_section() {
  awk -v id="$2" '
    function level(line) { match(line, /^#+/); return RLENGTH }
    /^#+ / {
      title = $0
      sub(/^#+ /, "", title)
      if (!insec && (title == id || index(title, id " ") == 1)) { insec = 1; lvl = level($0); next }
      if (insec && level($0) <= lvl) exit
    }
    insec
  ' "$1"
}

# first_pos TEXT REGEX : print the character position in TEXT where the extended REGEX first matches; nothing when it never
#   matches. Positions, not line numbers, so two steps written in one sentence still have an order.
first_pos() {
  awk -v re="$2" '{ if (match($0, re)) { print off + RSTART; exit } off += length($0) + 1 }' <<<"$1"
}

# text_between TEXT FROM TO : print TEXT from character position FROM up to TO, counted the way first_pos counts.
text_between() {
  awk -v from="$2" -v to="$3" '{ all = all $0 "\n" } END { print substr(all, from, to - from) }' <<<"$1"
}

# in_order A B : true when both positions are set and A comes before B.
in_order() { [[ -n $1 && -n $2 && $1 -lt $2 ]]; }

# paragraphs_with TEXT REGEX... : print each blank-line-separated paragraph of TEXT that matches every extended REGEX,
#   ignoring case.
paragraphs_with() {
  local text=$1
  shift
  PARAGRAPH_RES=$(printf '%s\n' "$@") awk '
    BEGIN { RS = ""; n = split(ENVIRON["PARAGRAPH_RES"], want, "\n") }
    { p = tolower($0); hit = 1; for (i = 1; i <= n; i++) if (want[i] != "" && p !~ tolower(want[i])) hit = 0; if (hit) { print; print "" } }
  ' <<<"$text"
}

# stale_unchanged_lines FILE... : print each line that says the PR body is published unchanged without naming the spec path.
stale_unchanged_lines() { grep -Hn -i 'unchanged' "$@" | grep -i 'publish' | grep -vi 'spec path'; }

echo "== JRN-001: 5.7 checks the sub-items before done"
S57=$(step_section "$SIGN_OFF" 5.7)
P_CHECK=$(first_pos "$S57" 'move-to-done\.sh --check \.workflow/specs/NNN-slug')
P_DONE=$(first_pos "$S57" 'status \.workflow/specs/NNN-slug done --step 5\.7')
check "JRN-001 5.7 runs move-to-done.sh --check on the spec" '[[ -n $P_CHECK ]]'
check "JRN-001 5.7 runs the check before the done status call" 'in_order "$P_CHECK" "$P_DONE"' \
  "check at ${P_CHECK:-none}, done call at ${P_DONE:-none}"
check "JRN-001 5.7 says to stop and list what is open when the check fails" \
  '[[ -n $(paragraphs_with "$S57" "stop" "open" "exit|fail") ]]'

echo "== JRN-006: 5.8 moves the spec between the two body checks"
S58=$(step_section "$SIGN_OFF" 5.8)
P_COMMIT=$(first_pos "$S58" '[Cc]ommit what is left')
P_PRE=$(first_pos "$S58" 'check-pr-body\.sh')
P_MOVE=$(first_pos "$S58" 'move-to-done\.sh \.workflow/specs/NNN-slug')
P_POST=$(first_pos "$S58" 'check-pr-body\.sh[^|]*\.workflow/specs/done/NNN-slug/pr-body\.md')
P_MARKER=$(first_pos "$S58" '<!-- 5\.8 publish commands -->')
check "JRN-006 5.8 commits what is left before the first body check" 'in_order "$P_COMMIT" "$P_PRE"' \
  "commit at ${P_COMMIT:-none}, check at ${P_PRE:-none}"
check "JRN-006 5.8 runs the move (move-to-done.sh .workflow/specs/NNN-slug) after the first body check" \
  'in_order "$P_PRE" "$P_MOVE"' "check at ${P_PRE:-none}, move at ${P_MOVE:-none}"
check "JRN-006 5.8 runs check-pr-body.sh on .workflow/specs/done/NNN-slug/pr-body.md after the move" \
  'in_order "$P_MOVE" "$P_POST"' "move at ${P_MOVE:-none}, moved-body check at ${P_POST:-none}"
check "JRN-006 5.8 checks the moved body before the publish marker" 'in_order "$P_POST" "$P_MARKER"' \
  "moved-body check at ${P_POST:-none}, marker at ${P_MARKER:-none}"
check "5.8 publishes on the 5.5 approval, asking for no go-ahead" \
  '[[ -n $(paragraphs_with "$S58" "5\\.5 approval" "go-ahead" "ask nothing") ]]'
check "JRN-006 5.8 stops sign-off unpublished on a fault in the moved body, as a move bug" \
  '[[ -n $(paragraphs_with "$S58" "move bug" "stop" "publish") ]]'
AFTER_MOVE=""
in_order "$P_POST" "$P_MARKER" && AFTER_MOVE=$(text_between "$S58" "$P_POST" "$P_MARKER")
WRITE_INSTRUCTION='fix each line|(^|[^a-z])Edit |log the answer|ask the 5\.5'
check "JRN-006 between the moved-body check and the publish block no line tells the main session to fix, Edit or log" \
  '[[ -n $AFTER_MOVE ]] && ! grep -Eq "$WRITE_INSTRUCTION" <<<"$AFTER_MOVE"' \
  "$(grep -E "$WRITE_INSTRUCTION" <<<"$AFTER_MOVE" | head -3)"
NEXT_AFTER_MARKER=$(awk -v m="$MARKER" 'found && NF { print; exit } index($0, m) { found = 1 }' "$SIGN_OFF")
check "JRN-006 the publish marker stays directly above the fenced publish block" \
  '[[ $NEXT_AFTER_MARKER =~ ^[[:space:]]*\`\`\`bash[[:space:]]*$ ]]' "line after the marker: $NEXT_AFTER_MARKER"

echo "== JRN-006: the published body is the approved one apart from the spec path"
S54_PUBLISH=$(step_section "$SIGN_OFF" 5.4 | grep -i '5\.8 publishes')
check "JRN-006 5.4 says 5.8 publishes the body unchanged apart from the spec path" \
  '[[ -n $S54_PUBLISH ]] && ! grep -vqi "spec path" <<<"$S54_PUBLISH"' "$S54_PUBLISH"
STALE=$(stale_unchanged_lines "$SIGN_OFF" "$FW_SKILL/scripts/check-pr-body.sh" "$FW_SKILL/assets/pr-template.md")
check "JRN-006 no line says the body is published unchanged without naming the spec path" '[[ -z $STALE ]]' "$STALE"

echo "== the rest of the workflow names the Done folder"
check "the conventions name move-to-done.sh" 'grep -q "move-to-done\.sh" "$FW_SKILL/references/conventions.md"'
check "large-path 6.13 names the Done folder" 'step_section "$LARGE_PATH" 6.13 | grep -q "specs/done"'
check "JRN-004 the review-lessons template's origin_spec rule names the Done folder" \
  'grep -E "^[[:space:]]*- origin_spec:" "$FW_SKILL/assets/review-lessons.md" | grep -q "specs/done"'

finish
