#!/usr/bin/env bash
# Suite: the retrospective's documented Measurements commands (skills/retrospective/modules/evidence.md; the retrospective
#   has no script, so its command block is the component).
# Covers: JRN-006 (spec 00019): the waits command, the line of the Measurements bash block whose trailing comment starts
#   `# Waits:`, run as written from a fixture project with S set to a fixture spec folder: a design log holding one round
#   answer and a Deep dive entry with `- Exchanges: 3` and its own answer gives 5 (two answers plus three exchanges), and
#   one holding two answers and no Exchanges line gives 2, the count from before exchanges were added. The waits command
#   is shellcheck-clean. Reads a copy of .agents/; writes only to a scratch dir.
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
P=$WORK/proj
copy_agents "$P"
EVIDENCE=$P/.agents/skills/retrospective/modules/evidence.md

# waits_command : the line of the bash block under `## Measurements` whose trailing comment starts `# Waits:`, without
#   its indent. Fences are tracked first so a comment line inside the block is not read as a heading.
waits_command() {
  awk '
    /^[[:space:]]*```/ { in_fence = !in_fence; next }
    !in_fence && /^#+ / { in_measurements = ($0 ~ /^## Measurements[[:space:]]*$/); next }
    in_measurements && in_fence && /[[:space:]]# Waits:/ { sub(/^[[:space:]]+/, ""); print; exit }
  ' "$EVIDENCE"
}

# run_waits SPEC_DIR : the waits command's output, run from the fixture project root with S set to SPEC_DIR.
run_waits() { (cd "$P" && S=$1 bash -c "$WAITS_COMMAND" 2>&1); }

WITH_DEEP_DIVE=.workflow/specs/001-with-deep-dive
WITHOUT_DEEP_DIVE=.workflow/specs/002-without-deep-dive
mkdir -p "$P/$WITH_DEEP_DIVE" "$P/$WITHOUT_DEEP_DIVE"

cat >"$P/$WITH_DEEP_DIVE/design-log.md" <<'EOF'
# Design log: fixture with a deep dive

## 2026-01-01 Questioning round 1

**Q1. Keep the default port?**

- Why now: the server is settled.
- Options: A: keep 8080 · B: pick another
- Recommended: A, because nothing else listens there
- Answer: "yes"
- Decision: **D1** keep port 8080.

Facts looked up instead of asked (0.3.10): None.

## 2026-01-01 Deep dive: where are reports stored?

- From: Q2 in round 1
- Restated: you asked where reports are stored; I recommended files because nothing else needs a database.
- Where it was wrong: "the reports need queries"
- Explored: None.
- Exchanges: 3
- Agreed statement: "store reports in the database the dashboards already read"
- Answer: "yes"
- Decision: **D2** store reports in the dashboards' database.
- Round check: Q1 stands
EOF

cat >"$P/$WITHOUT_DEEP_DIVE/design-log.md" <<'EOF'
# Design log: fixture without a deep dive

## 2026-01-01 Questioning round 1

**Q1. Keep the default port?**

- Why now: the server is settled.
- Options: A: keep 8080 · B: pick another
- Recommended: A, because nothing else listens there
- Answer: "yes"
- Decision: **D1** keep port 8080.

**Q2. Where are reports stored?**

- Why now: the report format is settled.
- Options: A: files · B: the database
- Recommended: A, because nothing else needs a database
- Answer: "files"
- Decision: **D2** store reports as files.

Facts looked up instead of asked (0.3.10): None.
EOF

echo "== the waits command"
WAITS_COMMAND=$(waits_command)
if [ -n "$WAITS_COMMAND" ]; then
  WAITS=$(printf 'with deep dive=%s, without=%s' "$(run_waits "$WITH_DEEP_DIVE")" "$(run_waits "$WITHOUT_DEEP_DIVE")")
else
  WAITS="no line in the Measurements bash block of evidence.md has a trailing # Waits: comment"
fi
eq "00019 JRN-006: the waits count adds the Exchanges numbers (5 for one answer plus a three-exchange deep dive) and stays 2 for two answers and no Exchanges line" \
  "$WAITS" "with deep dive=5, without=2"

WAITS_SCRIPT=$WORK/waits.sh
# shellcheck disable=SC2016  # the written script must hold the literal $1, expanded when it runs, not here
printf '#!/usr/bin/env bash\nS=$1\n%s\n' "$WAITS_COMMAND" >"$WAITS_SCRIPT"
shellcheck_files "shellcheck: retrospective-evidence suite and the waits command" \
  "$TESTS_DIR/scripts/retrospective-evidence.sh" "$WAITS_SCRIPT"
finish
