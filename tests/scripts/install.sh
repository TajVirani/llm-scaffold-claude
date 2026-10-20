#!/usr/bin/env bash
# Suite: install.sh (repo root; D11, D30, D36, D38, D40, D66, D67, D71, D72).
# Covers: preflight errors (not a git repo, sub-directory, bad --host, manifest line matching nothing); fresh installs for
#   --host claude, codex and all (payload = manifest expansion exactly, VERSION stamp, .claude symlinks, settings.json =
#   template, .codex/agents generated, hooks.json = template, config.toml parses to the template, .gitignore block);
#   vendored and scaffold-only files absent from the target; executable hooks; context-bridge.cjs shipped and wired as statusLine (D79) and run in a "type": "module" target (D83); Codex [tui] status_line merge (D83); idempotent re-run (no
#   byte changes, VERSION kept); upgrade that overwrites a changed file and removes a file dropped from the manifest while
#   keeping files no install shipped; settings merge over user settings (user keys, hooks and deny entries kept, deny
#   unioned without duplicates, outputStyle and statusLine kept with a warning, --force replaces them); refusals that write nothing (real
#   .claude/skills dir, wrong-type settings key, differing [permissions.workflow], invalid JSON) and their --force paths;
#   Codex hooks.json and config.toml merges over user files; project-owned files untouched (incl. .workflow/design-pattern-doc/ and
#   .workflow/pr-quality/, D75; their athena copies and modules not shipped); --dry-run writes nothing.
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
eq "config.toml sets the Codex context bar (D83)" "$(yq -p toml -o json -I=0 .tui.status_line "$A/.codex/config.toml")" '["model-with-reasoning","context-remaining","current-dir","git-branch"]'
for p in '.workflow/specs/*/.step' '.workflow/.cache-staging/' '.workflow/.worktrees/' '.workflow/.handoff/' '.workflow/.standards-staging/'; do
  check ".gitignore has $p" 'grep -qxF -- "$p" "$A/.gitignore"'
done
check "install creates no .workflow/ (D81)" '[ ! -e "$A/.workflow" ]'
check "path helper installed" '[ -f "$A/.agents/lib/workflow-paths.sh" ]'
check "hook scripts are executable" '[ -x "$A/.agents/hooks/pre-launch.sh" ] && [ -x "$A/.agents/hooks/block-destructive-git.sh" ] && [ -x "$A/.agents/skills/feature-workflow/scripts/status-transition.sh" ]'
out=$(printf '{"tool_name":"Bash","tool_input":{"command":"git push --force"},"cwd":"%s"}' "$A" | "$A/.agents/hooks/block-destructive-git.sh" 2>&1)
check "an installed hook runs from the target" 'printf "%s" "$out" | grep -qi "deny\|block"' "$out"

echo "== vendored and scaffold-only files are absent (D30, D71, D72)"
eq "installed skills are exactly the first-party set" "$(cd "$A/.agents/skills" && find . -mindepth 1 -maxdepth 1 | sed 's|^\./||' | LC_ALL=C sort | tr '\n' ' ')" \
  "data-structure-audit deeper-prompt deps-audit deps-update design-pattern-doc domain-modeling feature-workflow glab handoff pr-quality pr-review-data project-setup project-standards regenerate-caches retrospective visual-change-report writing-for-agents "
bad=""
# No vendored skill remains (D78): handoff and writing-for-agents are first-party; the rest were deleted.
for s in ask-matt clear-context code-review codebase-design diagnosing-bugs grill-me grill-with-docs grilling implement implement-spec improve-codebase-architecture install-anti-slop pr proof-of-work prototype research retro setup-matt-pocock-skills tdd to-questionnaire to-spec to-tickets triage wait-what wayfinder wizard wrap-up zoom-out; do
  [ ! -e "$A/.agents/skills/$s" ] || bad="$bad $s"
