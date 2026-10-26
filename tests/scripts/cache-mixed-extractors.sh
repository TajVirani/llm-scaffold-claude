#!/usr/bin/env bash
# Suite: JRN-004 "Mixed extractors merge": build-architecture.sh on a project with bash scripts and TS files whose profiles name
#   `bash`, `dependency-cruiser` and `none`, with DEPCRUISE pointed at a stub printing fixture JSON.
# Covers: one architecture graph holding both languages' files and edges; `--print-generator` naming the extractors that run,
#   sorted and comma-joined (`bash,dependency-cruiser`, `none` left out); a file claimed by two extractors (a duplicate
#   `source` in the merged graph) rejected with exit 2 naming the file. CAP-NEW-selectable-graph-extractor.
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
R="$WORK/repo"
git_init_repo "$R"
mkdir -p "$R/scripts" "$R/src"
cat >"$R/scripts/build.sh" <<'EOF'
#!/usr/bin/env bash
# Builds the web app.
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
EOF
printf '# Shared build helpers.\nlog() { echo "$1"; }\n' >"$R/scripts/lib.sh"
echo 'import { util } from "./util";' >"$R/src/app.ts"
echo 'export const util = 1;' >"$R/src/util.ts"
write_profile "$R" shell-scripts bash
write_profile "$R" web dependency-cruiser
write_profile "$R" agent-docs none
git_commit_all "$R" init

echo '{"modules":[{"source":"src/app.ts","dependencies":[{"resolved":"src/util.ts"}]},{"source":"src/util.ts","dependencies":[]}]}' >"$WORK/ts.json"
depcruise_stub "$WORK/depcruise" "$WORK/ts.json"
echo '{"modules":[{"source":"src/app.ts","dependencies":[]},{"source":"scripts/build.sh","dependencies":[]}]}' >"$WORK/dup.json"
depcruise_stub "$WORK/depcruise-dup" "$WORK/dup.json"
cd "$R" || exit 1

# section BODY NAME : the non-blank lines between "## NAME" and the next "## " heading.
section() { printf '%s\n' "$1" | awk -v h="## $2" '/^## / { on = ($0 == h); next } on && NF'; }

echo "== JRN-004 merged graph"
arch=$(DEPCRUISE="$WORK/depcruise" "$B" --cache architecture --scope scripts --scope src); rc=$?
eq "JRN-004 architecture exits 0" "$rc" 0
eq "JRN-004 one graph holds the bash and TS nodes" \
  "$(printf '%s\n' "$arch" | awk '/^```mermaid/ {m=1; next} /^```/ {m=0} m && /\[/' | tr -d ' ' | tr '\n' '|')" \
  'scripts_build_sh["scripts/build.sh"]|scripts_lib_sh["scripts/lib.sh"]|src_app_ts["src/app.ts"]|src_util_ts["src/util.ts"]|'
eq "JRN-004 edges from both extractors" "$(section "$arch" Edges)" '- `scripts/build.sh` → `scripts/lib.sh`
- `src/app.ts` → `src/util.ts`'

echo "== JRN-004 generator"
out=$("$B" --print-generator 2>&1); rc=$?
eq "JRN-004 --print-generator exits 0" "$rc" 0
eq "JRN-004 generator names bash,dependency-cruiser" "$out" "bash,dependency-cruiser"

echo "== JRN-004 a file claimed by two extractors"
out=$(DEPCRUISE="$WORK/depcruise-dup" "$B" --cache architecture --scope scripts --scope src 2>&1); rc=$?
eq "JRN-004 a duplicate source across extractors exits 2" "$rc" 2
check "JRN-004 the error names the duplicated file and no body is printed" \
  'printf "%s" "$out" | grep -qF scripts/build.sh && ! printf "%s" "$out" | grep -q "^# Architecture"' "$out"

shellcheck_files "shellcheck: build-architecture.sh, extractors/bash.sh, extractors/dependency-cruiser.sh" \
  "$B" "$S/extractors/bash.sh" "$S/extractors/dependency-cruiser.sh"
finish
