#!/usr/bin/env bash
# Suite: lint over the orchestrator modules verification-setup.md and implementation-orchestrator.md and the agent docs
#   implementation.md and integration.md: agent worktrees for Phase 1 and integration launches, and the artifacts merge gate.
# Covers: JRN-008: no line tells the orchestrator to launch an agent with `isolation: "worktree"` (a sentence saying never to is
#   fine) and no isolation fallback is left; Phase 1 and integration agent worktrees are created with
#   `git worktree add .workflow/.worktrees/<name> -b wf/NNN-slug/<name> spec/NNN-slug`, their wf/ branch is merged with no
#   isolation result branch (worktreeBranch) to read, and worktree and branch are removed after the merge; check-merge-artifacts.sh
#   runs before each merge site (1.2 and 1.3, 3.2 integration, 3.16 task, light-path fast-forward) with --rev and is never piped;
#   both agent briefs write their result file to an absolute main-checkout path. The checks match the design's intent, not
#   exact prose. Reads the repo; writes nothing.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/result-briefs.sh
source "$TESTS_DIR/fixtures/result-briefs.sh"
preflight

MODULES=$FW_SKILL/modules
VS=$MODULES/verification-setup.md
IO=$MODULES/implementation-orchestrator.md
IMPL=$AGENTS_SRC/agents/implementation.md
INTEG=$AGENTS_SRC/agents/integration.md

# Clauses are split on ". ", "; " and table cell bars, so one sentence that rules a thing out does not excuse its neighbour.
# A negation word before the subject in the same clause marks it as ruled out.
NEGATION='(^|[^a-z])(never|not|no|without|instead of|rather than|removed)([^a-z]|$)'

# isolation_launches DOC : prints "<line>: <clause>" for each clause that has a launch use `isolation: "worktree"`: a launch
#   word (launch, call, with, use, set, pass) before it and no negation, or a table cell holding only that option.
isolation_launches() {
  awk -v neg="$NEGATION" '
    {
      n = split($0, parts, /(\. |; |\|)/)
      for (i = 1; i <= n; i++) {
        clause = parts[i]
        pos = index(clause, "isolation: \"worktree\"")
        if (pos == 0) continue
        cell = clause
        gsub(/^[ `]+|[ `]+$/, "", cell)
        if (cell == "isolation: \"worktree\"") { print NR ": " clause; continue }
        before = tolower(substr(clause, 1, pos - 1))
        if (before ~ neg) continue
        if (before ~ /(^|[^a-z])(launch|launches|relaunch|call|with|use|using|set|pass)([^a-z]|$)/) print NR ": " clause
      }
    }' "$1"
}

# unnegated_clauses DOC REGEX [LINE_REGEX] : prints "<line>: <clause>" for each clause matching REGEX (case-insensitive) with no
#   negation word, only on lines matching LINE_REGEX (case-insensitive) when it is given.
unnegated_clauses() {
  awk -v neg="$NEGATION" -v re="$2" -v line_re="${3:-}" '
    line_re == "" || tolower($0) ~ line_re {
      n = split($0, parts, /(\. |; |\|)/)
      for (i = 1; i <= n; i++) {
        clause = tolower(parts[i])
        if (clause ~ re && clause !~ neg) print NR ": " parts[i]
      }
    }' "$1"
}

# lines DOC REGEX : prints "<line>: <text>" for each line matching the extended REGEX.
lines() { grep -nE -- "$2" "$1" || true; }

# gate_before_site DOC SITE_REGEX : true when the first line matching SITE_REGEX, or one of the ten lines before it, calls the gate.
# shellcheck disable=SC2329  # called from the eval'd check strings below
gate_before_site() {
  local site
  site=$(grep -nE -- "$2" "$1" | head -n 1 | cut -d: -f1)
  [ -n "$site" ] || return 1
  sed -n "$((site > 10 ? site - 10 : 1)),${site}p" "$1" | grep -q 'check-merge-artifacts\.sh'
}

