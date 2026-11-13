#!/usr/bin/env bash
# Suite: worktree-setup.sh (feature-workflow/scripts): setting up spec, agent and scratch worktrees in one fixture project that
#   declares a setup command and a copy list (.worktreeinclude).
# Covers: JRN-001: spec-worktree.sh create and worktree-setup.sh agent each leave the copy-list files as regular files equal to the
#   main checkout's and run worktree_setup there with WF_SLOT, WF_INSTANCE and WF_PORT_OFFSET; a tracked match, a match git does not
#   ignore and the setup command's stdout are left out; a match that is a symlink arrives as the file it points to; setup leaves
#   `git status --short` empty; env gives the isolation values, and 0, main, 0 in the main checkout; agent reuses a worktree that
#   exists; remove --force is refused for an agent worktree. JRN-003 (the check half): check and setup refuse a link into the main
#   checkout, one inside a dependency folder and one into another worktree, and pass a link outside the repository and a tracked
#   link inside the worktree. JRN-004: two spec worktrees hold slots 1 and 2, and one created after the first is removed takes 1.
#   JRN-007: scratch adds a detached worktree at an older commit, set up with the spec's slot, and remove --force takes it away.
#   The three new settings read through rules-setting.sh with default "". Setup run again keeps a copied file the worktree changed
#   and never writes through a link in a copy target's place; setup of the main checkout exits 1 and of a folder outside git 2;
#   remove refuses an agent worktree with an untracked file; env in spec worktrees with no slot file takes and keeps the lowest
#   free slots; env's lines eval back to a root path holding a space. Usage errors; shellcheck.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
P=$WORK/proj
S=.agents/skills/feature-workflow/scripts
LOG=$WORK/marker.log
make_fixture_repo "$P"

# The marker command lives outside the project, so its log never shows in a worktree's git status.
cat >"$WORK/marker.sh" <<M
#!/usr/bin/env bash
printf '%s %s %s %s %s\n' "\$1" "\$(pwd -P)" "\${WF_SLOT:-unset}" "\${WF_INSTANCE:-unset}" "\${WF_PORT_OFFSET:-unset}" >>'$LOG'
echo "marker stdout from \$1"
M
{ install_gitignore_lines; printf '%s\n' .env '*.local' node_modules/; } >"$P/.gitignore"
printf '# local config the app reads\n.env\n\n*.local\nnotes.txt\n' >"$P/.worktreeinclude"
mkdir -p "$P/.workflow" "$P/src"
printf '# Rules\n\n## Workflow settings\n\n```yaml\nworktree_setup: "bash %s setup"\n```\n' "$WORK/marker.sh" >"$P/.workflow/rules.md"
echo 'code' >"$P/src/app.sh"
ln -s src/app.sh "$P/app-link"
echo 'committed' >"$P/tracked.local"
git -C "$P" add -f tracked.local
git_commit_all "$P" "fixture: project"
MAIN_HEAD=$(git -C "$P" rev-parse HEAD)
echo 'SECRET=main' >"$P/.env"
echo 'local=1' >"$P/app.local"
echo 'shared=1' >"$WORK/shared.txt"
ln -s "$WORK/shared.txt" "$P/link.local"
echo 'notes' >"$P/notes.txt"
echo 'outside' >"$WORK/outside.env"

SW() { (cd "$P" && bash "$S/spec-worktree.sh" "$@"); }
# WS DIR ARGS... : run worktree-setup.sh from the checkout DIR, with that checkout's own copy, as a step file does.
WS() { local dir=$1; shift; (cd "$dir" && bash "$S/worktree-setup.sh" "$@"); }
# draft_spec NNN-SLUG : a spec folder discovery left uncommitted in the main checkout.
draft_spec() {
  mkdir -p "$P/.workflow/specs/$1"
  cp "$P/$S/../assets/spec.md" "$P/.workflow/specs/$1/spec.md"
}
# regular_copy COPY ORIGINAL : COPY is a regular file, not a symlink, with ORIGINAL's content.
# shellcheck disable=SC2329  # called from the eval'd check strings below
regular_copy() { [ -f "$1" ] && [ ! -L "$1" ] && cmp -s "$1" "$2"; }
# env_line WORKTREE NAME : the value env prints for NAME in WORKTREE.
env_line() { WS "$P" env "$1" 2>/dev/null | sed -n "s/^export $2=//p"; }
# expected_env SLOT INSTANCE OFFSET MAIN SPEC : the five lines env should print.
expected_env() {
  printf 'export WF_SLOT=%s\nexport WF_INSTANCE=%s\nexport WF_PORT_OFFSET=%s\nexport WF_MAIN_ROOT=%s\nexport WF_SPEC_ROOT=%s' "$@"
}

