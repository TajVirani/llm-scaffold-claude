#!/usr/bin/env bash
# Suite: lint of YAML frontmatter in .agents/skills/*/SKILL.md and .agents/agents/*.md (reads the repo, writes nothing).
# Covers: frontmatter is the first thing in the file and parses with yq v4; non-empty `name` (matches folder / file name)
#   and `description`; agents carry no `model:` and only `claude` / `codex` keys under `models:`;
#   `disable-model-invocation` only on first-party skills whose body has a STUB marker; no implemented file has a STUB marker;
#   every STUB-marked file is listed as a stub in PROVENANCE.md.
# A STUB marker is a line in the body that starts with `STUB:` (optionally inside an HTML comment opener).
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

PROV=$REPO_ROOT/PROVENANCE.md
new_workdir

# fm_extract FILE OUT : write the frontmatter (between the leading --- lines) to OUT. rc 1 when absent or unterminated.
fm_extract() {
  [ "$(head -n 1 "$1")" = "---" ] || return 1
  awk 'NR==1 {next} /^---[[:space:]]*$/ {found=1; exit} {print} END {exit found ? 0 : 1}' "$1" >"$2"
}

# body_has_stub FILE : true when the body (after the frontmatter) has a STUB marker line.
body_has_stub() {
  awk 'NR==1 && /^---/ {fm=1; next} fm && /^---[[:space:]]*$/ {fm=0; next} !fm {print}' "$1" |
    grep -Eq '^[[:space:]]*(<!--[[:space:]]*)?STUB:'
}

# listed_as_stub NAME : PROVENANCE.md has a line mentioning NAME whose status says stub.
listed_as_stub() {
  grep -F -- "$1" "$PROV" | grep -qi 'stub'
}

# lint_file KIND NAME FILE : prints one problem per line for FILE; KIND is skill or agent.
lint_file() {
  local kind=$1 name=$2 f=$3 fm="$WORK/fm.yaml" got desc ty k
  if ! fm_extract "$f" "$fm"; then
    echo "no frontmatter block at the top of the file"
    return
  fi
  if ! yq e '.' "$fm" >/dev/null 2>&1; then
    echo "frontmatter does not parse with yq: $(yq e '.' "$fm" 2>&1 | head -n 1)"
    return
  fi
  ty=$(yq e '. | tag' "$fm" 2>/dev/null)
  if [ "$ty" != "!!map" ]; then
    echo "frontmatter is not a YAML mapping ($ty)"
    return
  fi
  got=$(yq e '.name // ""' "$fm")
  desc=$(yq e '.description // ""' "$fm")
  [ -n "$got" ] || echo "name is missing or empty"
  [ -z "$got" ] || [ "$got" = "$name" ] || echo "name '$got' does not match '$name'"
  [ -n "$desc" ] || echo "description is missing or empty"
  if [ "$kind" = agent ]; then
    [ "$(yq e 'has("model")' "$fm")" = false ] || echo "agent has a model: key"
    if [ "$(yq e 'has("models")' "$fm")" = true ]; then
      for k in $(yq e '.models | keys | .[]' "$fm" 2>/dev/null); do
        case "$k" in claude | codex) ;; *) echo "models: has unsupported key '$k' (only claude, codex)" ;; esac
      done
    fi
  fi
  if [ "$kind" = skill ]; then
    if [ "$(yq e 'has("disable-model-invocation")' "$fm")" = true ] && ! body_has_stub "$f"; then
      echo "disable-model-invocation set but the body has no STUB marker"
    fi
  fi
  if body_has_stub "$f"; then
    if [ "$kind" = skill ]; then k=$name; else k=agents/$name.md; fi
    listed_as_stub "$k" || echo "has a STUB marker but PROVENANCE.md does not list '$k' as a stub"
  fi
}

# report NAME PROBLEMS : one assertion per file.
report() {
  if [ -z "$2" ]; then ok "$1"; else ko "$1" "$(printf '%s' "$2" | tr '\n' ';')"; fi
}

check "PROVENANCE.md exists" '[ -f "$PROV" ]'

count=0
for f in "$AGENTS_SRC"/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  name=$(basename "$(dirname "$f")")
  count=$((count + 1))
  report "skill $name" "$(lint_file skill "$name" "$f")"
done
check "found skills" '[ "$count" -gt 0 ]'

count=0
for f in "$AGENTS_SRC"/agents/*.md; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .md)
  count=$((count + 1))
  report "agent $name" "$(lint_file agent "$name" "$f")"
done
check "found agents" '[ "$count" -gt 0 ]'

# Self-check of the linter on bad fixtures, so a broken lint cannot pass silently.
mkdir -p "$WORK/bad"
printf 'no frontmatter\n' >"$WORK/bad/a.md"
printf -- '---\nname: a\ndescription: [unclosed\n---\nbody\n' >"$WORK/bad/b.md"
printf -- '---\nname: wrong\ndescription: d\nmodel: opus\nmodels:\n  claude: x\n  gemini: y\n---\nbody\n' >"$WORK/bad/c.md"
printf -- '---\nname: d\ndescription: d\ndisable-model-invocation: true\n---\nbody\n' >"$WORK/bad/d.md"
check "lint flags missing frontmatter" '[ -n "$(lint_file agent a "$WORK/bad/a.md")" ]'
check "lint flags unparseable frontmatter" '[ -n "$(lint_file agent b "$WORK/bad/b.md")" ]'
out=$(lint_file agent c "$WORK/bad/c.md")
check "lint flags name mismatch, model and bad models key" 'grep -q "does not match" <<<"$out" && grep -q "model: key" <<<"$out" && grep -q "gemini" <<<"$out"'
check "lint flags disable-model-invocation without STUB" '[ -n "$(lint_file skill d "$WORK/bad/d.md")" ]'

shellcheck_files "shellcheck tests/lint/frontmatter.sh" "$TESTS_DIR/lint/frontmatter.sh"
finish
