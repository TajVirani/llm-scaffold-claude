#!/usr/bin/env bash
# File: Fixture builders and oracles for the review-lessons suites (the lessons file, the standards lens's pass file for a
#   repeated lesson, the live-run repo).
#   Sourced after lib/common.sh; defines variables and functions only. bash 3.2 compatible.
# Provides:
#   RL001_ID, RL001_SYMPTOM, RL001_PATHS, RL001_ORIGIN_SPEC, RL001_DATE   the fixture lesson, the only lesson text the harness uses
#   RL001_RETIRED, RL001_ENFORCED_BY                                       the fields a retirement adds to it
#   LESSONS_TEMPLATE_REL           the template's path relative to the project root
#   lesson_rl001                   prints the RL-001 entry as an item of the lessons list
#   lesson_rl001_retired           prints the same entry retired (keeps its id, adds retired and enforced_by)
#   lessons_block_file FILE BLOCK  writes a lessons file in the template shape: header comment, then BLOCK in a yaml fence
#   review_lessons_file FILE [ENTRY...]   writes a lessons file whose list holds the given entries (lessons: [] when none)
#   REPORT_REPEAT, REPORT_CLEAN    the two versions of src/report.sh: one repeats RL-001, one checks the file first
#   REPORT_REPEAT_LINE             the line of REPORT_REPEAT that repeats the lesson
#   review_lessons_repo DIR [repeat|clean]   self-contained git repo for a live review-standards run (DIR is the caller's, never removed here)
#   expected_lens_block FILE [BASE HEAD]     writes the review-standards pass file the lens should write for the repeat repo
#   template_command NAME [TEMPLATE]         prints the validate: or next-id: command from the template's header comment
#   run_template_command NAME FILE [TEMPLATE] runs that command on FILE; exit 127 with a message when it is missing
# shellcheck disable=SC2034,SC2016  # the variables are read by the suites that source this file; $1 in the scripts is literal

RL001_ID=RL-001
RL001_SYMPTOM='A script under `src/` opens a file path taken from its arguments without first checking the file exists, so a missing file surfaces as a confusing error far from the call.'
RL001_PATHS='["src/**"]'
RL001_ORIGIN_SPEC=.workflow/specs/001-fixture
RL001_DATE=2026-10-21
RL001_RETIRED=2026-10-22
RL001_ENFORCED_BY='.workflow/rules.md § Cross-cutting policy, line 4'

LESSONS_TEMPLATE_REL=.agents/skills/feature-workflow/assets/review-lessons.md

lesson_rl001() {
  printf '  - id: %s\n    symptom: "%s"\n    paths: %s\n    origin_spec: %s\n    date: %s\n' \
    "$RL001_ID" "$RL001_SYMPTOM" "$RL001_PATHS" "$RL001_ORIGIN_SPEC" "$RL001_DATE"
}

lesson_rl001_retired() {
  lesson_rl001
  printf '    retired: %s\n    enforced_by: "%s"\n' "$RL001_RETIRED" "$RL001_ENFORCED_BY"
}

# The header stands in for the template's rule text; the oracles always come from the template itself, never from here.
lessons_block_file() {
  mkdir -p "$(dirname "$1")"
  {
    printf '<!--\nFile: review lessons (fixture). Entry rules: see the template.\n-->\n# Review lessons\n\n'
    printf '```yaml\n%s\n```\n' "$2"
  } >"$1"
}

