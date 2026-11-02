#!/usr/bin/env bash
# Suite: lint over the feature-workflow text and data that wire the small path: the router's sizing (0.0.3) and routing,
#   the "On the small path:" notes in the step files it changes, "Leave the small path" in the questioning loop, the
#   review-combined launch in modules/review-triage.md, the spec.md template's small_path key and validator, and the 0.0.3
#   and 4.10 rows of references/steps.tsv.
# Covers: JRN-007. The template validator accepts the template, a small-path spec (small_path and light_path true) and a
#   spec written before the key existed, and refuses small_path without light_path or a small_path that is not a boolean.
#   SKILL.md has no modules or progressive_loading frontmatter key, sizes 0.0.3 after the trivial-edit question and
#   loads discovery alone from it, still reads small_path when routing, names no small-path.md and links the leave
#   section in questioning-loop.md; modules/small-path.md is gone. discovery.md, discovery-impact.md, questioning-loop.md
#   and sign-off.md each carry an "On the small path:" note; discovery launches no library-evaluation on the small path
#   and its 0.3.3 note links the leave section; the questioning loop folds the deeper prompt and the summary into the one
#   round and holds the leave section (its log line, the late library-evaluation and the 0.3.19 small_path: false);
#   sign-off gives the five-line report, carries the retrospective lessons at 5.5 and asks nothing more at 5.7.
#   review-triage launches one review-combined on the light path at 4.10 and keeps the four lenses for the full path;
#   the Codex section of references/launching.md names the combined review's task_name.
#   steps.tsv has 0.0.3 as intake and 4.10 on the light track right after 4.9, with the four lenses on the full track.
#   Reads the repo; writes only to a scratch dir.
# shellcheck disable=SC2016,SC2034,SC2329  # check expressions are single-quoted and eval'd on purpose, and read variables and call helpers shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
new_workdir

SKILL=$FW_SKILL/SKILL.md
MODULES=$FW_SKILL/modules
DISCOVERY=$MODULES/discovery.md
LOOP=$MODULES/questioning-loop.md
SIGN_OFF=$MODULES/sign-off.md
TRIAGE=$MODULES/review-triage.md
LAUNCHING=$FW_SKILL/references/launching.md
TEMPLATE=$FW_SKILL/assets/spec.md
TSV=$FW_SKILL/references/steps.tsv

# section FILE NAME : the text of the `## <NAME>` section (heading alone or followed by more words, with or without a
#   leading section number such as "2. "), to the next `## `. Empty when FILE does not exist.
section() {
  [ -f "$1" ] || return 0
  awk -v id="$2" '
    /^## / {
      if (on) exit
      t = $0; sub(/^## /, "", t); bare = t; sub(/^[0-9]+\. /, "", bare)
      if (t == id || index(t, id " ") == 1 || bare == id || index(bare, id " ") == 1) { on = 1; next }
    }
    on' "$1"
}

echo "== spec.md template: small_path and its validator"
awk '/yq --front-matter=extract -e .$/ { on = 1; next } on && /^  . \.workflow\/specs/ { exit } on' "$TEMPLATE" >"$WORK/spec-validator.yq"
check "the validator was found in the template" '[ -s "$WORK/spec-validator.yq" ]'
check "the validator checks small_path" 'grep -q "small_path" "$WORK/spec-validator.yq"'
spec_valid() { yq --front-matter=extract -e "$(cat "$WORK/spec-validator.yq")" "$1" >/dev/null 2>&1; }
# variant NAME YQ-EXPR : a copy of the template with YQ-EXPR applied to its frontmatter, at $WORK/NAME.md.
variant() { cp "$TEMPLATE" "$WORK/$1.md" && yq --front-matter=process -i "$2" "$WORK/$1.md"; }
eq "the template ships small_path: false" "$(yq --front-matter=extract '.small_path' "$TEMPLATE")" "false"
check "the template passes its validator" 'spec_valid "$TEMPLATE"'
variant small '.small_path = true | .light_path = true'
check "a small-path spec (small_path and light_path true) passes" 'spec_valid "$WORK/small.md"'
variant older 'del(.small_path)'
check "a spec without small_path (written before the key) passes" 'spec_valid "$WORK/older.md"'
variant small-not-light '.small_path = true | .light_path = false'
check "small_path true with light_path false is refused" '! spec_valid "$WORK/small-not-light.md"'
variant small-string '.small_path = "yes" | .light_path = true'
check "a small_path that is not a boolean is refused" '! spec_valid "$WORK/small-string.md"'

echo "== SKILL.md: frontmatter, sizing and routing"
eq "the frontmatter has no modules key" "$(yq --front-matter=extract 'has("modules")' "$SKILL")" "false"
eq "the frontmatter has no progressive_loading key" "$(yq --front-matter=extract 'has("progressive_loading")' "$SKILL")" "false"
size=$(section "$SKILL" "Size the request")
check "0.0.1 No goes to 0.0.3" 'grep -qE "\*\*No:\*\* go to 0\.0\.3" <<<"$size"' "$size"
check "Size the request asks 0.0.3 small path?" 'grep -qi "0\.0\.3: small path?" <<<"$size"'
check "0.0.3 names the file, the cause and the test" 'grep -i "0\.0\.3" <<<"$size" | grep -i "file" | grep -i "cause" | grep -qi "test"'
check "0.0.3 Yes loads discovery alone" \
  'grep -E "^- \*\*Yes:\*\*" <<<"$size" | grep -q "modules/discovery.md" && ! grep -E "^- \*\*Yes:\*\*" <<<"$size" | grep -q "small-path"' "$size"
