#!/usr/bin/env bash
# Suite: resolve-launch.sh (feature-workflow/scripts) for launches from an initiative; JRN-008 "Launch from an initiative" (resolve part).
# Covers: --requirements listing the research task type with its spec_dir field; resolving a research launch header whose spec_dir
#   names an initiative folder (prompt and model returned, model from the research model-map entry or definition); the same for a
#   fact-lookup launch; a spec_dir naming a missing initiative folder denied; spec launches unchanged; edge cases: research from a
#   spec folder, module-audit from an initiative folder denied, an unnumbered initiative folder, a trailing slash, orchestrator mode.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
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
RL=$P/.agents/skills/feature-workflow/scripts/resolve-launch.sh

# launch TYPE SPEC_DIR : resolve a Claude launch whose header names SPEC_DIR; sets out, err and rc.
launch() {
  out=$(printf '```yaml launch-header\ntask_type: %s\nspec_dir: %s\n```\n\nAnswer IQ1 with sources.\n' "$1" "$2" \
    | bash "$RL" --host claude --task-type "$1" --project-dir "$P" 2>"$WORK/err")
  rc=$?
  err=$(cat "$WORK/err")
}

echo "== JRN-008 requirements"
req=$(bash "$RL" --requirements 2>/dev/null)
check "JRN-008 --requirements lists research" 'jq -e "has(\"research\")" <<<"$req" >/dev/null' "$(jq -r 'keys | join(", ")' <<<"$req" 2>/dev/null)"
eq "JRN-008 research requires spec_dir" "$(jq -c '.research.d31_fields' <<<"$req" 2>/dev/null)" '["spec_dir"]'
eq "JRN-008 research carries no profile" "$(jq -r '.research.profile' <<<"$req" 2>/dev/null)" none
t "JRN-008 --requirements --task-type research exits 0" 0 bash "$RL" --requirements --task-type research

echo "== JRN-008 research launch from an initiative folder"
launch research "$INI"
eq "JRN-008 the research launch resolves" "$rc" 0
check "JRN-008 the research launch returns a model" '[ -n "$(jq -r ".model // empty" <<<"$out" 2>/dev/null)" ]' "$out $err"
check "JRN-008 the research prompt keeps the header first and the body" \
  '[ "$(jq -r .prompt <<<"$out" 2>/dev/null | head -n1)" = "\`\`\`yaml launch-header" ] && jq -r .prompt <<<"$out" | grep -q "Answer IQ1 with sources."' "$out $err"
eq "JRN-008 the resolved header names the initiative folder" "$(jq -r '.header.spec_dir' <<<"$out" 2>/dev/null)" "$INI"

echo "== JRN-008 other Phase 0 types from an initiative folder"
launch fact-lookup "$INI"
eq "JRN-008 a fact-lookup launch from an initiative folder resolves" "$rc" 0

echo "== JRN-008 refusals and unchanged spec launches"
launch research .workflow/initiatives/404-missing
eq "JRN-008 a missing initiative folder is denied" "$rc" 2
launch research "$INI/questions.md"
eq "JRN-008 a spec_dir that is not an initiative folder is denied" "$rc" 2
mkdir -p "$P/.workflow/specs/002-core-flow"
launch fact-lookup .workflow/specs/002-core-flow
eq "JRN-008 a spec folder launch still resolves" "$rc" 0

echo "== JRN-008 edge and negative cases"
launch research .workflow/specs/002-core-flow
eq "JRN-008 a research launch from a spec folder resolves" "$rc" 0
launch module-audit "$INI"
eq "JRN-008 a module-audit launch from an initiative folder is denied" "$rc" 2
check "JRN-008 the module-audit refusal names the expected spec folder format" 'grep -q "malformed header value(s): spec_dir=" <<<"$err"' "$err"
launch research .workflow/initiatives/storage-overhaul
eq "JRN-008 an initiative folder without its number is denied" "$rc" 2
launch research "$INI/"
eq "JRN-008 a trailing slash on the initiative folder still resolves" "$rc" 0
out=$(bash "$RL" --host codex --task-type research --spec-dir "$INI" --project-dir "$P" </dev/null 2>"$WORK/err")
rc=$?
eq "JRN-008 an orchestrator-mode research launch from an initiative folder resolves" "$rc" 0

shellcheck_files "JRN-008 shellcheck resolve-launch.sh" "$RL"
finish