review_lessons_file() {
  local file=$1 block entry
  shift
  if [ $# -eq 0 ]; then
    block='lessons: []'
  else
    block='lessons:'
    for entry in "$@"; do block=$(printf '%s\n%s' "$block" "$entry"); done
  fi
  lessons_block_file "$file" "$block"
}

REPORT_REPEAT='#!/usr/bin/env bash
# Prints the report file named by the first argument.
set -euo pipefail
cat "$1"'
REPORT_CLEAN='#!/usr/bin/env bash
# Prints the report file named by the first argument.
set -euo pipefail
[[ -f "$1" ]] || { echo "report.sh: no such file: $1" >&2; exit 1; }
cat "$1"'
REPORT_REPEAT_LINE=$(printf '%s\n' "$REPORT_REPEAT" | grep -n '^cat "\$1"$' | cut -d: -f1)

# The lens is launched against this repo by hand, so everything it reads is inside it: the agents, the rules, the pitfalls,
# the lessons file and a spec whose baseline_revision is the commit before the change under review.
review_lessons_repo() {
  local p=$1 variant=${2:-repeat} report base
  case "$variant" in
    repeat) report=$REPORT_REPEAT ;;
    clean) report=$REPORT_CLEAN ;;
    *) echo "review_lessons_repo: variant must be repeat or clean, got '$variant'" >&2; return 2 ;;
  esac
  git_init_repo "$p"
  copy_agents "$p"
  mkdir -p "$p/.workflow/decisions" "$p/.workflow/specs/001-fixture"
  cp "$p/.agents/skills/project-setup/assets/docs/rules.md" "$p/.workflow/rules.md"
  cp "$p/.agents/skills/project-setup/assets/docs/decisions/pitfalls.md" "$p/.workflow/decisions/pitfalls.md"
  cat >"$p/.workflow/model-map.yaml" <<'M'
review-standards:
  tier: cheap
  claude: haiku
  codex: gpt-6-luna
  why: Judges a diff against written standards and recorded lessons.
M
  review_lessons_file "$p/.workflow/review-lessons.md" "$(lesson_rl001)"
  printf '%s\n' '.workflow/specs/*/.step' >"$p/.gitignore"
  git_commit_all "$p" "fixture: project with one review lesson"
  base=$(git -C "$p" rev-parse HEAD)
  git -C "$p" switch -q -c spec/001-fixture
  cp "$p/.agents/skills/feature-workflow/assets/spec.md" "$p/.workflow/specs/001-fixture/spec.md"
  FIXTURE_BASE=$base yq --front-matter=process -i \
    '.status = "in-review" | .baseline_revision = strenv(FIXTURE_BASE) | .spec_branch = "spec/001-fixture"' \
    "$p/.workflow/specs/001-fixture/spec.md"
  git_commit_all "$p" "spec 001-fixture"
  mkdir -p "$p/src"
  printf '%s\n' "$report" >"$p/src/report.sh"
  chmod +x "$p/src/report.sh"
  git_commit_all "$p" "add src/report.sh"
}

expected_lens_block() {
  local file=$1
  local base=${2:-1111111111111111111111111111111111111111} head=${3:-2222222222222222222222222222222222222222}
  mkdir -p "$(dirname "$file")"
  cat >"$file" <<EOF
lens: review-standards
status: done
blocked_reason: ""
baseline_revision: "$base"
head: "$head"
findings:
  - id: RS-1
    category: lesson
    lesson: $RL001_ID
    severity: high
    confidence: 90
    location: "src/report.sh:$REPORT_REPEAT_LINE"
    claim: "src/report.sh reads the file named by its first argument without checking that it exists, repeating review lesson $RL001_ID."
    consequence: "A missing report file fails inside cat with a bare error, far from the caller that passed the wrong path."
    evidence:
      basis: ".workflow/review-lessons.md $RL001_ID: \"$RL001_SYMPTOM\""
      diff: "+cat \"\$1\""
    suggested_fix: "Check the path with [[ -f \"\$1\" ]] and exit with a message naming it before reading."
checked: ["diff $base...$head", ".workflow/review-lessons.md", ".workflow/decisions/pitfalls.md"]
not_checked: []
EOF
}

template_command() {
  local template=${2:-$REPO_ROOT/$LESSONS_TEMPLATE_REL}
  [ -f "$template" ] || return 0
  sed -n "s/^$1: //p" "$template" | head -n 1
}

run_template_command() {
  local cmd
  cmd=$(template_command "$1" "${3:-}")
  if [ -z "$cmd" ]; then
    echo "no '$1:' line in the template header" >&2
    return 127
  fi
  bash -c "$cmd" _ "$2"
}