echo "== the three new settings read through rules-setting.sh"
git_init_repo "$WORK/bare"
for key in worktree_setup services_up services_down; do
  out=$(bash "$P/$S/rules-setting.sh" "$key" --cwd "$WORK/bare" 2>/dev/null); rc=$?
  eq "$key defaults to an empty value" "$rc:$out" "0:"
done
eq "worktree_setup reads the command rules.md sets" "$(bash "$P/$S/rules-setting.sh" worktree_setup --cwd "$P" 2>/dev/null)" \
  "bash $WORK/marker.sh setup"

echo "== the main checkout's isolation values"
eq "env in the main checkout prints 0, main, 0 and the main checkout twice" "$(WS "$P" env "$P" 2>/dev/null)" \
  "$(expected_env 0 main 0 "$P" "$P")"

echo "== JRN-001: create sets up the spec worktree"
draft_spec 001-alpha
out=$(SW create .workflow/specs/001-alpha 2>/dev/null); rc=$?
WA=$P/.workflow/.spec-worktrees/001-alpha
eq "JRN-001 create exits 0" "$rc" 0
eq "JRN-001 create's stdout is still the worktree and baseline lines alone" "$(cut -d' ' -f1 <<<"$out" | tr '\n' ' ')" "worktree baseline "
check "JRN-001 the setup command's stdout does not reach create's stdout" '! grep -q "marker stdout" <<<"$out"' "$out"
check "JRN-001 the spec worktree holds .env as a regular file equal to the main checkout's" 'regular_copy "$WA/.env" "$P/.env"'
check "JRN-001 another ignored copy-list match is copied" 'regular_copy "$WA/app.local" "$P/app.local"'
check "JRN-001 a copy-list match that is a symlink arrives as the file it points to" 'regular_copy "$WA/link.local" "$WORK/shared.txt"'
check "JRN-001 a copy-list match git does not ignore is not copied" '[ ! -e "$WA/notes.txt" ]'
check "JRN-001 worktree_setup ran in the spec worktree with slot 1, s001 and offset 100" \
  'grep -qx "setup $WA 1 s001 100" "$LOG" 2>/dev/null' "$(cat "$LOG" 2>/dev/null)"
eq "JRN-001 setup left no untracked file git does not ignore" "$(git -C "$WA" status --short 2>&1)" ""
eq "JRN-001 env in the spec worktree prints its isolation values" "$(WS "$P" env "$WA" 2>/dev/null)" \
  "$(expected_env 1 s001 100 "$P" "$WA")"

echo "== setup run again, and setup of what is not a spec worktree"
echo 'SECRET=edited in the worktree' >"$WA/.env"
out=$(WS "$WA" setup "$WA" 2>&1); rc=$?
check "setup run again keeps a copied file the worktree has changed since" \
  '[ $rc -eq 0 ] && [ "$(cat "$WA/.env")" = "SECRET=edited in the worktree" ]' "rc=$rc $out"
cp "$P/.env" "$WA/.env"
t "setup of the main checkout itself -> exit 1" 1 bash "$P/$S/worktree-setup.sh" setup "$P"
t "setup of a folder in no git repository -> exit 2" 2 bash "$P/$S/worktree-setup.sh" setup "$WORK"

echo "== JRN-001: an agent worktree inside the spec worktree"
# A changed working copy in the main checkout shows whether a tracked copy-list match was copied over the committed one.
echo 'changed in main' >"$P/tracked.local"
AG=$WA/.workflow/.worktrees/s001_t1
out=$(WS "$WA" agent s001_t1 task/001-alpha/T01-a 2>/dev/null); rc=$?
eq "JRN-001 agent prints only the new worktree" "$rc:$out" "0:worktree $AG"
eq "JRN-001 the agent worktree is on its branch" "$(git -C "$AG" branch --show-current 2>/dev/null)" task/001-alpha/T01-a
eq "JRN-001 the agent branch forks from the spec branch" "$(git -C "$P" rev-parse -q --verify 'task/001-alpha/T01-a^{commit}' 2>/dev/null)" \
  "$(git -C "$P" rev-parse spec/001-alpha)"
check "JRN-001 the agent worktree holds .env as a regular file equal to the main checkout's" 'regular_copy "$AG/.env" "$P/.env"'
check "JRN-001 worktree_setup ran in the agent worktree with the spec's slot" \
  'grep -qx "setup $AG 1 s001 100" "$LOG" 2>/dev/null' "$(cat "$LOG" 2>/dev/null)"
