#!/usr/bin/env bash
# Suite: the handoff skill's documented commands (skills/handoff/SKILL.md; the skill has no script, so its command
#   blocks are the component).
# Covers: the one bash block of `### 1. Locate` that names `.gitignore`, run as written with `stem` set, in a spec
#   worktree (JRN-001: the folder, its `*` ignore file and the new file name sit under the worktree, the main checkout
#   gets no handoff folder), in a repo with no workflow ignore block (JRN-002: git status names no handoff path) and twice
#   for one spec (JRN-003: two different names in the `<stem>--<UTC time>-<4 chars>.md` shape); the Resume section's
#   wording (JRN-006: resumed without asking, and the resumed handoff deleted). The extracted block is shellcheck-clean.
# shellcheck disable=SC2016,SC2034  # check expressions are single-quoted and eval'd on purpose, so their variables look unused
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
P=$WORK/proj
make_fixture_repo "$P"
SPEC_WT=$P/.workflow/.spec-worktrees/007-alpha
git -C "$P" worktree add -q "$SPEC_WT" -b spec/007-alpha 2>/dev/null
SKILL=$P/.agents/skills/handoff/SKILL.md
NAME_SHAPE='^007-alpha--[0-9]{8}T[0-9]{6}Z-[a-z0-9]{4}\.md$'

# locate_block : the fenced bash blocks of `### 1. Locate`; prints the one naming .gitignore, status 1 unless exactly one does.
locate_block() {
  awk '
    /^### 1\. Locate/ { in_section = 1; next }
    in_section && /^##/ { in_section = 0 }
    !in_section { next }
    !in_fence && /^[[:space:]]*```bash[[:space:]]*$/ { in_fence = 1; block = ""; next }
    in_fence && /^[[:space:]]*```[[:space:]]*$/ { in_fence = 0; if (block ~ /\.gitignore/) { hits++; kept = block }; next }
    in_fence { block = block $0 "\n" }
    END { if (hits != 1) exit 1; printf "%s", kept }
  ' "$SKILL"
}

LOCATE_SCRIPT=$WORK/locate.sh
if LOCATE_BLOCK=$(locate_block); then
  printf '#!/usr/bin/env bash\nstem=$1\n%s\nprintf '\''root=%%s\\nfile=%%s\\n'\'' "${root-}" "${file-}"\n' "$LOCATE_BLOCK" > "$LOCATE_SCRIPT"
else
  LOCATE_BLOCK=""
fi
MISSING_BLOCK="SKILL.md ### 1. Locate has no single bash block naming .gitignore, so there is no root or file to check"

# run_locate DIR STEM : run the Locate block in DIR with stem=STEM; sets LOC_ROOT and LOC_FILE ("" when the block is missing).
run_locate() {
  LOC_ROOT="" LOC_FILE=""
  [ -n "$LOCATE_BLOCK" ] || return 0
  local printed
  printed=$(cd "$1" && bash "$LOCATE_SCRIPT" "$2" 2>/dev/null)
  LOC_ROOT=$(sed -n 's/^root=//p' <<<"$printed" | tail -n 1)
  LOC_FILE=$(sed -n 's/^file=//p' <<<"$printed" | tail -n 1)
}

echo "== JRN-001 hand off from a spec worktree"
check "JRN-001 Locate section holds one bash block naming .gitignore" '[ -n "$LOCATE_BLOCK" ]' "$MISSING_BLOCK"
run_locate "$SPEC_WT" 007-alpha
eq "JRN-001 worktree run: root is the spec worktree" "$LOC_ROOT" "$SPEC_WT"
check "JRN-001 worktree run: the handoff folder and its .gitignore holding * are under the worktree" \
  '[ -d "$SPEC_WT/.workflow/.handoff" ] && [ "$(cat "$SPEC_WT/.workflow/.handoff/.gitignore" 2>/dev/null)" = "*" ]' \
  "$(ls -A "$SPEC_WT/.workflow/.handoff" 2>&1)"
check "JRN-001 worktree run: file is a new <stem>--<time>-<suffix>.md under the worktree's folder" \
  '[ "$(dirname "$LOC_FILE")" = "$SPEC_WT/.workflow/.handoff" ] && basename "$LOC_FILE" | grep -qE "$NAME_SHAPE" && [ ! -e "$LOC_FILE" ]' \
  "file=${LOC_FILE:-<unset>}; $MISSING_BLOCK when unset"