done
eq "no vendored skill installed" "$bad" ""
check "context-bridge.cjs (first-party, D79) installed and executable" '[ -x "$A/.agents/hooks/context-bridge.cjs" ]'
check "statusLine runs the shipped context-bridge.cjs (D79)" '[ "$(jq -r .statusLine.command "$A/.claude/settings.json")" = "node \"\${CLAUDE_PROJECT_DIR:-.}\"/.agents/hooks/context-bridge.cjs" ]'
if command -v node >/dev/null 2>&1; then
  mkdir -p "$WORK/ctxtmp"
  out=$(printf '%s' '{"session_id":"s1","context_window":{"remaining_percentage":60}}' | TMPDIR=$WORK/ctxtmp node "$A/.agents/hooks/context-bridge.cjs")
  check "context-bridge prints the scaled usage bar (40% real = 50%)" 'printf "%s" "$out" | grep -q "50%"'
  eq "context-bridge writes the bridge file" "$(jq -c '[.session_id, .remaining_percentage]' "$WORK/ctxtmp/claude-ctx-s1.json" 2>/dev/null)" '["s1",60]'
  out=$(printf '%s' '{"session_id":"s2"}' | TMPDIR=$WORK/ctxtmp node "$A/.agents/hooks/context-bridge.cjs")
  check "context-bridge without context_window prints nothing and writes no file" '[ -z "$out" ] && [ ! -e "$WORK/ctxtmp/claude-ctx-s2.json" ]'
  # A target whose package.json sets "type": "module" makes node treat .js as ESM; the .cjs name keeps the script CommonJS (D83).
  E=$WORK/esm
  new_target "$E"
  echo '{"type":"module"}' >"$E/package.json"
  INST "$E" --host claude >/dev/null 2>&1
  cmd=$(jq -r .statusLine.command "$E/.claude/settings.json")
  out=$(cd "$E" && printf '%s' '{"session_id":"s3","context_window":{"remaining_percentage":60}}' | TMPDIR=$WORK/ctxtmp CLAUDE_PROJECT_DIR=$E bash -c "$cmd" 2>&1)
  check "statusLine command prints the bar in a \"type\": \"module\" target (D83)" 'printf "%s" "$out" | grep -q "50%" && ! printf "%s" "$out" | grep -q "require is not defined"' "$out"
else
  skip "context-bridge.cjs behaviour" "node not installed"
fi
check ".agents/README.md (scaffold note) not installed" '[ ! -e "$A/.agents/README.md" ]'
check "Mermaid validator and syntax rules for the caches ship (D72)" '[ -f "$A/.agents/skills/visual-change-report/scripts/validate_mermaid.mjs" ] && [ -f "$A/.agents/skills/visual-change-report/references/visual-library.md" ]'
check "progress line script and its step list ship, executable (D84)" '[ -x "$A/.agents/skills/feature-workflow/scripts/step-progress.sh" ] && [ -f "$A/.agents/skills/feature-workflow/references/steps.tsv" ]'
check "vendor copies ship with their consumer and LICENSE (D74)" '[ -f "$A/.agents/skills/pr-quality/references/codebase-design.md" ] && [ -f "$A/.agents/skills/pr-quality/references/LICENSE" ]'
check "no shipped file points at a vendored skill path (D74)" '! grep -rqE "\.agents/skills/(improve-codebase-architecture|codebase-design)/|\.\./\.\./improve-codebase-architecture/" "$A/.agents/skills/pr-quality"'
check "project-owned content is not shipped: no design-pattern-doc conventions, no athena pr-quality modules (D75)" '[ ! -e "$A/.agents/skills/design-pattern-doc/conventions.md" ] && [ ! -e "$A/.agents/skills/pr-quality/modules/legend-state-review.md" ] && [ ! -e "$A/.agents/skills/pr-quality/modules/project-pitfalls.md" ]'
check "generic templates for project-owned files ship (D75)" '[ -f "$A/.agents/skills/design-pattern-doc/CONVENTIONS-FORMAT.md" ] && [ -f "$A/.agents/skills/pr-quality/assets/project-check.template.md" ]'
check "install creates no docs/ in the target (D75)" '[ ! -e "$A/docs" ]'
check "shipped glab and design-pattern-doc name no vendored skill (D71, D74)" '! grep -rhv "^Sources:" "$A/.agents/skills/glab" "$A/.agents/skills/design-pattern-doc" | grep -qE "(to-tickets|to-spec|setup-matt-pocock-skills|diagnosing-bugs|\`triage\`)"'
bad=""
for f in PLAN tests assetlist.md organization.md checklist.md PROVENANCE.md CHANGELOG.md install.sh upstream-lineage.json scripts; do
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

