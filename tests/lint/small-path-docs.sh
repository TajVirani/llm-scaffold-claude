#!/usr/bin/env bash
# Suite: lint over the feature-workflow text and data that wire the small path: SKILL.md sizing (0.0.3) and routing,
#   modules/small-path.md, the review-combined launch in modules/review-triage.md, the spec.md template's small_path key and
#   validator, and the 0.0.3 and 4.10 rows of references/steps.tsv.
# Covers: the template validator accepts the template, a small-path spec (small_path and light_path true) and a spec written
#   before the key existed, and refuses small_path without light_path or a small_path that is not a boolean. SKILL.md lists
#   the module in its frontmatter, sizes 0.0.3 after the trivial-edit question and loads the module from it, routes a spec
#   with small_path true to the module beside the phase module, and has a Modules row for it. small-path.md has the leave
#   section SKILL.md links to, every relative link in it resolves, it skips library-evaluation, folds the deeper prompt and
#   the summary into the one round, and gives the five-line report and the folded retrospective. review-triage launches one
#   review-combined on the light path at 4.10 and keeps the four lenses for the full path. steps.tsv has 0.0.3 as intake and
#   4.10 on the light track right after 4.9, with the four lenses on the full track. Reads the repo; writes only to a scratch dir.
# shellcheck disable=SC2016,SC2034,SC2329  # check expressions are single-quoted and eval'd on purpose, and read variables and call helpers shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
new_workdir

SKILL=$FW_SKILL/SKILL.md
SMALL=$FW_SKILL/modules/small-path.md
TRIAGE=$FW_SKILL/modules/review-triage.md
TEMPLATE=$FW_SKILL/assets/spec.md
TSV=$FW_SKILL/references/steps.tsv

# section FILE HEADING : the text of the `## <HEADING>` section (heading alone or followed by more words), to the next `## `.
section() {
  awk -v id="$2" '
    /^## / { if (on) exit; t = $0; sub(/^## /, "", t); if (t == id || index(t, id " ") == 1) { on = 1; next } }
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

echo "== SKILL.md: sizing and routing"
eq "the frontmatter modules list names small-path" "$(yq --front-matter=extract '.modules[] | select(. == "small-path")' "$SKILL")" "small-path"
size=$(section "$SKILL" "2. Size the request")
check "0.0.1 No goes to 0.0.3" 'grep -qE "\*\*No:\*\* go to 0\.0\.3" <<<"$size"' "$size"
check "Size the request asks 0.0.3 small path?" 'grep -qi "0\.0\.3: small path?" <<<"$size"'
check "0.0.3 names the file, the cause and the test" 'grep -i "0\.0\.3" <<<"$size" | grep -i "file" | grep -i "cause" | grep -qi "test"'
check "0.0.3 Yes loads modules/small-path.md" 'grep -E "^- \*\*Yes:\*\*" <<<"$size" | grep -q "modules/small-path.md"'
route=$(section "$SKILL" "3. Route by status")
check "the route reads small_path from spec.md" 'grep -q "\.small_path // false" <<<"$route"'
check "the route loads small-path beside the module the table names" 'grep -i "small_path" <<<"$route" | grep -q "modules/small-path.md"'
check "the in-review row resumes the light path at 4.10" 'grep -E "^\| .in-review. \| otherwise" <<<"$route" | grep -q "4\.10"'
check "the Modules table has a small-path row" 'grep -qE "^\| \[small-path\]\(modules/small-path\.md\) \|" "$SKILL"'
check "the leave anchor SKILL.md links to is a heading in small-path.md" \
  'grep -q "small-path.md#leave-the-small-path" "$SKILL" && grep -qx "## Leave the small path" "$SMALL"'

echo "== modules/small-path.md"
check "small-path.md exists" '[ -f "$SMALL" ]'
broken=""
while IFS= read -r link; do
  target=${link%%#*}
  [ -e "$FW_SKILL/modules/$target" ] || broken="$broken $link"
done < <(awk '/^ *```/ { fenced = !fenced; next } !fenced' "$SMALL" | grep -oE '\]\([^)#:]+(#[^)]*)?\)' | sed -E 's/^\]\(//; s/\)$//')
eq "every relative link outside code blocks in small-path.md resolves" "$broken" ""
phase0=$(section "$SMALL" "Phase 0")
check "Phase 0 sets small_path and light_path at 0.1.4" 'grep "0\.1\.4" <<<"$phase0" | grep "small_path: true" | grep -q "light_path: true"'
check "Phase 0 launches no library-evaluation" 'grep -q "no .library-evaluation." <<<"$phase0"'
check "the deeper prompt is the first question of the round" 'grep -i "first question" <<<"$phase0" | grep -qi "deeper prompt"'
check "the summary confirmation is the last question of the round" 'grep -qi "last question" <<<"$phase0"'
leave=$(section "$SMALL" "Leave the small path")
check "leaving logs a Left the small path line" 'grep -q "Left the small path: <reason>" <<<"$leave"'
check "leaving writes small_path: false at 0.3.19" 'grep "0\.3\.19" <<<"$leave" | grep -q "small_path: false"'
phase5=$(section "$SMALL" "Phase 5")
for line in Changed Tests Findings "Known gaps" Merge; do
  check "the short report has a $line line" 'grep -qE "^   - \*\*$line:\*\*" <<<"$phase5"'
done
eq "the short report is five lines under its title" "$(grep -cE '^   - \*\*[A-Za-z ]+:\*\*' <<<"$phase5")" "5"
check "5.5 carries the retrospective lessons" 'grep -q "Retrospective lessons approved at 5.5" <<<"$phase5"'
check "5.7 asks nothing beyond the 5.5 answers" 'grep "5\.7" <<<"$phase5" | grep -qi "ask nothing"'

echo "== review-triage: the combined review on the light path"
launch=$(section "$TRIAGE" "2. Launch the four lenses")
check "the launch section names 4.10" 'grep -q "4\.10" <<<"$launch"'
check "the light path launches review-combined" 'grep -i "light path" <<<"$launch" | grep -q "task_type: review-combined"'
check "the Codex name for the combined review" 'grep -q "s<NNN>_review_combined" <<<"$launch"'
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