check "JRN-001 a tracked copy-list match is not copied, and setup leaves git status empty" \
  '[ -d "$AG" ] && [ -z "$(git -C "$AG" status --short 2>&1)" ]' "$(git -C "$AG" status --short 2>&1)"
eq "JRN-001 env in the agent worktree gives the spec's values" "$(WS "$P" env "$AG" 2>/dev/null)" "$(expected_env 1 s001 100 "$P" "$WA")"
out=$(WS "$WA" agent s001_t1 task/001-alpha/T01-a 2>/dev/null); rc=$?
eq "JRN-001 agent again reuses the worktree that exists" "$rc:$out" "0:worktree $AG"
git -C "$P" checkout -q -- tracked.local

echo "== JRN-003: the link check"
out=$(WS "$WA" check "$WA" 2>&1); rc=$?
eq "JRN-003 a tracked symlink inside its own worktree passes" "$rc" 0
rm -f "$WA/.env"
ln -s "$P/.env" "$WA/.env"
out=$(WS "$WA" check "$WA" 2>&1); rc=$?
check "JRN-003 check refuses .env linked to the main checkout's, naming it" '[ $rc -eq 1 ] && grep -q "\.env" <<<"$out"' "rc=$rc $out"
out=$(WS "$WA" setup "$WA" 2>&1); rc=$?
check "JRN-003 setup refuses it too" '[ $rc -eq 1 ] && grep -q "\.env" <<<"$out"' "rc=$rc $out"
rm -f "$WA/.env"
ln -s "$WORK/outside.env" "$WA/.env"
out=$(WS "$WA" check "$WA" 2>&1); rc=$?
eq "JRN-003 a link to a file outside the repository passes" "$rc" 0
rm -f "$WA/.env"
cp "$P/.env" "$WA/.env"
mkdir -p "$WA/node_modules/pkg"
ln -s "$P/.env" "$WA/node_modules/pkg/config.env"
out=$(WS "$WA" check "$WA" 2>&1); rc=$?
check "JRN-003 a link inside a dependency folder that resolves into the main checkout is refused" \
  '[ $rc -eq 1 ] && grep -q "node_modules/pkg/config.env" <<<"$out"' "rc=$rc $out"
rm -rf "$WA/node_modules"
# The link points at an ignored file in the main checkout that is not on the copy list, so a write through it would show there.
mkdir -p "$P/node_modules"
echo 'decoy' >"$P/node_modules/decoy"
rm -f "$WA/app.local"
ln -s "$P/node_modules/decoy" "$WA/app.local"
out=$(WS "$WA" setup "$WA" 2>&1); rc=$?
check "setup does not write a copy-list file through a link already in its place, and the link check names it" \
  '[ $rc -eq 1 ] && grep -q "app\.local" <<<"$out" && [ -L "$WA/app.local" ] && [ "$(cat "$P/node_modules/decoy")" = decoy ]' "rc=$rc $out"
rm -f "$WA/app.local"
cp "$P/app.local" "$WA/app.local"
rm -rf "$P/node_modules"

echo "== JRN-007: a scratch worktree at an older commit"
SC=$WA/.workflow/.worktrees/s001_known_bad
out=$(WS "$WA" scratch s001_known_bad "$MAIN_HEAD" 2>/dev/null); rc=$?
eq "JRN-007 scratch prints only the new worktree" "$rc:$out" "0:worktree $SC"
check "JRN-007 the scratch worktree is detached at that commit" \
  '[ -d "$SC" ] && ! git -C "$SC" symbolic-ref -q HEAD >/dev/null && [ "$(git -C "$SC" rev-parse HEAD)" = "$MAIN_HEAD" ]'
check "JRN-007 the copy list is applied" 'regular_copy "$SC/.env" "$P/.env"'
check "JRN-007 worktree_setup ran there with the spec's slot" \
  'grep -qx "setup $SC 1 s001 100" "$LOG" 2>/dev/null' "$(cat "$LOG" 2>/dev/null)"
eq "JRN-007 env in the scratch worktree gives the spec's values" "$(WS "$P" env "$SC" 2>/dev/null)" "$(expected_env 1 s001 100 "$P" "$WA")"
[ ! -d "$SC" ] || echo 'probe output' >"$SC/probe.txt"
out=$(WS "$WA" remove s001_known_bad --force 2>/dev/null); rc=$?
eq "JRN-007 remove --force prints the removed scratch worktree" "$rc:$out" "0:removed worktree $SC"
check "JRN-007 the scratch worktree is gone, from disk and from git's list" \
  '[ ! -e "$SC" ] && ! git -C "$P" worktree list --porcelain | grep -qxF "worktree $SC"'