echo "== upgrade: overwrite changed files, remove files dropped from the manifest"
U=$WORK/up
new_target "$U"
INST "$U" >/dev/null 2>&1
mkdir -p "$U/.workflow"
echo '{"commit":"abc"}' >"$U/.workflow/data-structure-audit-state.jsonl"
echo "local edit" >>"$U/.agents/skills/feature-workflow/SKILL.md"
echo "user note" >"$U/.agents/skills/deps-audit/NOTES.local.md"
cp -R "$SC" "$WORK/sc2"
sed -i.bak '/^skills\/glab$/d; /^skills\/deps-audit$/d' "$WORK/sc2/.agents/install-manifest.txt"
rm -f "$WORK/sc2/.agents/install-manifest.txt.bak"
out=$("$TEST_BASH" "$WORK/sc2/install.sh" "$U" 2>&1)
eq "upgrade exits 0" "$?" 0
check "dropped skill removed (dir gone)" '[ ! -e "$U/.agents/skills/glab" ]'
check "dropped skill files removed, user file in it kept" '[ ! -e "$U/.agents/skills/deps-audit/SKILL.md" ] && [ -f "$U/.agents/skills/deps-audit/NOTES.local.md" ]'
check "removal reported" 'printf "%s" "$out" | grep -q "remove .agents/skills/glab/SKILL.md"'
check "locally edited scaffold file overwritten" 'cmp -s "$U/.agents/skills/feature-workflow/SKILL.md" "$SC/.agents/skills/feature-workflow/SKILL.md"'
check "file no install shipped is kept" '[ -f "$U/.workflow/data-structure-audit-state.jsonl" ]'
check "VERSION no longer lists the dropped skill" '! grep -q "^skills/glab/" "$U/.agents/VERSION" && grep -q "^skills/feature-workflow/SKILL.md$" "$U/.agents/VERSION"'
before=$(snap "$U")
"$TEST_BASH" "$WORK/sc2/install.sh" "$U" >/dev/null 2>&1
eq "upgrade re-run changes nothing" "$(snap "$U")" "$before"

echo "== Claude settings merge over user settings"
M=$WORK/merge
new_target "$M"
mkdir -p "$M/.claude"
cat >"$M/.claude/settings.json" <<'EOF'
{
  "outputStyle": "Explanatory",
  "statusLine": {"type": "command", "command": "my-status.sh"},
  "enabledPlugins": {"foo@bar": true},
  "env": {"FOO": "1"},
  "permissions": {"allow": ["Bash(ls:*)"], "deny": ["Read(.env)", "Edit(.workflow/cache/**)"]},
  "hooks": {
    "PreToolUse": [
      {"matcher": "Bash", "hooks": [{"type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/block-destructive-git.sh", "timeout": 10}]},
      {"matcher": "Read", "hooks": [{"type": "command", "command": "my-read-hook.sh"}]}
    ],
    "Stop": [{"hooks": [{"type": "command", "command": "my-stop.sh"}]}]
  }
}
EOF
out=$(INST "$M" --host claude 2>&1)
eq "merge exits 0" "$?" 0
S=$M/.claude/settings.json
eq "outputStyle kept" "$(jq -r .outputStyle "$S")" "Explanatory"
check "outputStyle warning printed" 'printf "%s" "$out" | grep -q "outputStyle: keeping your"'
eq "statusLine kept" "$(jq -r .statusLine.command "$S")" "my-status.sh"
check "statusLine warning printed" 'printf "%s" "$out" | grep -q "statusLine: keeping your"'
eq "unrelated user keys kept" "$(jq -c '[.enabledPlugins, .env, .permissions.allow]' "$S")" '[{"foo@bar":true},{"FOO":"1"},["Bash(ls:*)"]]'
eq "deny unioned, user first, no duplicates" "$(jq -c .permissions.deny "$S")" '["Read(.env)","Edit(.workflow/cache/**)","Edit(.workflow/specs/*/.step)"]'
check "user hooks kept" '[ "$(jq -r ".hooks.Stop[0].hooks[0].command" "$S")" = my-stop.sh ] && jq -e "[.hooks.PreToolUse[].hooks[].command] | index(\"my-read-hook.sh\")" "$S" >/dev/null'
eq "block-destructive-git not duplicated" "$(jq '[.hooks.PreToolUse[].hooks[].command | select(test("block-destructive-git"))] | length' "$S")" 1
# shellcheck disable=SC2034  # used inside the eval'd check below
tpl_cmds=$(jq -r '[.hooks[][].hooks[].command] | sort | .[]' "$SC/.agents/hooks/claude-settings.template.json")
# shellcheck disable=SC2034
got_cmds=$(jq -r '[.hooks[][].hooks[].command] | sort | .[]' "$S")
check "every template hook command present" '[ -z "$(comm -23 <(printf "%s\n" "$tpl_cmds") <(printf "%s\n" "$got_cmds"))" ]'
eq "PostToolUseFailure event added with its Bash group" "$(jq -c '[.hooks.PostToolUseFailure[] | {matcher, c: [.hooks[].command]}]' "$S")" "$(jq -c '[.hooks.PostToolUseFailure[] | {matcher, c: [.hooks[].command]}]' "$SC/.agents/hooks/claude-settings.template.json")"
before=$(snap "$M")
INST "$M" --host claude >/dev/null 2>&1
eq "merge re-run changes nothing" "$(snap "$M")" "$before"
t "--force run" 0 INST "$M" --host claude --force
eq "--force replaces outputStyle" "$(jq -r .outputStyle "$S")" "Concise Technical"
eq "--force replaces statusLine" "$(jq -c .statusLine "$S")" "$(jq -c .statusLine "$SC/.agents/hooks/claude-settings.template.json")"
eq "--force keeps user keys" "$(jq -c .env "$S")" '{"FOO":"1"}'

