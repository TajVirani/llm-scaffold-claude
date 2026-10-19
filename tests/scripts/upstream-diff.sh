#!/usr/bin/env bash
# Suite: scripts/upstream-diff.sh (scaffold-only lineage diff), offline only.
# Covers: argument handling (help, unknown flag, missing values, bad --repo, missing or invalid lineage, --repo with no
#   entry), entry selection (--repo, repeatable; --path prefix; --dry-run lists without cloning), the "unknown" commit
#   skip with a warning, and a real run against local file:// upstreams: changed vs unchanged entries, diff headers,
#   --summary-only, --ref, a commit missing upstream (exit 3), --cache reuse, and that the lineage file is not modified.
# shellcheck disable=SC2016,SC2034  # check expressions are single-quoted and eval'd on purpose; their variables look unused
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
new_workdir

# The component under test, copied into the fixture so the run never touches the repo.
mkdir -p "$WORK/scaffold/scripts"
cp "$REPO_ROOT/scripts/upstream-diff.sh" "$WORK/scaffold/scripts/"
UD=$WORK/scaffold/scripts/upstream-diff.sh

# Two local upstreams: alpha has a file that changes after the pin and one that does not; beta changes nothing.
mk_upstream() {
  git_init_repo "$1"
  mkdir -p "$1/skills/x"
  printf 'one\n' >"$1/skills/x/SKILL.md"
  printf 'stable\n' >"$1/skills/x/STABLE.md"
  git_commit_all "$1" base
}
A=$WORK/up/alpha
B=$WORK/up/beta
mk_upstream "$A"
mk_upstream "$B"
A0=$(git -C "$A" rev-parse HEAD)
B0=$(git -C "$B" rev-parse HEAD)
printf 'two\n' >"$A/skills/x/SKILL.md"
git_commit_all "$A" change
A1=$(git -C "$A" rev-parse HEAD)
git -C "$A" tag mid "$A1"
printf 'three\n' >"$A/skills/x/SKILL.md"
git_commit_all "$A" change-again

LIN=$WORK/lineage.json
jq -n --arg a "file://$A" --arg b "file://$B" --arg a0 "$A0" --arg b0 "$B0" '{
  version: 1,
  upstreams: {
    "o/alpha": {url: $a, license: "MIT", aliases: ["o/alpha"]},
    "o/beta": {url: $b, license: "MIT", aliases: ["o/beta"]}
  },
  entries: [
    {path: ".agents/skills/one/SKILL.md", kind: "derived", upstream_repo: "o/alpha", upstream_path: "skills/x/SKILL.md", upstream_commit: $a0, commit_basis: "pinned", changes: ["c"], why: "w", reviewed_at: "2026-10-19"},
    {path: ".agents/skills/one/STABLE.md", kind: "derived", upstream_repo: "o/alpha", upstream_path: "skills/x/STABLE.md", upstream_commit: $a0, commit_basis: "pinned", changes: ["c"], why: "w", reviewed_at: "2026-10-19"},
    {path: ".agents/agents/two.md", kind: "derived", upstream_repo: "o/beta", upstream_path: "skills/x/SKILL.md", upstream_commit: $b0, commit_basis: "pinned", changes: ["c"], why: "w", reviewed_at: "2026-10-19"},
    {path: ".agents/agents/three.md", kind: "derived", upstream_repo: "o/beta", upstream_path: "skills/x/STABLE.md", upstream_commit: "unknown", commit_basis: "survey-date", changes: ["c"], why: "w", reviewed_at: "2026-10-19"}
  ]
}' >"$LIN"
LIN_SUM=$(cksum <"$LIN")

echo "== arguments"
t "--help exits 0" 0 bash "$UD" --help
out=$(bash "$UD" --help 2>&1)
check "--help prints usage" 'printf "%s" "$out" | grep -q -- "--dry-run"'
t "unknown flag exits 2" 2 bash "$UD" --bogus
t "--repo without a value exits 2" 2 bash "$UD" --repo
t "--repo not OWNER/REPO exits 2" 2 bash "$UD" --lineage "$LIN" --repo alpha
t "--ref without a value exits 2" 2 bash "$UD" --lineage "$LIN" --ref
t "missing lineage file exits 2" 2 bash "$UD" --lineage "$WORK/nope.json" --dry-run
printf '{"version":1}\n' >"$WORK/bad.json"
t "lineage without entries exits 2" 2 bash "$UD" --lineage "$WORK/bad.json" --dry-run
t "--repo with no entry exits 2" 2 bash "$UD" --lineage "$LIN" --repo o/gamma --dry-run
t "--path matching nothing exits 2" 2 bash "$UD" --lineage "$LIN" --path .agents/hooks/ --dry-run