echo "== no isolation launch and no isolation fallback (JRN-008)"
for doc in "$VS" "$IO"; do
  found=$(isolation_launches "$doc")
  check "JRN-008 ${doc##*/} tells no launch to use isolation: \"worktree\"" '[ -z "$found" ]' "$found"
  found=$(unnegated_clauses "$doc" 'baseref')
  check "JRN-008 ${doc##*/} sets no worktree baseRef for an isolation launch" '[ -z "$found" ]' "$found"
  found=$(unnegated_clauses "$doc" 'fallback' 'isolation')
  check "JRN-008 ${doc##*/} keeps no isolation fallback" '[ -z "$found" ]' "$found"
  found=$(lines "$doc" 'worktreeBranch')
  check "JRN-008 ${doc##*/} reads no isolation result branch (worktreeBranch)" '[ -z "$found" ]' "$found"
done

echo "== agent worktrees: created off the spec branch, merged, removed (JRN-008)"
# shellcheck disable=SC2034  # read inside the eval'd check strings below
CREATE='git worktree add [^ ]*\.workflow/\.worktrees/[^ ]+ -b wf/[^ ]+ spec/'
check "JRN-008 verification-setup.md creates the Phase 1 agent worktree on a wf/ branch off the spec branch" \
  '[ -n "$(lines "$VS" "$CREATE")" ]'
check "JRN-008 implementation-orchestrator.md creates the integration agent worktree on a wf/ branch off the spec branch" \
  '[ -n "$(lines "$IO" "$CREATE")" ]'
check "JRN-008 verification-setup.md names a phase_1 agent worktree" '[ -n "$(lines "$VS" "s<?NNN>?_phase_1_|s[0-9]+_phase_1_")" ]'
check "JRN-008 implementation-orchestrator.md names an integration agent worktree" '[ -n "$(lines "$IO" "s<?NNN>?_integration_|s[0-9]+_integration_")" ]'
for doc in "$VS" "$IO"; do
  check "JRN-008 ${doc##*/} merges the agent's wf/ branch" '[ -n "$(lines "$doc" "git merge" | grep "wf/")" ]'
  check "JRN-008 ${doc##*/} removes the agent worktree after the merge" \
    '[ -n "$(lines "$doc" "git worktree remove[^\`]*\\.workflow/\\.worktrees/")" ]'
  check "JRN-008 ${doc##*/} deletes the agent's wf/ branch after the merge" '[ -n "$(lines "$doc" "git branch -[dD] [^\`]*wf/")" ]'
done

echo "== artifacts gate before each merge (JRN-008)"
check "JRN-008 the gate runs before the 1.2 and 1.3 merge" 'gate_before_site "$VS" "git merge --no-ff"'
check "JRN-008 the gate runs before the 3.2 integration merge" 'gate_before_site "$IO" "Merge integration-"'
check "JRN-008 the gate runs before the 3.16 task merge" 'gate_before_site "$IO" "git merge --no-ff -m \"Merge T"'
check "JRN-008 the gate runs before the light-path fast-forward" 'gate_before_site "$IO" "git merge --ff-only"'
calls=$(cat "$VS" "$IO" | grep 'check-merge-artifacts\.sh' || true)
check "JRN-008 every gate call passes --rev" '[ -n "$calls" ] && ! grep -v -- "--rev" <<<"$calls" | grep -q .' "$calls"
check "JRN-008 no gate call is piped into another command" '[ -n "$calls" ] && ! grep -qE "check-merge-artifacts\.sh[^|]*\|[^|]" <<<"$calls"' "$calls"

echo "== briefs write the result file to an absolute main-checkout path (JRN-008)"
# main_checkout_path PATH : true when PATH starts at the main checkout as an absolute path or a placeholder naming it.
# shellcheck disable=SC2329  # called from the eval'd check strings below
main_checkout_path() {
  case "$1" in
    /*) return 0 ;;
    \<*main*\>/* | \<*Main*\>/*) return 0 ;;
    *) return 1 ;;
  esac
}
for pair in "$IMPL|implementation.yaml" "$INTEG|integration.yaml"; do
  doc=${pair%|*} file=${pair#*|}
  target=$(brief_result_target "$(brief_result_command "$doc" "$file")")
  check "JRN-008 ${doc##*/} writes $file to an absolute main-checkout path" 'main_checkout_path "$target"' "target: ${target:-none found}"
done

shellcheck_files "shellcheck: this suite and fixtures/result-briefs.sh" "${BASH_SOURCE[0]}" "$TESTS_DIR/fixtures/result-briefs.sh"
finish