route=$(section "$SKILL" "Route by status")
check "the route reads small_path from spec.md" 'grep -q "\.small_path // false" <<<"$route"'
check "the in-review row resumes the light path at 4.10" 'grep -E "^\| .in-review. \| otherwise" <<<"$route" | grep -q "4\.10"'
check "the router names no small-path.md" '! grep -q "small-path\.md" "$SKILL"' "$(grep -n "small-path\.md" "$SKILL")"
check "the router links the leave section in questioning-loop.md" 'grep -q "modules/questioning-loop\.md#leave-the-small-path" "$SKILL"'
check "modules/small-path.md is gone" '[ ! -e "$MODULES/small-path.md" ]'

echo "== the small-path notes in the step files"
for step_file in discovery discovery-impact questioning-loop sign-off; do
  check "$step_file.md has an \"On the small path:\" note" 'grep -q "On the small path:" "$MODULES/$step_file.md" 2>/dev/null'
done
check "0.1.4 on the small path sets small_path and light_path" \
  'section "$DISCOVERY" "0.1" | grep "small_path: true" | grep -q "light_path: true"'
check "discovery launches no library-evaluation on the small path" 'grep -q "no .library-evaluation." "$DISCOVERY"'
check "discovery's small-path note links the leave section" 'grep -q "questioning-loop\.md#leave-the-small-path" "$DISCOVERY"'
check "the deeper prompt is the first question of the round" 'grep -i "first question" "$LOOP" | grep -qi "deeper prompt"'
check "the summary confirmation is the last question of the round" 'grep -qi "last question" "$LOOP"'

echo "== questioning-loop.md: Leave the small path"
check "questioning-loop.md has the Leave the small path heading" 'grep -qx "## Leave the small path" "$LOOP"'
leave=$(section "$LOOP" "Leave the small path")
check "leaving logs a Left the small path line" 'grep -q "Left the small path: <reason>" <<<"$leave"'
check "leaving launches the skipped library-evaluation" 'grep -q "library-evaluation" <<<"$leave"'
check "leaving writes small_path: false at 0.3.19" 'grep "0\.3\.19" <<<"$leave" | grep -q "small_path: false"'

echo "== sign-off.md: the short report and the folded retrospective"
# The short report is the fenced markdown block that opens with its title line.
report=$(awk '/^[[:space:]]*```markdown/ { block = ""; on = 1; next } on && /^[[:space:]]*```/ { if (block ~ /# Report: <feature title>/) { printf "%s", block; exit } on = 0; next } on { block = block $0 "\n" }' "$SIGN_OFF")
for line in Changed Tests Findings "Known gaps" Merge; do
  check "the short report has a $line line" 'grep -qE "^[[:space:]]*- \*\*$line:\*\*" <<<"$report"'
done
eq "the short report is five lines under its title" "$(grep -cE '^[[:space:]]*- \*\*[A-Za-z ]+:\*\*' <<<"$report")" "5"
check "5.5 carries the retrospective lessons" 'grep -q "Retrospective lessons approved at 5.5" "$SIGN_OFF"'
check "5.7 asks nothing beyond the 5.5 answers" 'section "$SIGN_OFF" "5.7" | grep -qi "ask nothing"'

echo "== review-triage: the combined review on the light path"
launch=$(section "$TRIAGE" "2. Launch the four lenses")
check "the launch section names 4.10" 'grep -q "4\.10" <<<"$launch"'
check "the light path launches review-combined" 'grep -i "light path" <<<"$launch" | grep -q "task_type: review-combined"'
check "launching.md gives the combined review its Codex name" \
  'section "$LAUNCHING" "Codex" | grep -F "\`review-combined\`" | grep -qF "\`s<NNN>_review_combined\`"'
check "the full path keeps the four lenses" \
  'grep -q "Launch .review-standards., .review-end-state., .review-targets. and .review-lessons. together" <<<"$launch"'

echo "== steps.tsv rows"
row() { grep -v '^#' "$TSV" | awk -F'\t' -v id="$1" '($1 "") == (id "") { print $2 "/" $3 }'; }
eq "0.0.3 is an intake step" "$(row 0.0.3)" "-/intake"
eq "4.10 is on the light track" "$(row 4.10)" "4/light"
eq "4.10 comes right after 4.9" "$(grep -v '^#' "$TSV" | cut -f1 | grep -A1 -x '4\.9' | tail -n 1)" "4.10"
for lens in 4.1 4.2 4.3 4.9; do
  eq "lens $lens is on the full track" "$(row "$lens")" "4/full"
done

shellcheck_files "shellcheck: small-path-docs suite" "$TESTS_DIR/lint/small-path-docs.sh"
finish
