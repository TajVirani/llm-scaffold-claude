#!/usr/bin/env bash
# Suite: install.sh (repo root): preflight, payload and host shims.
# Covers: preflight errors (not a git repo, sub-directory, bad --host, manifest line matching nothing); fresh installs for
#   --host all, claude and codex (payload = manifest expansion exactly, VERSION stamp, .claude symlinks, settings.json =
#   template, .codex/agents generated, hooks.json = template, config.toml parses to the template, .gitignore block, next
#   steps per host); vendored and scaffold-only files absent from the target; executable hooks; context-bridge.cjs shipped
#   and wired as statusLine and run in a "type": "module" target; idempotent re-run (no byte changes, VERSION kept).
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
# manifest_files SCAFFOLD : expected payload (paths relative to .agents/), sorted.
manifest_files() {
  local line
  sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' "$1/.agents/install-manifest.txt" | sed '/^$/d' | while IFS= read -r line; do
    if [ -d "$1/.agents/$line" ]; then (cd "$1/.agents" && find "$line" -type f ! -name .DS_Store); else printf '%s\n' "$line"; fi
  done | LC_ALL=C sort -u
}
target_files() { (cd "$1/.agents" && find . -type f ! -name VERSION | sed 's|^\./||' | LC_ALL=C sort); }
new_target() { rm -rf "$1"; git_init_repo "$1"; }

echo "== preflight"
mkdir -p "$WORK/notgit"
t "target that is not a git repo: exit 2" 2 INST "$WORK/notgit"
new_target "$WORK/sub"
mkdir -p "$WORK/sub/inner"
t "target that is a sub-directory of a repo: exit 2" 2 INST "$WORK/sub/inner"
t "bad --host: exit 2" 2 INST "$WORK/sub" --host cursor
t "no target: exit 2" 2 INST
out=$(INST "$WORK/sub" --bogus 2>&1)
check "unknown option is named" 'printf "%s" "$out" | grep -q "unknown option: --bogus"'
cp -R "$SC" "$WORK/badsc"
echo "skills/does-not-exist" >>"$WORK/badsc/.agents/install-manifest.txt"
t "manifest line that matches nothing: exit 2" 2 "$TEST_BASH" "$WORK/badsc/install.sh" "$WORK/sub"
check "...and nothing was written" '[ ! -e "$WORK/sub/.agents" ]'
check "yq preflight names mikefarah v4" 'grep -q "mikefarah yq v4" "$SC/install.sh"'

echo "== fresh install, --host all"
A=$WORK/all
new_target "$A"
t "install --host all" 0 INST "$A" --host all
eq "payload is exactly the manifest expansion" "$(target_files "$A")" "$(manifest_files "$SC")"
check "VERSION lists the same files" '[ "$(awk "f{print} /^files:/{f=1}" "$A/.agents/VERSION")" = "$(manifest_files "$SC")" ]'
check "VERSION has version, commit and date" 'grep -q "^scaffold_version: " "$A/.agents/VERSION" && grep -q "^scaffold_commit: [0-9a-f]\{40\}$" "$A/.agents/VERSION" && grep -q "^installed: 20" "$A/.agents/VERSION"'
for d in skills agents output-styles; do
  eq ".claude/$d -> ../.agents/$d" "$(readlink "$A/.claude/$d")" "../.agents/$d"