echo "== refusals write nothing"
R=$WORK/refuse
new_target "$R"
mkdir -p "$R/.claude/skills/mine"
echo "x" >"$R/.claude/skills/mine/SKILL.md"
before=$(snap "$R")
out=$(INST "$R" 2>&1)
eq "real .claude/skills dir: exit 1" "$?" 1
check "...names the directory and --force" 'printf "%s" "$out" | grep -q ".claude/skills is a real directory" && printf "%s" "$out" | grep -q -- "--force"'
eq "...and nothing was written" "$(snap "$R")" "$before"
t "real .claude/skills dir with --force" 0 INST "$R" --force
eq "--force: .claude/skills is now the symlink" "$(readlink "$R/.claude/skills")" "../.agents/skills"
check "--force: old dir kept as a backup" 'ls "$R/.claude" | grep -q "^skills.backup-" && [ -f "$R/.claude/$(ls "$R/.claude" | grep "^skills.backup-")/mine/SKILL.md" ]'
R2=$WORK/refuse2
new_target "$R2"
mkdir -p "$R2/.claude"
ln -s /elsewhere "$R2/.claude/agents"
t "symlink pointing elsewhere: exit 1" 1 INST "$R2" --host claude
t "symlink pointing elsewhere with --force" 0 INST "$R2" --host claude --force
eq "--force: symlink replaced" "$(readlink "$R2/.claude/agents")" "../.agents/agents"
R3=$WORK/refuse3
new_target "$R3"
mkdir -p "$R3/.claude"
echo '{"permissions": "all"}' >"$R3/.claude/settings.json"
before=$(snap "$R3")
t "settings key of the wrong type: exit 1" 1 INST "$R3" --host claude
eq "...and nothing was written" "$(snap "$R3")" "$before"
echo '{not json' >"$R3/.claude/settings.json"
t "invalid settings JSON: exit 1" 1 INST "$R3" --host claude
t "invalid settings JSON: exit 1 even with --force" 1 INST "$R3" --host claude --force

echo "== Codex merges over user files"
K=$WORK/codexmerge
new_target "$K"
mkdir -p "$K/.codex/agents"
cat >"$K/.codex/config.toml" <<'EOF'
# my config
model = "gpt-x"