echo "== selection (dry run, no clones)"
out=$(bash "$UD" --lineage "$LIN" --dry-run 2>/dev/null)
eq "dry run lists every entry" "$(printf '%s\n' "$out" | grep -cE '^(would|skipped) ')" "4"
out=$(bash "$UD" --lineage "$LIN" --dry-run --repo o/alpha 2>/dev/null)
eq "--repo selects only that upstream" "$(printf '%s\n' "$out" | grep -cE '^(would|skipped) ')" "2"
check "--repo o/alpha names no beta entry" '! printf "%s" "$out" | grep -q "o/beta"'
out=$(bash "$UD" --lineage "$LIN" --dry-run --repo o/alpha --repo o/beta 2>/dev/null)
eq "--repo is repeatable" "$(printf '%s\n' "$out" | grep -cE '^(would|skipped) ')" "4"
out=$(bash "$UD" --lineage "$LIN" --dry-run --path .agents/agents/ 2>/dev/null)
eq "--path selects by prefix" "$(printf '%s\n' "$out" | grep -cE '^(would|skipped) ')" "2"
err=$(bash "$UD" --lineage "$LIN" --dry-run --repo o/beta 2>&1 >/dev/null)
check "unknown commit warns on stderr" 'printf "%s" "$err" | grep -q "three.md.*unknown; skipped"'
out=$(bash "$UD" --lineage "$LIN" --dry-run --repo o/beta 2>/dev/null)
check "unknown commit is listed as skipped" 'printf "%s" "$out" | grep -q "^skipped .*three.md.*upstream_commit unknown"'
bash "$UD" --lineage "$LIN" --dry-run --cache "$WORK/drycache" >/dev/null 2>&1
check "dry run clones nothing (no cache dir created)" '[ ! -e "$WORK/drycache" ]'

echo "== real run against local upstreams"
out=$(bash "$UD" --lineage "$LIN" 2>"$WORK/err")
rc=$?
eq "real run exits 0" "$rc" "0"
check "changed entry is reported" 'printf "%s" "$out" | grep -q "^changed .*one/SKILL.md <- o/alpha:skills/x/SKILL.md"'
check "unchanged entry is reported" 'printf "%s" "$out" | grep -q "^unchanged .*one/STABLE.md"'
check "beta entry unchanged" 'printf "%s" "$out" | grep -q "^unchanged .*two.md"'
check "unknown commit skipped in a real run" 'printf "%s" "$out" | grep -q "^skipped .*three.md" && grep -q "unknown; skipped" "$WORK/err"'
check "diff header printed for the changed entry" 'printf "%s" "$out" | grep -q "^=== .agents/skills/one/SKILL.md <- o/alpha:skills/x/SKILL.md"'
check "diff shows the upstream change to HEAD" 'printf "%s" "$out" | grep -q "^+three"'
check "summary counts changed entries" 'printf "%s" "$out" | grep -q "^1 of 4 entries changed upstream"'

out=$(bash "$UD" --lineage "$LIN" --summary-only 2>/dev/null)
check "--summary-only prints no diff" '! printf "%s" "$out" | grep -q "^==="'
check "--summary-only still prints the summary" 'printf "%s" "$out" | grep -q "^changed "'

out=$(bash "$UD" --lineage "$LIN" --repo o/alpha --ref mid 2>/dev/null)
check "--ref compares against that ref" 'printf "%s" "$out" | grep -q "^+two" && ! printf "%s" "$out" | grep -q "^+three"'

jq --arg z "0000000000000000000000000000000000000000" '.entries[0].upstream_commit = $z' "$LIN" >"$WORK/missing.json"
out=$(bash "$UD" --lineage "$WORK/missing.json" --repo o/alpha 2>/dev/null)
rc=$?
eq "commit missing upstream exits 3" "$rc" "3"
check "commit missing upstream is skipped with a reason" 'printf "%s" "$out" | grep -q "^skipped .*commit 0000000000000000000000000000000000000000 not found upstream"'

C=$WORK/cache
t "--cache run exits 0" 0 bash "$UD" --lineage "$LIN" --repo o/alpha --summary-only --cache "$C"
check "--cache keeps the clone" '[ -d "$C/o_alpha/.git" ]'
t "--cache re-run fetches into the kept clone" 0 bash "$UD" --lineage "$LIN" --repo o/alpha --summary-only --cache "$C"

eq "lineage file not modified" "$(cksum <"$LIN")" "$LIN_SUM"

shellcheck_files "shellcheck scripts/upstream-diff.sh tests/scripts/upstream-diff.sh" "$REPO_ROOT/scripts/upstream-diff.sh" "$TESTS_DIR/scripts/upstream-diff.sh"
finish
