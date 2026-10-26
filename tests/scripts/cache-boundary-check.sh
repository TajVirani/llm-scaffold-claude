#!/usr/bin/env bash
# Suite: JRN-006 "Bash project with a boundary config builds architecture without depcruise": build-architecture.sh on a
#   bash fixture project with a committed .workflow/tools/boundaries/dependency-cruiser.cjs, first with only a
#   `graph_extractor: bash` profile, then with a second profile naming `dependency-cruiser`.
# Covers: with no profile selecting dependency-cruiser, the boundary check never runs depcruise and Boundary violations
#   reads the "no boundary checker" line naming the `--print-generator` extractors, the body passing check-staged-cache.sh;
#   with a profile selecting dependency-cruiser, depcruise runs the boundary check and its violations are listed.
#   CAP-004.
# shellcheck disable=SC2016  # literal Markdown backticks in single quotes; check expressions are eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/graph-extractors.sh
source "$TESTS_DIR/fixtures/graph-extractors.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
S="$WORK/scaffold/.agents/skills/regenerate-caches/scripts"
B="$S/build-architecture.sh"
C="$S/check-staged-cache.sh"
R="$WORK/repo"
git_init_repo "$R"
mkdir -p "$R/scripts" "$R/.workflow/tools/boundaries"
cat >"$R/scripts/build.sh" <<'EOF'
#!/usr/bin/env bash
# Builds the release.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
EOF
printf '# Shared build helpers.\nlog() { echo "$1"; }\n' >"$R/scripts/lib.sh"
printf 'module.exports = { forbidden: [] };\n' >"$R/.workflow/tools/boundaries/dependency-cruiser.cjs"
write_profile "$R" shell-scripts bash
git_commit_all "$R" init

# A depcruise stand-in that records each run in a marker file and fails, for the run that must not call it.
cat >"$WORK/depcruise-refusing" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$WORK/depcruise-refusing.ran"
echo "depcruise must not run for this project" >&2
exit 3
EOF
chmod +x "$WORK/depcruise-refusing"

# A depcruise stand-in that answers the boundary check (--config) with violations, exiting 1 as depcruise does when it
#   finds some, and the graph run with the TS graph.
echo '{"modules":[{"source":"src/app.ts","dependencies":[{"resolved":"src/util.ts"}]},{"source":"src/util.ts","dependencies":[]}]}' \
  >"$WORK/ts.json"
cat >"$WORK/violations.json" <<'EOF'
{"modules":[],"summary":{"violations":[
 {"rule":{"name":"util-not-to-app"},"from":"src/util.ts","to":"src/app.ts"}]}}
EOF
cat >"$WORK/depcruise-answering" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$WORK/depcruise-answering.ran"
case " \$* " in
  *" --config "*) cat "$WORK/violations.json"; exit 1 ;;
  *) cat "$WORK/ts.json" ;;
esac
EOF
chmod +x "$WORK/depcruise-answering"
cd "$R" || exit 1

# section BODY NAME : the non-blank lines between "## NAME" and the next "## " heading.
section() { printf '%s\n' "$1" | awk -v h="## $2" '/^## / { on = ($0 == h); next } on && NF'; }

echo "== JRN-006 run 1: bash profile only, boundary config committed"
arch=$(DEPCRUISE="$WORK/depcruise-refusing" "$B" --cache architecture --scope scripts 2>"$WORK/run1.err"); rc=$?
eq "JRN-006 run 1 architecture exits 0" "$rc" 0
check "JRN-006 run 1 never runs depcruise" '[ ! -e "$WORK/depcruise-refusing.ran" ]' \
  "$(cat "$WORK/depcruise-refusing.ran" 2>/dev/null; cat "$WORK/run1.err")"
eq "JRN-006 run 1 Boundary violations names the extractors with no boundary checker" \
  "$(section "$arch" "Boundary violations")" \
  "Not checked: no boundary checker for this project's graph extractors (bash)."
mkdir -p .workflow/.cache-staging
printf '%s\n' "$arch" >.workflow/.cache-staging/architecture.md
t "JRN-006 run 1 check-staged-cache.sh passes the architecture body" 0 "$C" architecture .workflow/.cache-staging/architecture.md
rm -rf .workflow/.cache-staging

echo "== JRN-006 run 2: a second profile selects dependency-cruiser"
mkdir -p src
echo 'export const util = 1;' >src/util.ts
echo 'import { util } from "./util";' >src/app.ts
write_profile "$R" web dependency-cruiser
git_commit_all "$R" "add the web profile"
arch=$(DEPCRUISE="$WORK/depcruise-answering" "$B" --cache architecture --scope scripts --scope src 2>"$WORK/run2.err"); rc=$?
eq "JRN-006 run 2 architecture exits 0" "$rc" 0
check "JRN-006 run 2 runs depcruise for the boundary check" \
  'grep -q -- "--config" "$WORK/depcruise-answering.ran" 2>/dev/null' \
  "$(cat "$WORK/depcruise-answering.ran" 2>/dev/null; cat "$WORK/run2.err")"
eq "JRN-006 run 2 Boundary violations lists the stub's violations" \
  "$(section "$arch" "Boundary violations")" '- `util-not-to-app`: `src/util.ts` → `src/app.ts`'

shellcheck_files "shellcheck: build-architecture.sh, check-staged-cache.sh, extractors/bash.sh, extractors/dependency-cruiser.sh" \
  "$B" "$C" "$S/extractors/bash.sh" "$S/extractors/dependency-cruiser.sh"
finish