[profiles.fast]
model = "gpt-y"
EOF
printf 'name = "mine"\ndescription = "user agent"\ndeveloper_instructions = "hi"\n' >"$K/.codex/agents/mine.toml"
echo '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"my-stop.sh"}]}]}}' >"$K/.codex/hooks.json"
t "codex merge" 0 INST "$K" --host codex
j=$(yq -p toml -o json -I=0 . "$K/.codex/config.toml")
eq "config.toml: user keys kept" "$(jq -c '[.model, .profiles.fast.model]' <<<"$j")" '["gpt-x","gpt-y"]'
eq "config.toml: default_permissions added" "$(jq -r .default_permissions <<<"$j")" workflow
eq "config.toml: workflow profile added" "$(jq -c .permissions.workflow <<<"$j")" "$(yq -p toml -o json -I=0 .permissions.workflow "$SC/.agents/hooks/codex-config.template.toml")"
check "config.toml: user text kept verbatim" 'grep -qx "# my config" "$K/.codex/config.toml" && grep -qxF "[profiles.fast]" "$K/.codex/config.toml"'
eq "config.toml: tui.status_line added (D83)" "$(jq -c .tui.status_line <<<"$j")" '["model-with-reasoning","context-remaining","current-dir","git-branch"]'
check "user-written agent toml kept" '[ -f "$K/.codex/agents/mine.toml" ]'
eq "hooks.json: user hook kept" "$(jq -r '.hooks.Stop[0].hooks[0].command' "$K/.codex/hooks.json")" my-stop.sh
check "hooks.json: template events added" 'jq -e ".hooks.PreToolUse and .hooks.SubagentStop and .hooks.SessionStart" "$K/.codex/hooks.json" >/dev/null'
before=$(snap "$K")
INST "$K" --host codex >/dev/null 2>&1
eq "codex merge re-run changes nothing" "$(snap "$K")" "$before"
# A refreshed managed block: edits inside the markers are replaced on the next run.
sed -i.bak 's|^".workflow/cache" = "read"$|".workflow/cache" = "write"|' "$K/.codex/config.toml" && rm -f "$K/.codex/config.toml.bak"
INST "$K" --host codex >/dev/null 2>&1
eq "managed block refreshed from the template" "$(yq -p toml -o json -I=0 '.permissions.workflow.filesystem.":workspace_roots".".workflow/cache"' "$K/.codex/config.toml")" '"read"'

K2=$WORK/codexconflict
new_target "$K2"
mkdir -p "$K2/.codex"
printf 'default_permissions = "mine"\n\n[permissions.workflow]\nextends = ":read-only"\n' >"$K2/.codex/config.toml"
before=$(snap "$K2")
out=$(INST "$K2" --host codex 2>&1)
eq "differing [permissions.workflow]: exit 1" "$?" 1
eq "...and nothing was written" "$(snap "$K2")" "$before"
out=$(INST "$K2" --host codex --force 2>&1)
eq "differing [permissions.workflow] with --force: exit 0" "$?" 0
check "--force: hand-written profile left as is, with a warning" 'grep -qx "extends = \":read-only\"" "$K2/.codex/config.toml" && printf "%s" "$out" | grep -q "left as is"'
eq "--force: default_permissions overwritten" "$(yq -p toml -oy '.default_permissions' "$K2/.codex/config.toml")" workflow
K3=$WORK/codexdp
new_target "$K3"
mkdir -p "$K3/.codex"
printf 'default_permissions = "mine"\n' >"$K3/.codex/config.toml"
out=$(INST "$K3" --host codex 2>&1)
eq "different default_permissions: exit 0" "$?" 0
eq "...user value kept" "$(yq -p toml -oy '.default_permissions' "$K3/.codex/config.toml")" mine
check "...with a warning" 'printf "%s" "$out" | grep -q "keeping your default_permissions"'
# A [tui] table the user wrote is kept: no second table, a warning, and --force does not rewrite it (D83).
K4=$WORK/codextui
new_target "$K4"
mkdir -p "$K4/.codex"
printf '[tui]\ntheme = "mine"\n' >"$K4/.codex/config.toml"
out=$(INST "$K4" --host codex 2>&1)
eq "user [tui]: exit 0" "$?" 0
check "user [tui]: warning names status_line" 'printf "%s" "$out" | grep -q "keeping your \[tui\] table; add status_line"'
eq "user [tui]: one [tui] table, user key kept, no status_line added" "$(grep -c "^\[tui\]" "$K4/.codex/config.toml") $(yq -p toml -o json -I=0 '[.tui.theme, .tui.status_line]' "$K4/.codex/config.toml")" '1 ["mine",null]'
out=$(INST "$K4" --host codex --force 2>&1)
check "user [tui] with --force: left as is, with a warning" '[ "$(grep -c "^\[tui\]" "$K4/.codex/config.toml")" = 1 ] && printf "%s" "$out" | grep -q "does not rewrite it"'
check "user [tui]: config.toml still parses" 'yq -p toml -o json . "$K4/.codex/config.toml" >/dev/null'
K5=$WORK/codextuikey
new_target "$K5"
mkdir -p "$K5/.codex"
printf 'tui.status_line = ["model"]\n' >"$K5/.codex/config.toml"
out=$(INST "$K5" --host codex 2>&1)
check "user tui.status_line key: kept, warned, still parses" 'printf "%s" "$out" | grep -q "keeping your \[tui\]" && [ "$(yq -p toml -o json -I=0 .tui.status_line "$K5/.codex/config.toml")" = "[\"model\"]" ] && ! grep -q "^\[tui\]" "$K5/.codex/config.toml"'
K6=$WORK/codextuisame
new_target "$K6"
mkdir -p "$K6/.codex"
printf '[tui]\nstatus_line = ["model-with-reasoning", "context-remaining", "current-dir", "git-branch"]\n' >"$K6/.codex/config.toml"
out=$(INST "$K6" --host codex 2>&1)
check "user [tui] already matching: no warning, one table" '! printf "%s" "$out" | grep -q "\[tui\]" && [ "$(grep -c "^\[tui\]" "$K6/.codex/config.toml")" = 1 ]'

