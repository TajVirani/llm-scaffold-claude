#!/bin/bash
# Codex hook verification. Usage: ./run.sh [work-base-dir]   (default: $TMPDIR)
# Builds a scratch repo in a fresh temp dir, runs ONE headless codex exec, prints a jq summary.
# Run OUTSIDE any outer sandbox (e.g. Claude Code Bash sandbox): Codex needs seatbelt for its shell.
# Uses --dangerously-bypass-hook-trust and an in-memory project-trust override (-c projects={...});
# ~/.codex/config.toml is never edited. Scaffold-only harness; not part of the install payload (D30).
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
BASE="${1:-${TMPDIR:-/tmp}}"; mkdir -p "$BASE"
H="$(cd "$(mktemp -d "$BASE/codexhooks.XXXXXX")" && pwd -P)"
MODEL="${CODEX_TEST_MODEL:-gpt-6-luna}"
echo "work dir: $H"
"$SRC/setup.sh" "$H"
codex debug models | jq -r '.. | objects | select(has("slug")) | select(.visibility=="list") | .slug' > "$H/runs/models.txt"
P="$H/proj"
for v in $(env | grep -o "^CLAUDE[A-Z_]*"); do unset "$v"; done
cd "$P"
# Free preflight (no model call): project layer loads, skills (incl. symlinked) are listed, profile applied
codex debug prompt-input -c "projects={\"$P\"={trust_level=\"trusted\"}}" "hi" > "$H/runs/prompt-input.json" 2>/dev/null || true
codex exec -C "$P" --dangerously-bypass-hook-trust --json \
  -m "$MODEL" -c model_reasoning_effort=\"${CODEX_TEST_EFFORT:-medium}\" -c approval_policy=\"never\" \
  -c "projects={\"$P\"={trust_level=\"trusted\"}}" \
  -o "$H/runs/run1.last.txt" \
  "Do these steps in order. Do not retry a failed step and do not request escalation. 1) Spawn the custom agent with agent_type 'probe' and message 'go'; wait for it and report its final reply verbatim. 2) Spawn the custom agent with agent_type 'probem' and message 'ping'; wait for it and report its final reply verbatim. 3) Use apply_patch to create denyme.txt containing x. 4) Run the shell command: echo x; exit 3 5) Use apply_patch to create docs/cache/a.txt containing x. 6) Run the shell command: echo y > docs/cache/b.txt 7) List every tool name you have, exactly, comma-separated. Report the outcome of every step." \
  > "$H/runs/run1.jsonl" 2> "$H/runs/run1.err" || echo "codex exit $?"
"$SRC/report.sh" "$H"
