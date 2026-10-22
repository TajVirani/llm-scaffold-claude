#!/usr/bin/env bash
# Suite: emission of a settled slice as a spec; JRN-003 "Emit a slice as a seeded spec".
# Covers: settling every question of S1 through initiative-transition.sh set-question; the emission sequence replayed as the large
#   path fixes it (next spec number, discovery 0.1.4 through status-transition.sh with `initiative:` in the frontmatter, a Why from
#   the slice, a design-log Origin entry carrying the binding decisions, set-slice to emitted, the reference table, a folder-scoped
#   initiative commit); the spec.md validator from assets/spec.md admitting the `initiative` key as an optional string.
# shellcheck disable=SC2016,SC2329  # check expressions are single-quoted and eval'd on purpose, and call helpers shellcheck cannot see
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/initiative.sh
source "$TESTS_DIR/fixtures/initiative.sh"
preflight

new_workdir
P=$WORK/proj
large_path_repo "$P"
seed_initiative "$P" 001 storage-overhaul
INI=.workflow/initiatives/001-storage-overhaul
BR=initiative/001-storage-overhaul
IT() { initiative_transition "$P" "$@"; }
question() { fm "$P/$INI/questions.md" ".questions[] | select(.id == \"$1\") | $2"; }
slice() { fm "$P/$INI/initiative.md" ".slices[] | select(.id == \"$1\") | $2"; }

# The spec.md validator is the yq expression in the template's "Validate the frontmatter" block.
awk '/yq --front-matter=extract -e .$/ { on = 1; next } on && /^  . \.workflow\/specs/ { exit } on' \
  "$P/$FW_ASSETS_REL/spec.md" >"$WORK/spec-validator.yq"
spec_valid() { yq --front-matter=extract -e "$(cat "$WORK/spec-validator.yq")" "$1" >/dev/null 2>&1; }

echo "== JRN-003 settle every question of S1"
IT set-question "$INI" IQ1 --state researching --launched research >/dev/null 2>&1
IT set-question "$INI" IQ1 --state settled --settled "https://example.org/storage-survey#formats" >/dev/null 2>&1
IT set-question "$INI" IQ3 --state settled --settled "The platform team owns the core flow." >/dev/null 2>&1
eq "JRN-003 every question of S1 is settled" "$(fm "$P/$INI/questions.md" '[.questions[] | select(.id == "IQ1" or .id == "IQ3") | .state] | join(" ")')" "settled settled"

echo "== JRN-003 emission, replayed"
NUM=$(next_spec_number "$P")
eq "JRN-003 the emitted spec takes the next spec number" "$NUM" 002
SPEC_NAME=$NUM-core-flow
SPEC=.workflow/specs/$SPEC_NAME
mkdir -p "$P/$SPEC"
spec_transition "$P" step "$SPEC" 0.1.4 >/dev/null 2>&1
{
  sed -n '1,/^---$/p' "$P/$FW_ASSETS_REL/spec.md"
  printf '\n# Core flow\n\n## Why\n\nOrigin: initiative 001-storage-overhaul, slice S1 (Core flow). Move the core flow to the adopted storage format.\n'
} >"$P/$SPEC/spec.md"
yq --front-matter=process -i '.initiative = "001-storage-overhaul"' "$P/$SPEC/spec.md"
spec_transition "$P" status "$SPEC" draft --step 0.1.4 >/dev/null 2>&1
{
  printf '# Design log: Core flow\n\nSpec: [spec.md](spec.md)\n\n'
  printf '## 2026-10-21 Origin: initiative 001-storage-overhaul, slice S1\n\n- Initiative: %s\n- Slice: S1 Core flow\n- Binding decisions:\n' "$INI"
  fm "$P/$INI/questions.md" '.questions[] | select(.id == "IQ1" or .id == "IQ3") | "  - " + .id + ": " + (.settled // "")'
} >"$P/$SPEC/design-log.md"
IT set-slice "$INI" S1 --status emitted --spec "$SPEC_NAME" >/dev/null 2>&1
printf '\n## Specs\n\n| Slice | Spec |\n| --- | --- |\n| S1 Core flow | [%s](../../specs/%s/spec.md) |\n' "$SPEC_NAME" "$SPEC_NAME" >>"$P/$INI/initiative.md"
git -C "$P" add "$INI" && git -C "$P" commit -q -m "initiative 001-storage-overhaul: emitted S1 as $SPEC_NAME"

echo "== JRN-003 the new spec"
check "JRN-003 the spec folder exists" '[ -f "$P/$SPEC/spec.md" ]'
eq "JRN-003 spec.md carries its initiative" "$(fm "$P/$SPEC/spec.md" .initiative)" 001-storage-overhaul
eq "JRN-003 the spec is a draft" "$(fm "$P/$SPEC/spec.md" .status)" draft
check "JRN-003 the Why is drafted from the slice" 'grep -q "^Origin: initiative 001-storage-overhaul, slice S1" "$P/$SPEC/spec.md"'
check "JRN-003 the design log opens with an Origin entry naming the initiative and slice" \
  'grep -q "^## .* Origin: initiative 001-storage-overhaul, slice S1" "$P/$SPEC/design-log.md"'
check "JRN-003 the Origin entry carries the binding decisions" \
  'grep -qF "IQ1: https://example.org/storage-survey#formats" "$P/$SPEC/design-log.md" && grep -qF "IQ3: The platform team owns the core flow." "$P/$SPEC/design-log.md"' \
  "$(cat "$P/$SPEC/design-log.md")"
check "JRN-003 the spec validator accepts the new spec" 'spec_valid "$P/$SPEC/spec.md"'
check "JRN-003 the spec validator names the initiative key" 'grep -q "\.initiative" "$WORK/spec-validator.yq"' "$(cat "$WORK/spec-validator.yq")"
cp "$P/$SPEC/spec.md" "$WORK/bad-initiative.md"
yq --front-matter=process -i '.initiative = ["001-storage-overhaul"]' "$WORK/bad-initiative.md"
check "JRN-003 the spec validator rejects an initiative that is not a string" '! spec_valid "$WORK/bad-initiative.md"'
check "JRN-003 the spec template documents the initiative key" 'grep -q "^#\{0,1\} *initiative:" "$P/$FW_ASSETS_REL/spec.md"'

echo "== JRN-003 the initiative after emission"
eq "JRN-003 S1 is emitted" "$(slice S1 .status)" emitted
eq "JRN-003 S1 names its spec" "$(slice S1 .spec)" "$SPEC_NAME"
eq "JRN-003 S2 is still planned" "$(slice S2 .status)" planned
check "JRN-003 the reference table links the spec" 'grep -qF "](../../specs/$SPEC_NAME/spec.md)" "$P/$INI/initiative.md"'
eq "JRN-003 the emission commit holds only initiative files" \
  "$(git -C "$P" show --name-only --format= HEAD | grep -v '^\.workflow/initiatives/')" ""
check "JRN-003 the emission commit lists initiative.md" 'git -C "$P" show --name-only --format= HEAD | grep -qx "$INI/initiative.md"'
eq "JRN-003 the spec folder stays uncommitted in the working tree" "$(git -C "$P" status --porcelain -- "$SPEC" | cut -c1-2 | sort -u)" "??"
eq "JRN-003 the session stays on the initiative branch" "$(git -C "$P" branch --show-current)" "$BR"
eq "JRN-003 the next spec number counts the emitted slice" "$(next_spec_number "$P")" 003

shellcheck_files "JRN-003 shellcheck emission components" "$P/$IT_REL" "$P/$ST_REL"
finish
