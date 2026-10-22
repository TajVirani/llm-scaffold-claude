#!/usr/bin/env bash
# Suite: install.sh (repo root): Codex config.toml and hooks.json merges.
# Covers: Codex hooks.json and config.toml merges over user files (user keys and text kept, default_permissions and the
#   workflow profile added, managed block refreshed); a differing [permissions.workflow] refused and its --force path;
#   a different default_permissions kept with a warning.
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
eq "config.toml: tui.status_line added" "$(jq -c .tui.status_line <<<"$j")" '["model-with-reasoning","context-remaining","current-dir","git-branch"]'
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

echo "== lint"
shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"

finish
