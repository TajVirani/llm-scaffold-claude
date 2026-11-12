#!/usr/bin/env bash
# Suite: lint over the feature-workflow step files (modules/*.md), the launching reference (references/launching.md) and the agent
#   definitions (.agents/agents/*.md): every worktree is created and removed through worktree-setup.sh.
# Covers: JRN-008: no document tells a reader to run a raw `git worktree add` or `git worktree remove` (a sentence saying never to
#   is fine); each document that makes an agent or scratch worktree names `worktree-setup.sh agent` or `worktree-setup.sh scratch`
#   (verification-setup.md, implementation-waves.md, implementation-shared-core.md, profile-mini-review.md and the three review
#   agents); the coding agents (implementation.md, integration.md) carry the rule never to install, copy or link into a worktree
#   by hand.
#   Reads the repo; writes nothing.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

MODULES=$FW_SKILL/modules
AGENTS=$AGENTS_SRC/agents

# Clauses are split on ". ", "; ", ", " and table cell bars, so one sentence that rules a thing out does not excuse its
#   neighbour. A negation word before the command in the same clause marks it as ruled out; one after it is about something else.
NEGATION='(^|[^a-z])(never|not|no|instead of|rather than)([^a-z]|$)'

# raw_worktree_commands DOC : prints "<line>: <clause>" for each clause that runs `git worktree add` or `git worktree remove`
#   with no negation word before it.
raw_worktree_commands() {
  awk -v neg="$NEGATION" '
    {
      n = split($0, parts, /(\. |; |, |\|)/)
      for (i = 1; i <= n; i++) {
        clause = tolower(parts[i])
        if (!match(clause, /git( -c [^ ]+)? worktree (add|remove)/)) continue
        if (substr(clause, 1, RSTART - 1) !~ neg) print NR ": " parts[i]
      }
    }' "$1"
}

# no_hand_setup_rule DOC : true when one sentence of DOC says never and names installing, copying and linking.
# shellcheck disable=SC2329  # called from the eval'd check strings below
no_hand_setup_rule() {
  awk '{
      n = split($0, sentences, /\. /)
      for (i = 1; i <= n; i++) {
        s = tolower(sentences[i])
        if (s ~ /never/ && s ~ /install/ && s ~ /cop(y|ies)/ && s ~ /link/) found = 1
      }
    } END { exit !found }' "$1"
}

echo "== no raw git worktree add or remove (JRN-008)"
for doc in "$MODULES"/*.md "$FW_SKILL/references/launching.md" "$AGENTS"/*.md; do
  found=$(raw_worktree_commands "$doc")
  check "JRN-008 ${doc#"$AGENTS_SRC"/} runs no raw git worktree add or remove" '[ -z "$found" ]' "$found"
done

echo "== every worktree creation names worktree-setup.sh (JRN-008)"
for pair in "$MODULES/verification-setup.md|agent" "$MODULES/verification-setup.md|scratch" \
  "$MODULES/implementation-waves.md|agent" "$MODULES/implementation-shared-core.md|agent" \
  "$AGENTS/profile-mini-review.md|scratch" "$AGENTS/review-end-state.md|scratch" "$AGENTS/review-standards.md|scratch" \
  "$AGENTS/review-combined.md|scratch"; do
  doc=${pair%|*} call=${pair#*|}
  t "JRN-008 ${doc##*/} creates its $call worktree with worktree-setup.sh $call" 0 grep -q "worktree-setup\.sh $call " "$doc"
done

echo "== the coding agents never set up a worktree by hand (JRN-008)"
for doc in "$AGENTS/implementation.md" "$AGENTS/integration.md"; do
  check "JRN-008 ${doc##*/} says never to install, copy or link into a worktree by hand" 'no_hand_setup_rule "$doc"'
done

shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"
finish
