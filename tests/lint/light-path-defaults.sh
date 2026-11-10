#!/usr/bin/env bash
# Suite: lint over the feature-workflow text and data behind the light path's defaults, which took over from the retired
#   small path: sizing in the router, library evaluation only when needed at 0.2.5, one questioning round unless a question
#   stays open, the five-line report, the combined review at 4.10, and the spec.md template with no small_path key.
# Covers: the router sizes with the trivial-edit question alone and its No loads discovery; no file under .agents/ names
#   the small path or small_path, and modules/small-path.md is gone; steps.tsv has no 0.0.3 row. The spec.md template has no
#   small_path key, and its validator still accepts a finished spec that carries small_path: true. discovery.md launches
#   library-evaluation only when the request names a new library, SDK or external API or a concern has no approved library
#   in the work profile, and otherwise writes a "Not evaluated:" line; the questioning loop launches it late when an answer
#   brings in a library, and runs a second round only when a question stays open. sign-off.md's short report is five lines.
#   review-triage launches one review-combined on the light path at 4.10 and the three lenses on the full path; launching.md
#   names the combined review's Codex task_name; steps.tsv has 4.10 on the light track right after 4.3.
#   Reads the repo; writes only to a scratch dir.
# shellcheck disable=SC2016,SC2034  # check expressions are single-quoted and eval'd on purpose, and read variables shellcheck cannot see
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

echo "== the small path is gone"
size=$(section "$SKILL" "2. Size the request")
check "0.0.1 No loads discovery" 'grep -E "^- \*\*No:\*\*" <<<"$size" | grep -q "modules/discovery.md"' "$size"
check "the router asks no 0.0.3" '! grep -q "0\.0\.3" "$SKILL"'
names=$(grep -rliE "small[ -]path|small_path" "$AGENTS_SRC" 2>/dev/null || true) # no match is the passing case
eq "no file under .agents/ names the small path" "$names" ""
check "modules/small-path.md is gone" '[ ! -e "$MODULES/small-path.md" ]'
check "steps.tsv has no 0.0.3 row" '! grep -q "^0\.0\.3	" "$TSV"'

echo "== spec.md template"
awk '/yq --front-matter=extract -e .$/ { on = 1; next } on && /^  . \.workflow\/specs/ { exit } on' "$TEMPLATE" >"$WORK/spec-validator.yq"
check "the validator was found in the template" '[ -s "$WORK/spec-validator.yq" ]'
check "the template has no small_path key" '[ "$(yq --front-matter=extract ".small_path // \"absent\"" "$TEMPLATE")" = absent ]'
cp "$TEMPLATE" "$WORK/old-small.md"
yq --front-matter=process -i '.small_path = true | .light_path = true' "$WORK/old-small.md"
check "a finished spec carrying small_path: true still validates" \
  'yq --front-matter=extract -e "$(cat "$WORK/spec-validator.yq")" "$WORK/old-small.md" >/dev/null'

echo "== discovery: library evaluation only when needed"
check "0.2.5 asks whether library evaluation is needed" 'grep -q "Is library evaluation needed?" "$DISCOVERY"'
need=$(grep "Is library evaluation needed?" "$DISCOVERY")
check "a library, SDK or external API the request names" 'grep -q "library, SDK or external API" <<<"$need"' "$need"
check "a concern with no approved library in the work profile" 'grep -q "Approved libraries per concern" <<<"$need"' "$need"
check "otherwise one Not evaluated line" 'grep -q "Not evaluated: <why>" "$DISCOVERY"'
check "the loop launches it when an answer brings in a library" \
  'grep "did not evaluate" "$LOOP" | grep -q "library-evaluation"'

echo "== questioning loop: one round unless a question stays open"
check "0.3.18 runs a second round only when a question stays open" \
  'grep "0\.3\.18" "$LOOP" | grep -q "second round only when a question stays open"'

echo "== sign-off.md: the short report"
# The short report is the fenced markdown block that opens with its title line.
report=$(awk '/^[[:space:]]*```markdown/ { block = ""; on = 1; next } on && /^[[:space:]]*```/ { if (block ~ /# Report: <feature title>/) { printf "%s", block; exit } on = 0; next } on { block = block $0 "\n" }' "$SIGN_OFF")
for line in Changed Tests Findings "Known gaps" Merge; do
  check "the short report has a $line line" 'grep -qE "^[[:space:]]*- \*\*$line:\*\*" <<<"$report"'
done
eq "the short report is five lines under its title" "$(grep -cE '^[[:space:]]*- \*\*[A-Za-z ]+:\*\*' <<<"$report")" "5"

echo "== review-triage: the combined review on the light path"
launch=$(section "$TRIAGE" "2. Launch the three lenses")
check "the launch section names 4.10" 'grep -q "4\.10" <<<"$launch"'
check "the light path launches review-combined" 'grep -i "light path" <<<"$launch" | grep -q "task_type: review-combined"'
check "launching.md gives the combined review its Codex name" \
  'section "$LAUNCHING" "Codex" | grep -F "\`review-combined\`" | grep -qF "\`s<NNN>_review_combined\`"'
check "the full path keeps the three lenses" \
  'grep -q "Launch .review-standards., .review-end-state. and .review-targets. together" <<<"$launch"'

echo "== steps.tsv rows"
row() { grep -v '^#' "$TSV" | awk -F'\t' -v id="$1" '($1 "") == (id "") { print $2 "/" $3 }'; }
eq "4.10 is on the light track" "$(row 4.10)" "4/light"
eq "4.10 comes right after 4.3" "$(grep -v '^#' "$TSV" | cut -f1 | grep -A1 -x '4\.3' | tail -n 1)" "4.10"
for lens in 4.1 4.2 4.3; do
  eq "lens $lens is on the full track" "$(row "$lens")" "4/full"
done

shellcheck_files "shellcheck: light-path-defaults suite" "$TESTS_DIR/lint/light-path-defaults.sh"
finish
