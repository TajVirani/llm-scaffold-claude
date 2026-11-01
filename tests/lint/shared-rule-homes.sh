#!/usr/bin/env bash
# Suite: lint that each rule every feature-workflow step file shares is written in one file only.
# Covers: JRN-006. Each shared rule's marker (listed below with the reason it was picked) appears in exactly one of
#   SKILL.md, references/conventions.md, references/launching.md and modules/*.md (large-path.md included); the
#   escalation-class line only in modules/discovered-work.md and the "## Leave the small path" heading only in
#   modules/questioning-loop.md; modules/small-path.md does not exist; and the guarded-writes table, wherever it lives,
#   gives each guarded file the steps scripts/check-write.sh allows it. Reads the repo only.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
new_workdir

CHECK_WRITE=$FW_SKILL/scripts/check-write.sh
TABLE_HEADER="| File | Allowed steps |"

# One marker per shared rule: "<rule>|<marker>|<the one file that must hold it, or any>". Each marker is text the rule
# carries today and keeps word for word wherever it moves, so finding it twice means the rule was copied.
#   one writer and exit codes: the exit-code sentence of the status-transition.sh call forms.
#   set the step then write: the sentence that opens the guarded-writes rule.
#   guarded-writes table: the table's header row.
#   progress line: the sentence that opens the progress-line rule.
#   sub-agent writes: the rule's bold label, which also opens the initiative scope of the same rule.
#   launch header: the sentence that opens the launching rule.
#   host launch rows: the reason the Codex launch row gives for fork_turns, which step files repeat today, and the
#     sentence that names the Codex spawn hook.
#   Codex write-guard row: the advisory clause of the check-write.sh row.
#   escalation classes: the scope-expanding class line of the proven-first rule; it belongs in discovered-work.md.
#   leave the small path: the section heading; it belongs in questioning-loop.md, where the triggers run.
MARKERS='one writer and exit codes|Exit 0 done; 1 environment error|any
set the step then write|These files are written only from the main session, only at these steps.|any
guarded-writes table|TABLE_HEADER|any
progress line|Lead every phase or step update|any
sub-agent writes|Sub-agents write only their own result file|any
launch header|Every launch prompt starts with the launch header on its first line|any
host launch rows: fork_turns|a full-history fork may ignore the spawn `model` override|any
host launch rows: spawn hook|`hooks/codex-pre-spawn.sh` denies a malformed name|any
Codex write-guard row|write only on exit 0 (advisory)|any
escalation classes|**scope-expanding**|modules/discovered-work.md
leave the small path|## Leave the small path|modules/questioning-loop.md'

# rule_files : the files a shared rule may live in, relative to the skill folder, those that exist.
rule_files() {
  local rel
  for rel in SKILL.md references/conventions.md references/launching.md; do
    [ -f "$FW_SKILL/$rel" ] && printf '%s\n' "$rel"
  done
  (cd "$FW_SKILL" && ls modules/*.md)
}

# files_holding MARKER : the rule files that hold MARKER (a whole line when it is a heading), space-separated.
files_holding() {
  local rel found=""
  while IFS= read -r rel; do
    case "$1" in
      '#'*) grep -qxF -- "$1" "$FW_SKILL/$rel" && found="$found $rel" ;;
      *) grep -qF -- "$1" "$FW_SKILL/$rel" && found="$found $rel" ;;
    esac
  done < <(rule_files)
  printf '%s' "${found# }"
}

echo "== one home per shared rule"
while IFS='|' read -r rule marker home; do
  # The table header row holds the pipe character the list is split on, so the list names it TABLE_HEADER.
  [ "$marker" = TABLE_HEADER ] && marker="$TABLE_HEADER"
  holders=$(files_holding "$marker")
  if [ "$home" = any ]; then
    check "$rule: in exactly one file" '[ -n "$holders" ] && [ "${holders#* }" = "$holders" ]' "files: ${holders:-none}"
  else
    eq "$rule: only in $home" "$holders" "$home"
  fi
done <<<"$MARKERS"
check "modules/small-path.md no longer exists" '[ ! -e "$FW_SKILL/modules/small-path.md" ]'

echo "== the guarded-writes table matches check-write.sh"
# step_set TEXT : the step ids in TEXT, sorted, one space-separated line.
step_set() { grep -oE '\b[0-9]+\.[0-9]+(\.[0-9]+)?\b' <<<"$1" | sort -u | tr '\n' ' ' | sed 's/ $//'; }
# constant NAME : the step list check-write.sh assigns to NAME.
constant() { sed -n "s/^$1=\"\([^\"]*\)\".*/\1/p" "$CHECK_WRITE"; }

missing_constants=""
for name in SPEC_STEPS TASKS_STEPS BACKLOG_STEPS BACKLOG_SEED_STEP INITIATIVE_STEPS GLOSSARY_STEPS TIER_A_STEPS \
  PROFILE_EDIT_STEPS PROFILE_CREATE_STEPS REVIEW_LESSONS_STEPS; do
  [ -n "$(constant "$name")" ] || missing_constants="$missing_constants $name"
done
eq "check-write.sh still assigns every step constant the table is compared with" "$missing_constants" ""

table_home=$(files_holding "$TABLE_HEADER")
check "the guarded-writes table is found in one file" '[ -n "$table_home" ] && [ "${table_home#* }" = "$table_home" ]' \
  "files: ${table_home:-none}"
if [ -n "$table_home" ] && [ "${table_home#* }" = "$table_home" ]; then
  awk '/\| File \| Allowed steps \|/ { on = 1; next } on && !/^[[:space:]]*\|/ { exit } on' "$FW_SKILL/$table_home" \
    >"$WORK/table.md"
  # row_steps PATTERN : the step ids in the Allowed steps cell of the row whose File cell matches PATTERN.
  row_steps() { step_set "$(awk -F'|' -v pat="$1" '$2 ~ pat { print $3 }' "$WORK/table.md")"; }
  eq "spec.md steps" "$(row_steps '`spec\.md`')" "$(step_set "$(constant SPEC_STEPS)")"
  eq "tasks.md steps" "$(row_steps 'tasks\.md')" "$(step_set "$(constant TASKS_STEPS)")"
  eq "work-backlog steps" "$(row_steps 'work-backlog')" "$(step_set "$(constant BACKLOG_STEPS) $(constant BACKLOG_SEED_STEP)")"
  eq "initiative.md steps" "$(row_steps 'initiative\.md')" "$(step_set "$(constant INITIATIVE_STEPS)")"
  eq "glossary steps" "$(row_steps 'GLOSSARY\.md')" "$(step_set "$(constant GLOSSARY_STEPS)")"
  eq "other Tier A steps" "$(row_steps 'Other Tier A')" "$(step_set "$(constant TIER_A_STEPS)")"
  eq "work profile steps" "$(row_steps 'profiles')" \
    "$(step_set "$(constant PROFILE_EDIT_STEPS) $(constant PROFILE_CREATE_STEPS)")"
  eq "review-lessons steps" "$(row_steps 'review-lessons\.md')" "$(step_set "$(constant REVIEW_LESSONS_STEPS)")"
fi

shellcheck_files "shellcheck: shared-rule-homes suite" "$TESTS_DIR/lint/shared-rule-homes.sh"
finish
