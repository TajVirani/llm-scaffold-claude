#!/usr/bin/env bash
# Suite: lint of the review-lessons asset set: the lessons-file template and its oracles, and the standards lens that checks
#   the lessons.
# Covers: JRN-008: the template exists, its own validate: command accepts it and its next-id: command prints RL-001, and
#   project-setup's file table creates .workflow/review-lessons.md from it. JRN-006: a file with RL-001 validates and its next id
#   is RL-002, retiring the entry keeps the id taken, and each broken entry (retired without enforced_by, a repeated id, empty
#   paths, an absolute path, a bad origin_spec, a bad date, lessons not a list) fails validation. review-standards reads the
#   lessons file, the pitfalls, the retrospectives' process lessons and the spec's accepted gaps, and carries the lesson category
#   and lesson: field; the review-lessons agent, its manifest line, README entry, Codex toml and 4.9 step row are gone, and the
#   manifest's agent count still matches. Reads the repo; writes only to a scratch dir.
# shellcheck disable=SC2016,SC2329,SC2034  # check expressions are single-quoted and eval'd on purpose; helpers and variables are read inside them
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/review-lessons.sh
source "$TESTS_DIR/fixtures/review-lessons.sh"
preflight
new_workdir

TEMPLATE=$REPO_ROOT/$LESSONS_TEMPLATE_REL
STANDARDS=$AGENTS_SRC/agents/review-standards.md
MANIFEST=$AGENTS_SRC/install-manifest.txt
FILES_TABLE=$AGENTS_SRC/skills/project-setup/modules/files.md
TSV=$FW_SKILL/references/steps.tsv

# validates FILE : the template's validate: command accepts FILE.
validates() { run_template_command validate "$1" >/dev/null 2>&1; }
# rejects FILE : the template's validate: command exists and refuses FILE (a missing command is not a rejection).
rejects() {
  local rc
  [ -n "$(template_command validate)" ] || return 1
  run_template_command validate "$1" >/dev/null 2>&1
  rc=$?
  [ "$rc" -ne 0 ]
}
next_id() { run_template_command next-id "$1" 2>/dev/null; }

echo "== JRN-008: template and project-setup row"
check "JRN-008 the template exists" '[ -f "$TEMPLATE" ]' "$TEMPLATE"
check "JRN-008 the template header has a validate: command" '[ -n "$(template_command validate)" ]'
check "JRN-008 the template header has a next-id: command" '[ -n "$(template_command next-id)" ]'
check "JRN-008 the template validates with its own command" 'validates "$TEMPLATE"' "$(run_template_command validate "$TEMPLATE" 2>&1)"
eq "JRN-008 the template's next id is RL-001" "$(next_id "$TEMPLATE")" "RL-001"
row=$(grep -E '^\| *`\.workflow/review-lessons\.md` *\|' "$FILES_TABLE")
check "JRN-008 files.md has a row for .workflow/review-lessons.md" '[ -n "$row" ]'
check "JRN-008 that row's source is the feature-workflow template" \
  '[[ $(cut -d"|" -f3 <<<"$row") == *"$LESSONS_TEMPLATE_REL"* ]]' "$row"

echo "== JRN-006: entries, retirement and the next id"
L=$WORK/lessons
review_lessons_file "$L/one.md" "$(lesson_rl001)"
check "JRN-006 a file with RL-001 validates" 'validates "$L/one.md"' "$(run_template_command validate "$L/one.md" 2>&1)"
eq "JRN-006 the next id after RL-001 is RL-002" "$(next_id "$L/one.md")" "RL-002"
review_lessons_file "$L/retired.md" "$(lesson_rl001_retired)"
check "JRN-006 the retired entry still validates" 'validates "$L/retired.md"' "$(run_template_command validate "$L/retired.md" 2>&1)"
eq "JRN-006 a retired id stays taken: the next id is still RL-002" "$(next_id "$L/retired.md")" "RL-002"

review_lessons_file "$L/retired-no-enforced-by.md" "$(lesson_rl001; printf '    retired: %s' "$RL001_RETIRED")"
review_lessons_file "$L/duplicate-id.md" "$(lesson_rl001)" "$(lesson_rl001)"
review_lessons_file "$L/empty-paths.md" "$(lesson_rl001 | sed 's#^    paths: .*#    paths: []#')"
review_lessons_file "$L/absolute-path.md" "$(lesson_rl001 | sed 's#^    paths: .*#    paths: ["/src/**"]#')"
review_lessons_file "$L/bad-origin-spec.md" "$(lesson_rl001 | sed 's#^    origin_spec: .*#    origin_spec: specs/fixture#')"
review_lessons_file "$L/bad-date.md" "$(lesson_rl001 | sed 's#^    date: .*#    date: 21-10-2026#')"
lessons_block_file "$L/lessons-not-a-list.md" "lessons: {id: RL-001}"
for case in retired-no-enforced-by duplicate-id empty-paths absolute-path bad-origin-spec bad-date lessons-not-a-list; do
  check "JRN-006 validate: refuses $case" 'rejects "$L/$case.md"' "$(run_template_command validate "$L/$case.md" 2>&1)"
done

echo "== the standards lens checks the lessons; no lessons lens is left"
check "review-standards reads .workflow/review-lessons.md" 'grep -q "\`.workflow/review-lessons.md\`" "$STANDARDS"'
check "review-standards reads the pitfalls and the retrospectives' process lessons" \
  'grep -q "decisions/pitfalls.md" "$STANDARDS" && grep -q "Process lessons" "$STANDARDS"'
check "review-standards lists the lesson category and the lesson: field" \
  'grep -q "| lesson | discovered-work" "$STANDARDS" && grep -qE "^    lesson: \"RL-001\"" "$STANDARDS"'
check "review-standards reads the spec's accepted gaps" 'grep -q "Assumptions.*Non-goals.*Known gaps" "$STANDARDS"'
check "agents/review-lessons.md is gone" '[ ! -e "$AGENTS_SRC/agents/review-lessons.md" ]'
check "install-manifest.txt does not list agents/review-lessons.md" '! grep -qx "agents/review-lessons.md" "$MANIFEST"'
agents_header=$(grep -E '^# --- Agents \([0-9]+\)$' "$MANIFEST")
eq "the Agents header counts the agent lines" "$(grep -oE '[0-9]+' <<<"$agents_header")" "$(grep -c '^agents/' "$MANIFEST")"
check "README.md does not name a review-lessons lens" '! grep -q "\`review-lessons\`" "$REPO_ROOT/README.md"'
check "steps.tsv has no 4.9 row" '! grep -qE "^4\.9	" "$TSV"'

copy_agents "$WORK/codex"
t "generate-codex-agents.sh runs on a fixture copy" 0 "$WORK/codex/.agents/hooks/generate-codex-agents.sh"
check "it emits no review_lessons.toml" '[ ! -e "$WORK/codex/.codex/agents/review_lessons.toml" ]'
check "it emits review_standards.toml" '[ -f "$WORK/codex/.codex/agents/review_standards.toml" ]'

shellcheck_files "shellcheck: review-lessons suite and fixtures" "$TESTS_DIR/lint/review-lessons.sh" "$TESTS_DIR/fixtures/review-lessons.sh"
finish
