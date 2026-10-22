#!/usr/bin/env bash
# Suite: install.sh (repo root): single-host installs and the dry run.
# Covers: fresh installs for --host claude and --host codex (only that host's shim, the .gitignore block, next steps
#   naming that host, re-run changes nothing); --dry-run writes nothing and lists or reports its actions.
# The scaffold under test is a copy of this repo's install.sh and .agents/ inside the fixture, so the repo is never written.
# Env: TEST_BASH=<bash binary> runs install.sh under another bash (default: bash).
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
TEST_BASH=${TEST_BASH:-bash}

new_workdir
SC=$WORK/scaffold
mkdir -p "$SC"
cp "$REPO_ROOT/install.sh" "$SC/install.sh"
copy_agents "$SC"
git_init_repo "$SC"
git_commit_all "$SC" scaffold
INST() { "$TEST_BASH" "$SC/install.sh" "$@"; }

# snap DIR : one line per file (cksum) and symlink (target) outside .git, sorted.
snap() {
  (cd "$1" && find . -path ./.git -prune -o \( -type f -o -type l \) -print | LC_ALL=C sort | while IFS= read -r f; do
    if [ -L "$f" ]; then printf '%s -> %s\n' "$f" "$(readlink "$f")"; else cksum "$f"; fi
  done)
}
new_target() { rm -rf "$1"; git_init_repo "$1"; }

echo "== fresh install, --host claude and --host codex"
C=$WORK/claude
new_target "$C"
t "install --host claude" 0 INST "$C" --host claude
check "claude: .claude shim present, no .codex" '[ -L "$C/.claude/skills" ] && [ -f "$C/.claude/settings.json" ] && [ ! -e "$C/.codex" ]'
check "claude: .gitignore block still written" 'grep -qxF ".workflow/.worktrees/" "$C/.gitignore"'
out=$(INST "$C" --host claude 2>&1)
check "claude: next steps name .claude/ but not .codex/" 'printf "%s" "$out" | grep -qF "(.agents/, .claude/, .gitignore)" && ! printf "%s" "$out" | grep -qF ".codex/"' "$out"
before=$(snap "$C")
INST "$C" --host claude >/dev/null 2>&1
eq "claude: re-run changes nothing" "$(snap "$C")" "$before"
X=$WORK/codex
new_target "$X"
t "install --host codex" 0 INST "$X" --host codex
check "codex: .codex shim present, no .claude" '[ -f "$X/.codex/hooks.json" ] && [ -f "$X/.codex/config.toml" ] && [ -f "$X/.codex/agents/fact_lookup.toml" ] && [ ! -e "$X/.claude" ]'
out=$(INST "$X" --host codex 2>&1)
check "codex: next steps print the trust and /hooks steps" 'printf "%s" "$out" | grep -q "/hooks" && printf "%s" "$out" | grep -qi "trust"'
check "next steps point at project-setup" 'printf "%s" "$out" | grep -q "project-setup"'
check "codex: next steps name .codex/ but not .claude/" 'printf "%s" "$out" | grep -qF "(.agents/, .codex/, .gitignore)"' "$out"
before=$(snap "$X")
INST "$X" --host codex >/dev/null 2>&1
eq "codex: re-run changes nothing" "$(snap "$X")" "$before"

echo "== dry run"
D=$WORK/dry
new_target "$D"
printf 'node_modules/\n' >"$D/.gitignore"
before=$(snap "$D")
out=$(INST "$D" --dry-run 2>&1)
rc=$?
eq "dry run on a fresh target exits 0" "$rc" 0
eq "dry run on a fresh target writes nothing" "$(snap "$D")" "$before"
check "dry run lists actions" 'printf "%s" "$out" | grep -q "would create .agents/skills/feature-workflow/SKILL.md" && printf "%s" "$out" | grep -q "would link .claude/skills" && printf "%s" "$out" | grep -q "would create .codex/agents/fact_lookup.toml"'
INST "$D" >/dev/null 2>&1
echo "tampered" >>"$D/.agents/skills/glab/SKILL.md"
before=$(snap "$D")
out=$(INST "$D" --dry-run 2>&1)
eq "dry run on an install with drift writes nothing" "$(snap "$D")" "$before"
check "...and reports the update" 'printf "%s" "$out" | grep -q "would update .agents/skills/glab/SKILL.md"'

echo "== lint"
shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"

finish