echo "== project-owned files untouched; .gitignore user lines kept"
P=$WORK/owned
new_target "$P"
mkdir -p "$P/.workflow/model-map" "$P/.workflow/profiles" "$P/.workflow/decisions" "$P/.workflow/design-pattern-doc" "$P/.workflow/pr-quality" "$P/.workflow/deferred" "$P/.workflow/specs/001-x"
echo "implementation: {claude: opus}" >"$P/.workflow/agent-overrides.yaml"
echo "m" >"$P/.workflow/model-map/retrieval.md"
echo "p" >"$P/.workflow/profiles/web.md"
echo "g" >"$P/.workflow/GLOSSARY.md"
echo "r" >"$P/.workflow/rules.md"
echo "a" >"$P/.workflow/decisions/0001.md"
echo "c" >"$P/.workflow/design-pattern-doc/conventions.md"
echo "q" >"$P/.workflow/pr-quality/my-check.md"
echo "d" >"$P/.workflow/deferred/x.md"
echo "s" >"$P/.workflow/specs/001-x/spec.md"
printf 'node_modules/\n*.log' >"$P/.gitignore"
owned() { (cd "$P" && cksum .workflow/agent-overrides.yaml .workflow/model-map/retrieval.md .workflow/profiles/web.md .workflow/GLOSSARY.md .workflow/rules.md .workflow/decisions/0001.md .workflow/design-pattern-doc/conventions.md .workflow/pr-quality/my-check.md .workflow/deferred/x.md .workflow/specs/001-x/spec.md); }
before=$(owned)
INST "$P" >/dev/null 2>&1
INST "$P" --force >/dev/null 2>&1
"$TEST_BASH" "$WORK/sc2/install.sh" "$P" --force >/dev/null 2>&1
eq "project-owned files byte-identical after install, --force and upgrade" "$(owned)" "$before"
check "project-owned .workflow/ gained no files" '[ "$(find "$P/.workflow" -type f | wc -l | tr -d " ")" = 10 ]'
check ".gitignore user lines kept, block added once" 'grep -qx "node_modules/" "$P/.gitignore" && grep -qx "\*.log" "$P/.gitignore" && [ "$(grep -c "^.workflow/specs/\*/.step$" "$P/.gitignore")" = 1 ]'

echo "== lint"
shellcheck_files "shellcheck: install.sh" "$REPO_ROOT/install.sh"
shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"

finish