done
check "settings.json equals the template" '[ "$(jq -S . "$A/.claude/settings.json")" = "$(jq -S . "$SC/.agents/hooks/claude-settings.template.json")" ]'
n_agents=$(find "$SC/.agents/agents" -name '*.md' | wc -l | tr -d ' ')
eq "one .codex/agents toml per agent definition" "$(find "$A/.codex/agents" -name '*.toml' | wc -l | tr -d ' ')" "$n_agents"
t "generated agents are current (--check)" 0 "$TEST_BASH" "$A/.agents/hooks/generate-codex-agents.sh" --check
check "hooks.json equals the Codex template" '[ "$(jq -S . "$A/.codex/hooks.json")" = "$(jq -S . "$SC/.agents/hooks/codex-hooks.template.json")" ]'
check "config.toml parses to the template values" '[ "$(yq -p toml -o json -I=0 . "$A/.codex/config.toml")" = "$(yq -p toml -o json -I=0 . "$SC/.agents/hooks/codex-config.template.toml")" ]'
eq "config.toml sets the Codex context bar" "$(yq -p toml -o json -I=0 .tui.status_line "$A/.codex/config.toml")" '["model-with-reasoning","context-remaining","current-dir","git-branch"]'
for p in '.workflow/specs/*/.step' '.workflow/initiatives/*/.step' '.workflow/.cache-staging/' '.workflow/.worktrees/' '.workflow/.handoff/' '.workflow/.standards-staging/'; do
  check ".gitignore has $p" 'grep -qxF -- "$p" "$A/.gitignore"'
done
check "install creates no .workflow/" '[ ! -e "$A/.workflow" ]'
check "path helper installed" '[ -f "$A/.agents/lib/workflow-paths.sh" ]'
eq "installed wf_path resolves the initiatives root" "$("$TEST_BASH" -c '. "$1/.agents/lib/workflow-paths.sh" && wf_path "$1" "$WF_INITIATIVES"' _ "$A")" "$A/.workflow/initiatives"
check "hook scripts are executable" '[ -x "$A/.agents/hooks/pre-launch.sh" ] && [ -x "$A/.agents/hooks/block-destructive-git.sh" ] && [ -x "$A/.agents/skills/feature-workflow/scripts/status-transition.sh" ]'
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"git push --force"},"cwd":"%s"}' "$A" | "$A/.agents/hooks/block-destructive-git.sh" 2>&1)
check "an installed hook runs from the target" 'printf "%s" "$out" | grep -qi "deny\|block"' "$out"

echo "== vendored and scaffold-only files are absent"
eq "installed skills are exactly the first-party set" "$(cd "$A/.agents/skills" && find . -mindepth 1 -maxdepth 1 | sed 's|^\./||' | LC_ALL=C sort | tr '\n' ' ')" \
  "data-structure-audit deeper-prompt deps-audit deps-update design-pattern-doc domain-modeling feature-workflow glab handoff pr-quality pr-review-data project-setup project-standards regenerate-caches retrospective visual-change-report writing-for-agents "
bad=""
# No vendored skill remains: handoff and writing-for-agents are first-party; the rest were deleted.
for s in ask-matt clear-context code-review codebase-design diagnosing-bugs grill-me grill-with-docs grilling implement implement-spec improve-codebase-architecture install-anti-slop pr proof-of-work prototype research retro setup-matt-pocock-skills tdd to-questionnaire to-spec to-tickets triage wait-what wayfinder wizard wrap-up zoom-out; do
  [ ! -e "$A/.agents/skills/$s" ] || bad="$bad $s"
done
eq "no vendored skill installed" "$bad" ""
check "context-bridge.cjs (first-party) installed and executable" '[ -x "$A/.agents/hooks/context-bridge.cjs" ]'
check "statusLine runs the shipped context-bridge.cjs" '[ "$(jq -r .statusLine.command "$A/.claude/settings.json")" = "node \"\${CLAUDE_PROJECT_DIR:-.}\"/.agents/hooks/context-bridge.cjs" ]'
if command -v node >/dev/null 2>&1; then
  mkdir -p "$WORK/ctxtmp"
  out=$(printf '%s' '{"session_id":"s1","context_window":{"remaining_percentage":60}}' | TMPDIR=$WORK/ctxtmp node "$A/.agents/hooks/context-bridge.cjs")
  check "context-bridge prints the scaled usage bar (40% real = 50%)" 'printf "%s" "$out" | grep -q "50%"'
  eq "context-bridge writes the bridge file" "$(jq -c '[.session_id, .remaining_percentage]' "$WORK/ctxtmp/claude-ctx-s1.json" 2>/dev/null)" '["s1",60]'
  out=$(printf '%s' '{"session_id":"s2"}' | TMPDIR=$WORK/ctxtmp node "$A/.agents/hooks/context-bridge.cjs")
  check "context-bridge without context_window prints nothing and writes no file" '[ -z "$out" ] && [ ! -e "$WORK/ctxtmp/claude-ctx-s2.json" ]'
  # A target whose package.json sets "type": "module" makes node treat .js as ESM; the .cjs name keeps the script CommonJS.
  E=$WORK/esm
  new_target "$E"
  echo '{"type":"module"}' >"$E/package.json"
  INST "$E" --host claude >/dev/null 2>&1
  cmd=$(jq -r .statusLine.command "$E/.claude/settings.json")
  out=$(cd "$E" && printf '%s' '{"session_id":"s3","context_window":{"remaining_percentage":60}}' | TMPDIR=$WORK/ctxtmp CLAUDE_PROJECT_DIR=$E bash -c "$cmd" 2>&1)
  check "statusLine command prints the bar in a \"type\": \"module\" target" 'printf "%s" "$out" | grep -q "50%" && ! printf "%s" "$out" | grep -q "require is not defined"' "$out"