echo "== remove: an agent worktree"
WS "$WA" agent s001_t1 task/001-alpha/T01-a >/dev/null 2>&1
echo 'work in progress' >"$AG/untracked.txt"
out=$(WS "$WA" remove s001_t1 2>&1); rc=$?
check "remove refuses an agent worktree with an untracked file, which stays" \
  '[ $rc -eq 1 ] && [ -f "$AG/untracked.txt" ]' "rc=$rc $out"
rm -f "$AG/untracked.txt"
out=$(WS "$WA" remove s001_t1 --force 2>&1); rc=$?
check "remove --force is refused for an agent worktree, which stays" '[ $rc -eq 1 ] && [ -d "$AG" ]' "rc=$rc $out"
out=$(WS "$WA" remove s001_t1 2>/dev/null); rc=$?
eq "remove of the agent worktree prints it" "$rc:$out" "0:removed worktree $AG"
check "the agent worktree is gone" '[ ! -e "$AG" ]'
git -C "$P" branch -q -D task/001-alpha/T01-a 2>/dev/null

echo "== JRN-004: two specs, two slots"
draft_spec 002-beta
SW create .workflow/specs/002-beta >/dev/null 2>&1
WB=$P/.workflow/.spec-worktrees/002-beta
eq "JRN-004 the first spec worktree holds slot 1" "$(env_line "$WA" WF_SLOT)" 1
eq "JRN-004 the second spec worktree holds slot 2" "$(env_line "$WB" WF_SLOT):$(env_line "$WB" WF_PORT_OFFSET)" 2:200
check "JRN-004 worktree_setup ran in the second spec worktree with slot 2 and s002" \
  'grep -qx "setup $WB 2 s002 200" "$LOG" 2>/dev/null' "$(cat "$LOG" 2>/dev/null)"
ln -s "$WB/src/app.sh" "$WA/peer-link"
out=$(WS "$WA" check "$WA" 2>&1); rc=$?
check "JRN-003 a link into another worktree of the same repository is refused" \
  '[ $rc -eq 1 ] && grep -q "peer-link" <<<"$out"' "rc=$rc $out"
rm -f "$WA/peer-link"
git -C "$P" merge -q --no-ff -m "Merge spec/001-alpha" spec/001-alpha
out=$(SW remove .workflow/specs/001-alpha 2>&1); rc=$?
check "JRN-004 the first spec worktree is removed" '[ $rc -eq 0 ] && [ ! -e "$WA" ]' "rc=$rc $out"
draft_spec 003-gamma
SW create .workflow/specs/003-gamma >/dev/null 2>&1
WC=$P/.workflow/.spec-worktrees/003-gamma
eq "JRN-004 a spec worktree created after the first was removed takes the freed slot 1" "$(env_line "$WC" WF_SLOT)" 1
eq "JRN-004 the second spec worktree keeps slot 2" "$(env_line "$WB" WF_SLOT)" 2
SW create .workflow/specs/002-beta >/dev/null 2>&1
eq "JRN-004 setup run again keeps the slot it holds" "$(env_line "$WB" WF_SLOT)" 2

echo "== env in spec worktrees that hold no slot file yet"
rm -f "$WB/.workflow/.slot" "$WC/.workflow/.slot"
eq "env in a spec worktree with no slot file takes the lowest free slot" "$(env_line "$WB" WF_SLOT)" 1
eq "env in the next one takes the slot after it, so the first kept its slot" "$(env_line "$WC" WF_SLOT)" 2
eq "a second env in the first prints the same slot" "$(env_line "$WB" WF_SLOT)" 1

echo "== env of a root whose path holds a space"
SPACED="$WORK/with space"
git_init_repo "$SPACED"
out=$(bash "$P/$S/worktree-setup.sh" env "$SPACED" 2>&1); rc=$?
eq "eval of env's lines gives back both roots holding the space" \
  "$rc:$(eval "$out" 2>/dev/null; printf '%s|%s' "${WF_MAIN_ROOT:-}" "${WF_SPEC_ROOT:-}")" "0:$SPACED|$SPACED"

echo "== usage"
t "no call -> exit 2" 2 bash "$P/$S/worktree-setup.sh"
t "an unknown call -> exit 2" 2 bash "$P/$S/worktree-setup.sh" move x

shellcheck_files "shellcheck: worktree-setup.sh and this suite" "$AGENTS_SRC/skills/feature-workflow/scripts/worktree-setup.sh" "${BASH_SOURCE[0]}"
check "worktree-setup.sh is executable" '[ -x "$AGENTS_SRC/skills/feature-workflow/scripts/worktree-setup.sh" ]'
finish
