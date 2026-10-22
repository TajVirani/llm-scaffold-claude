#!/usr/bin/env bash
# Suite: install.sh (repo root): upgrade and project-owned files.
# Covers: upgrade that overwrites a changed file and removes a file dropped from the manifest while keeping files no
#   install shipped; project-owned files untouched by install, --force and upgrade (incl. .workflow/design-pattern-doc/
#   and .workflow/pr-quality/); .gitignore user lines kept.
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
check ".gitignore user lines kept, block added once" 'grep -qx "node_modules/" "$P/.gitignore" && grep -qx "\*.log" "$P/.gitignore" && [ "$(grep -c "^.workflow/specs/\*/.step$" "$P/.gitignore")" = 1 ] && [ "$(grep -c "^.workflow/initiatives/\*/.step$" "$P/.gitignore")" = 1 ]'

echo "== lint"
shellcheck_files "shellcheck: this suite" "${BASH_SOURCE[0]}"

finish