else
  skip "context-bridge.cjs behaviour" "node not installed"
fi
check ".agents/README.md (scaffold note) not installed" '[ ! -e "$A/.agents/README.md" ]'
check "Mermaid validator and syntax rules for the caches ship" '[ -f "$A/.agents/skills/visual-change-report/scripts/validate_mermaid.mjs" ] && [ -f "$A/.agents/skills/visual-change-report/references/visual-library.md" ]'
check "progress line script and its step list ship, executable" '[ -x "$A/.agents/skills/feature-workflow/scripts/step-progress.sh" ] && [ -f "$A/.agents/skills/feature-workflow/references/steps.tsv" ]'
check "vendor copies ship with their consumer and LICENSE" '[ -f "$A/.agents/skills/pr-quality/references/codebase-design.md" ] && [ -f "$A/.agents/skills/pr-quality/references/LICENSE" ]'
check "no shipped file points at a vendored skill path" '! grep -rqE "\.agents/skills/(improve-codebase-architecture|codebase-design)/|\.\./\.\./improve-codebase-architecture/" "$A/.agents/skills/pr-quality"'
check "project-owned content is not shipped: no design-pattern-doc conventions, no athena pr-quality modules" '[ ! -e "$A/.agents/skills/design-pattern-doc/conventions.md" ] && [ ! -e "$A/.agents/skills/pr-quality/modules/legend-state-review.md" ] && [ ! -e "$A/.agents/skills/pr-quality/modules/project-pitfalls.md" ]'
check "generic templates for project-owned files ship" '[ -f "$A/.agents/skills/design-pattern-doc/CONVENTIONS-FORMAT.md" ] && [ -f "$A/.agents/skills/pr-quality/assets/project-check.template.md" ]'
check "install creates no docs/ in the target" '[ ! -e "$A/docs" ]'
check "shipped glab and design-pattern-doc name no vendored skill" '! grep -rhv "^Sources:" "$A/.agents/skills/glab" "$A/.agents/skills/design-pattern-doc" | grep -qE "(to-tickets|to-spec|setup-matt-pocock-skills|diagnosing-bugs|\`triage\`)"'
bad=""
for f in PLAN tests assetlist.md checklist.md PROVENANCE.md CHANGELOG.md install.sh upstream-lineage.json scripts wayfinder-comparison.html testprompt.md .workflow; do
  [ ! -e "$A/$f" ] && [ ! -e "$A/.agents/$f" ] || bad="$bad $f"
done
eq "no scaffold-only file in the target" "$bad" ""

echo "== idempotent re-run"
before=$(snap "$A")
t "re-run --host all" 0 INST "$A" --host all
eq "re-run changes nothing (VERSION included)" "$(snap "$A")" "$before"
out=$(INST "$A" 2>&1)
check "re-run reports up to date" 'printf "%s" "$out" | grep -q "up to date"'

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

echo "== lint"
shellcheck_files "shellcheck: install.sh" "$REPO_ROOT/install.sh"
shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"

finish
