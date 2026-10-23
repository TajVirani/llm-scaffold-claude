#!/usr/bin/env bash
# Suite: review-lessons.sh (feature-workflow/scripts).
# Covers: validate exits 0 on the template and on a file with RL-001 or RL-001 retired, and exits 1 with one stderr line naming
#   the broken field for each broken file (retired without enforced_by, a repeated id, empty paths, an absolute path, a bad
#   origin_spec, a bad date, lessons not a list, a block that does not parse); next-id prints RL-001, RL-002 and RL-002 after retirement,
#   and exits 1 with one stderr line on a block that does not parse; exit 2 on no argument, an unknown subcommand and a missing file.
# shellcheck disable=SC2016,SC2329  # check expressions are single-quoted and eval'd on purpose; helpers run inside them
# shellcheck source=../lib/common.sh  # the path is built from BASH_SOURCE at run time, so -x needs this hint to follow it
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/review-lessons.sh  # the path is built from TESTS_DIR at run time, so -x needs this hint to follow it
source "$TESTS_DIR/fixtures/review-lessons.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
RLS="$WORK/scaffold/.agents/skills/feature-workflow/scripts/review-lessons.sh"
TEMPLATE="$WORK/scaffold/$LESSONS_TEMPLATE_REL"
L=$WORK/lessons

# run_rls ARG... : run the script, capturing stdout in OUT, stderr in ERR and the exit code in RC.
run_rls() {
  OUT=$("$RLS" "$@" 2>"$WORK/stderr")
  RC=$?
  ERR=$(cat "$WORK/stderr")
}

# one_stderr_line : true when the last run_rls wrote exactly one line to stderr.
one_stderr_line() { [[ $(printf '%s\n' "$ERR" | wc -l | tr -d ' ') -eq 1 ]]; }

# refuses_naming FILE FIELD : validate exits 1 on FILE with exactly one stderr line, and that line names FIELD.
refuses_naming() {
  run_rls validate "$1"
  [[ $RC -eq 1 && $ERR == *"$2"* ]] && one_stderr_line
}

echo "== validate accepts files that meet the entry rules"
review_lessons_file "$L/one.md" "$(lesson_rl001)"
review_lessons_file "$L/retired.md" "$(lesson_rl001_retired)"
for file in "$TEMPLATE" "$L/one.md" "$L/retired.md"; do
  run_rls validate "$file"
  check "validate accepts $(basename "$file")" '[[ $RC -eq 0 && -z $ERR ]]' "rc=$RC: $ERR"
done

echo "== validate refuses each broken file, naming the rule"
review_lessons_file "$L/retired-no-enforced-by.md" "$(lesson_rl001; printf '    retired: %s' "$RL001_RETIRED")"
review_lessons_file "$L/duplicate-id.md" "$(lesson_rl001)" "$(lesson_rl001)"
review_lessons_file "$L/empty-paths.md" "$(lesson_rl001 | sed 's#^    paths: .*#    paths: []#')"
review_lessons_file "$L/absolute-path.md" "$(lesson_rl001 | sed 's#^    paths: .*#    paths: ["/src/**"]#')"
review_lessons_file "$L/dotdot-path.md" "$(lesson_rl001 | sed 's#^    paths: .*#    paths: ["src/../etc/**"]#')"
review_lessons_file "$L/bad-origin-spec.md" "$(lesson_rl001 | sed 's#^    origin_spec: .*#    origin_spec: specs/fixture#')"
review_lessons_file "$L/bad-date.md" "$(lesson_rl001 | sed 's#^    date: .*#    date: 21-10-2026#')"
review_lessons_file "$L/bad-id.md" "$(lesson_rl001 | sed 's#^  - id: .*#  - id: RL-1#')"
review_lessons_file "$L/empty-symptom.md" "$(lesson_rl001 | sed 's#^    symptom: .*#    symptom: ""#')"
lessons_block_file "$L/lessons-not-a-list.md" "lessons: {id: RL-001}"
printf '# Review lessons\n\nNo fenced block here.\n' >"$L/no-block.md"
lessons_block_file "$L/unparsable.md" "lessons: [\"RL-001"
while IFS=' ' read -r case field; do
  check "validate refuses $case naming $field" 'refuses_naming "$L/$case.md" "$field"' "rc=$RC: $ERR"
done <<'CASES'
retired-no-enforced-by lessons[0].enforced_by
duplicate-id lessons[1].id
empty-paths lessons[0].paths
absolute-path lessons[0].paths[0]
dotdot-path lessons[0].paths[0]
bad-origin-spec lessons[0].origin_spec
bad-date lessons[0].date
bad-id lessons[0].id
empty-symptom lessons[0].symptom
lessons-not-a-list lessons:
no-block lessons:
unparsable the fenced yaml block does not parse
CASES

echo "== next-id"
run_rls next-id "$TEMPLATE"
eq "next-id on the template is RL-001" "$OUT" "RL-001"
run_rls next-id "$L/one.md"
eq "next-id after RL-001 is RL-002" "$OUT" "RL-002"
run_rls next-id "$L/retired.md"
eq "next-id after a retired RL-001 is still RL-002" "$OUT" "RL-002"
lessons_block_file "$L/high.md" "$(printf 'lessons:\n%s\n%s' "$(lesson_rl001)" "$(lesson_rl001 | sed 's#^  - id: .*#  - id: RL-999#')")"
run_rls next-id "$L/high.md"
eq "next-id after RL-999 is RL-1000" "$OUT" "RL-1000"
run_rls next-id "$L/unparsable.md"
check "next-id on a block that does not parse exits 1 with one stderr line" '[[ $RC -eq 1 && -z $OUT && $ERR == *"does not parse" ]] && one_stderr_line' "rc=$RC: $ERR"

echo "== usage and environment errors"
t "no argument exits 2" 2 "$RLS"
t "a subcommand without a file exits 2" 2 "$RLS" validate
t "an unknown subcommand exits 2" 2 "$RLS" check "$TEMPLATE"
t "validate on a missing file exits 2" 2 "$RLS" validate "$L/missing.md"
t "next-id on a missing file exits 2" 2 "$RLS" next-id "$L/missing.md"

shellcheck_files "shellcheck: review-lessons.sh and its suite" "$REPO_ROOT/.agents/skills/feature-workflow/scripts/review-lessons.sh" "$TESTS_DIR/scripts/review-lessons.sh"
finish
