#!/usr/bin/env bash
# Suite: lint over how much workflow text a session loads at its two heaviest load points, counted with wc -c.
# Covers: JRN-001 (a new-feature start, small path included: AGENTS.md, the session-start hook output, the feature-workflow
#   router SKILL.md, references/conventions.md, modules/discovery.md and the term-list output for this repo's glossary is
#   at most 45000 bytes), JRN-002 (an implementation resume: AGENTS.md, the same hook output, SKILL.md,
#   references/conventions.md and modules/implementation-waves.md is at most 55000 bytes) and JRN-008 (the measuring
#   function fails a load point above its limit, naming the point, its total and its limit, and names a counted file that
#   is missing). The hook output comes from a scratch repo holding one in-flight draft spec and no handoffs.
#   Each measure prints one line "<load point>: <n> bytes (limit <m>)" at the start of a line, for scripts that read the
#   totals from this suite's output. Reads the repo; writes only to a scratch dir.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/initiative.sh
source "$TESTS_DIR/fixtures/initiative.sh"
preflight
new_workdir

NEW_FEATURE_LIMIT=45000
RESUME_LIMIT=55000
FW_REL=.agents/skills/feature-workflow
TERM_LIST_REL=.agents/skills/domain-modeling/scripts/term-list.sh

# load_size ROOT LOAD_POINT LIMIT PATH... : sum wc -c over PATHs (relative ones under ROOT, absolute ones as they are) and
#   print "<load point>: <n> bytes (limit <m>)". A missing path adds a "missing: <load point> counts <path>" line and is
#   left out of the total; a total above LIMIT adds "over: <load point> <n> bytes > limit <m>". Returns 1 on either.
load_size() {
  local root=$1 point=$2 limit=$3 path file total=0 bytes failed=0 notes=""
  shift 3
  for path in "$@"; do
    case "$path" in /*) file=$path ;; *) file=$root/$path ;; esac
    if [ -f "$file" ]; then
      bytes=$(wc -c <"$file")
      total=$((total + bytes))
    else
      notes="${notes}missing: $point counts $path"$'\n'
      failed=1
    fi
  done
  printf '%s: %s bytes (limit %s)\n' "$point" "$total" "$limit"
  if [ "$total" -gt "$limit" ]; then
    notes="${notes}over: $point $total bytes > limit $limit"$'\n'
    failed=1
  fi
  printf '%s' "$notes"
  return "$failed"
}

# new_feature_paths HOOK_OUT TERM_OUT : the new-feature start's counted paths.
new_feature_paths() {
  printf '%s\n' AGENTS.md "$1" "$FW_REL/SKILL.md" "$FW_REL/references/conventions.md" "$FW_REL/modules/discovery.md" "$2"
}

# resume_paths HOOK_OUT : the implementation resume's counted paths.
resume_paths() {
  printf '%s\n' AGENTS.md "$1" "$FW_REL/SKILL.md" "$FW_REL/references/conventions.md" "$FW_REL/modules/implementation-waves.md"
}

# measure ROOT LOAD_POINT LIMIT : load_size over the paths read from stdin, one per line; sets MEASURE_OUT and MEASURE_RC.
#   Feed it by redirection, not a pipe: a piped function runs in a subshell and its variables never reach the caller.
measure() {
  local paths=() path
  while IFS= read -r path; do paths+=("$path"); done
  MEASURE_OUT=$(load_size "$1" "$2" "$3" "${paths[@]}")
  MEASURE_RC=$?
}

echo "== the measuring function on scratch roots of known size"
SYNTH=$WORK/synthetic
mkdir -p "$SYNTH/$FW_REL/references" "$SYNTH/$FW_REL/modules"
# fill FILE BYTES : FILE holding exactly BYTES bytes.
fill() { head -c "$2" /dev/zero | tr '\0' 'x' >"$1"; }
for rel in AGENTS.md "$FW_REL/SKILL.md" "$FW_REL/references/conventions.md" "$FW_REL/modules/discovery.md" \
  "$FW_REL/modules/implementation-waves.md" hook.txt terms.txt; do
  fill "$SYNTH/$rel" 1000
done
measure "$SYNTH" "new-feature start" "$NEW_FEATURE_LIMIT" < <(new_feature_paths "$SYNTH/hook.txt" "$SYNTH/terms.txt")
eq "six files of 1000 bytes are within the limit" "$MEASURE_RC" 0
eq "and print the total line only" "$MEASURE_OUT" "new-feature start: 6000 bytes (limit 45000)"

fill "$SYNTH/AGENTS.md" 50000
measure "$SYNTH" "new-feature start" "$NEW_FEATURE_LIMIT" < <(new_feature_paths "$SYNTH/hook.txt" "$SYNTH/terms.txt")
eq "a counted file padded past the limit fails the load point" "$MEASURE_RC" 1
check "the failure names the load point, its total and its limit" \
  'grep -qx "over: new-feature start 55000 bytes > limit 45000" <<<"$MEASURE_OUT"' "$MEASURE_OUT"
measure "$SYNTH" "implementation resume" "$RESUME_LIMIT" < <(resume_paths "$SYNTH/hook.txt")
eq "the same padding leaves the larger resume limit met" "$MEASURE_OUT" "implementation resume: 54000 bytes (limit 55000)"

rm "$SYNTH/$FW_REL/references/conventions.md"
measure "$SYNTH" "implementation resume" "$RESUME_LIMIT" < <(resume_paths "$SYNTH/hook.txt")
eq "a missing counted file fails the load point" "$MEASURE_RC" 1
check "the failure names the missing file and still prints the total of what exists" \
  'grep -qx "missing: implementation resume counts $FW_REL/references/conventions.md" <<<"$MEASURE_OUT" &&
   grep -qx "implementation resume: 53000 bytes (limit 55000)" <<<"$MEASURE_OUT"' "$MEASURE_OUT"

echo "== generated output: the session-start hook and the term list"
HOOK_REPO=$WORK/hook-repo
large_path_repo "$HOOK_REPO" >/dev/null 2>&1
seed_draft_spec "$HOOK_REPO" 001 alpha
resume_offer "$HOOK_REPO" >"$WORK/hook-output.txt"
check "the hook offers the one in-flight draft spec" 'grep -qF "specs/001-alpha: status draft" "$WORK/hook-output.txt"' \
  "$(cat "$WORK/hook-output.txt")"

GLOSSARY_REPO=$WORK/glossary-repo
git_init_repo "$GLOSSARY_REPO"
copy_agents "$GLOSSARY_REPO"
mkdir -p "$GLOSSARY_REPO/.workflow"
cp "$REPO_ROOT/.workflow/GLOSSARY.md" "$GLOSSARY_REPO/.workflow/GLOSSARY.md"
[ -f "$REPO_ROOT/.workflow/GLOSSARY-MAP.md" ] && cp "$REPO_ROOT/.workflow/GLOSSARY-MAP.md" "$GLOSSARY_REPO/.workflow/"
TERM_OUT=$WORK/term-list-output.txt
if [ -f "$GLOSSARY_REPO/$TERM_LIST_REL" ]; then
  (cd "$GLOSSARY_REPO" && bash "$GLOSSARY_REPO/$TERM_LIST_REL") >"$TERM_OUT" 2>/dev/null
  check "the term list prints the glossary's terms" '[ -s "$TERM_OUT" ]' "$TERM_LIST_REL printed nothing for this repo's glossary"
else
  # Counting the script's own repo path makes the measure report it as the missing piece.
  TERM_OUT=$TERM_LIST_REL
  ko "the term list prints the glossary's terms" "$TERM_LIST_REL does not exist"
fi

echo "== this repo's load points"
measure "$REPO_ROOT" "new-feature start" "$NEW_FEATURE_LIMIT" < <(new_feature_paths "$WORK/hook-output.txt" "$TERM_OUT")
printf '%s\n' "$MEASURE_OUT" | head -n 1
eq "new-feature start: every counted file exists" "$(grep '^missing: ' <<<"$MEASURE_OUT")" ""
eq "new-feature start is at most $NEW_FEATURE_LIMIT bytes" "$(grep '^over: ' <<<"$MEASURE_OUT")" ""

measure "$REPO_ROOT" "implementation resume" "$RESUME_LIMIT" < <(resume_paths "$WORK/hook-output.txt")
printf '%s\n' "$MEASURE_OUT" | head -n 1
eq "implementation resume: every counted file exists" "$(grep '^missing: ' <<<"$MEASURE_OUT")" ""
eq "implementation resume is at most $RESUME_LIMIT bytes" "$(grep '^over: ' <<<"$MEASURE_OUT")" ""

shellcheck_files "shellcheck: workflow-load-size suite" "$TESTS_DIR/lint/workflow-load-size.sh"
finish