check "JRN-001 worktree run: the main checkout has no .workflow/.handoff/" \
  '[ -n "$LOC_FILE" ] && [ ! -e "$P/.workflow/.handoff" ]' "file=${LOC_FILE:-<unset>}; main has: $(ls -A "$P/.workflow" 2>&1)"

echo "== JRN-002 handoff stays out of git with no ignore block"
PLAIN=$WORK/plain
git_init_repo "$PLAIN"
echo readme > "$PLAIN/README.md"
git_commit_all "$PLAIN" init
run_locate "$PLAIN" 007-alpha
[ -z "$LOC_FILE" ] || : > "$LOC_FILE"
untracked=$(git -C "$PLAIN" status --porcelain --untracked-files=all)
check "JRN-002 written handoff and its folder are invisible to git status" \
  '[ -n "$LOC_FILE" ] && [ -f "$LOC_FILE" ] && ! grep -q "\.workflow/\.handoff" <<<"$untracked"' \
  "file=${LOC_FILE:-<unset>}; status: $untracked"

echo "== JRN-003 two runs, one spec, same second"
SAME_SECOND=$WORK/same-second
git_init_repo "$SAME_SECOND"
git_commit_all "$SAME_SECOND" init
# A stub date first on PATH pins the UTC timestamp, so both runs fall in the same second and only the suffix can differ.
FIXED_CLOCK=$WORK/fixed-clock
mkdir -p "$FIXED_CLOCK"
cat > "$FIXED_CLOCK/date" <<'STUB'
#!/usr/bin/env bash
if [ "$*" = "-u +%Y%m%dT%H%M%SZ" ]; then echo 20260101T120000Z; else exec /bin/date "$@"; fi
STUB
chmod +x "$FIXED_CLOCK/date"
PATH="$FIXED_CLOCK:$PATH" run_locate "$SAME_SECOND" 007-alpha
first_file=$LOC_FILE
[ -z "$first_file" ] || : > "$first_file"
PATH="$FIXED_CLOCK:$PATH" run_locate "$SAME_SECOND" 007-alpha
second_file=$LOC_FILE
first_name=$(basename "${first_file:-unset}")
second_name=$(basename "${second_file:-unset}")
TIME_FIELD='s/^.*--\([0-9]\{8\}T[0-9]\{6\}Z\)-.*$/\1/p'
first_time=$(sed -n "$TIME_FIELD" <<<"$first_name")
second_time=$(sed -n "$TIME_FIELD" <<<"$second_name")
check "JRN-003 with the clock fixed both runs carry the same timestamp" \
  '[ -n "$first_time" ] && [ "$first_time" = "$second_time" ]' \
  "first=$first_name second=$second_name"
check "JRN-003 two runs for 007-alpha in the same second give two different names" \
  '[ -n "$first_file" ] && [ -n "$second_file" ] && [ "$first_name" != "$second_name" ]' "first=$first_name second=$second_name"
check "JRN-003 both names have the <stem>--<UTC time>-<4 chars>.md shape" \
  'grep -qE "$NAME_SHAPE" <<<"$first_name" && grep -qE "$NAME_SHAPE" <<<"$second_name"' "first=$first_name second=$second_name"

echo "== JRN-006 resume rules are written down"
resume_section=$(awk '/^## Resume[[:space:]]*$/ { in_section = 1; next } in_section && /^## / { exit } in_section' "$SKILL")
check "JRN-006 Resume section says a handoff named by path is resumed without asking" \
  'grep -qF "without asking" <<<"$resume_section"' "Resume section lacks: without asking"
check "JRN-006 Resume section says to delete the handoff you resumed from" \
  'grep -qF "delete the handoff you resumed from" <<<"$resume_section"' "Resume section lacks: delete the handoff you resumed from"

if [ -n "$LOCATE_BLOCK" ]; then
  shellcheck_files "shellcheck: handoff skill Locate block" "$LOCATE_SCRIPT"
else
  check "shellcheck: handoff skill Locate block" false "$MISSING_BLOCK"
fi
finish
