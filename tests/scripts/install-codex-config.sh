#!/usr/bin/env bash
# Suite: install.sh (repo root): Codex config.toml and hooks.json merges.
# Covers: Codex hooks.json and config.toml merges over user files (user keys and text kept, the tui block added and refreshed,
#   no permissions profile written); the default-permissions and permissions-workflow blocks an older install wrote are
#   removed with the user's text around them kept; a user's own default_permissions left as is, with no warning.
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
INST() { "$TEST_BASH" "$SC/install.sh" "$@" </dev/null; }

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
eq "config.toml: no default_permissions or permissions written" "$(jq -c '[.default_permissions, .permissions]' <<<"$j")" '[null,null]'
check "config.toml: user text kept verbatim" 'grep -qx "# my config" "$K/.codex/config.toml" && grep -qxF "[profiles.fast]" "$K/.codex/config.toml"'
eq "config.toml: tui.status_line added" "$(jq -c .tui.status_line <<<"$j")" '["model-with-reasoning","context-remaining","current-dir","git-branch"]'
check "user-written agent toml kept" '[ -f "$K/.codex/agents/mine.toml" ]'
eq "hooks.json: user hook kept" "$(jq -r '.hooks.Stop[0].hooks[0].command' "$K/.codex/hooks.json")" my-stop.sh
check "hooks.json: template events added" 'jq -e ".hooks.PreToolUse and .hooks.SubagentStop and .hooks.SessionStart" "$K/.codex/hooks.json" >/dev/null'
before=$(snap "$K")
INST "$K" --host codex >/dev/null 2>&1
eq "codex merge re-run changes nothing" "$(snap "$K")" "$before"
# A refreshed managed block: edits inside the markers are replaced on the next run.
sed -i.bak 's|^status_line = \[.*$|status_line = ["git-branch"]|' "$K/.codex/config.toml" && rm -f "$K/.codex/config.toml.bak"
INST "$K" --host codex >/dev/null 2>&1
eq "managed block refreshed from the template" "$(yq -p toml -o json -I=0 '.tui.status_line' "$K/.codex/config.toml")" '["model-with-reasoning","context-remaining","current-dir","git-branch"]'

K2=$WORK/codexold
new_target "$K2"
mkdir -p "$K2/.codex"
OLDB='# >>> workflow-2.0 scaffold:' OLDE='# <<< workflow-2.0 scaffold:' OLDM='(managed by install.sh; edits inside are replaced) >>>'
{
  printf '%s default-permissions %s\ndefault_permissions = "workflow"\n%s default-permissions <<<\n\n' "$OLDB" "$OLDM" "$OLDE"
  printf '# mine\nmodel = "gpt-x"\n\n'
  printf '%s permissions-workflow %s\n[permissions.workflow]\nextends = ":workspace"\n%s permissions-workflow <<<\n' "$OLDB" "$OLDM" "$OLDE"
} >"$K2/.codex/config.toml"
t "older install: re-run" 0 INST "$K2" --host codex
j=$(yq -p toml -o json -I=0 . "$K2/.codex/config.toml")
eq "older install: default_permissions and the profile removed" "$(jq -c '[.default_permissions, .permissions]' <<<"$j")" '[null,null]'
check "older install: no old marker left" '! grep -Eq "default-permissions|permissions-workflow" "$K2/.codex/config.toml"'
check "older install: user text kept" 'grep -qx "# mine" "$K2/.codex/config.toml" && grep -qx "model = \"gpt-x\"" "$K2/.codex/config.toml"'
eq "older install: tui block added" "$(jq -c .tui.status_line <<<"$j")" '["model-with-reasoning","context-remaining","current-dir","git-branch"]'
before=$(snap "$K2")
INST "$K2" --host codex >/dev/null 2>&1
eq "older install: second re-run changes nothing" "$(snap "$K2")" "$before"

K3=$WORK/codexdp
new_target "$K3"
mkdir -p "$K3/.codex"
printf 'default_permissions = "mine"\n' >"$K3/.codex/config.toml"
out=$(INST "$K3" --host codex 2>&1)
eq "a user default_permissions: exit 0" "$?" 0
eq "...user value kept" "$(yq -p toml -oy '.default_permissions' "$K3/.codex/config.toml")" mine
check "...with no warning about it" '! printf "%s" "$out" | grep -q "default_permissions"'

echo "== lint"
shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"

finish
