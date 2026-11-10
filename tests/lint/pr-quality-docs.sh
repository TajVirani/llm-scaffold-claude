#!/usr/bin/env bash
# Suite: pr-quality's Step 0, which skips the checks the workflow's Phase 4 review already settled.
# Covers: SKILL.md has a Step 0 before Step 1 that names the done status and in-review once sent to sign-off, skips duplicate detection, seam
#   conformance and documentation conformance and the covered_by_review project checks, keeps orphan detection, complexity
#   and the expert panel, and puts the skips in the report; the project-check template carries the covered_by_review key;
#   this repo's commit-hygiene check sets it and payload-bookkeeping does not. Step 0's two bash blocks, run in a fixture
#   repo: the spec status from a spec/ branch, the last triage Outcome line after it, from the Done folder, from a spec folder the diff touches on another branch,
#   nothing with no spec or with two spec folders in the diff, and the covered project checks listed (a check with no
#   frontmatter left out). Reads the repo; writes only to a scratch dir.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight
new_workdir

PRQ=$AGENTS_SRC/skills/pr-quality
SKILL=$PRQ/SKILL.md
TEMPLATE=$PRQ/assets/project-check.template.md

step0=$(awk '/^### Step 0/ { on = 1; next } on && /^### / { exit } on' "$SKILL")
# block N : print the Nth fenced bash block of Step 0, with the list indent removed.
block() {
  awk -v n="$1" '/^ *```bash$/ { c++; on = (c == n); next } /^ *```$/ { on = 0 } on' <<<"$step0" | sed 's/^  //'
}

echo "== SKILL.md Step 0"
check "Step 0 exists" '[ -n "$step0" ]'
check "Step 0 comes before Step 1" \
  '[ "$(grep -n "^### Step 0" "$SKILL" | cut -d: -f1)" -lt "$(grep -n "^### Step 1" "$SKILL" | cut -d: -f1)" ]'
check "Step 0 names the done status and in-review sent to sign-off" \
  'grep -q "status \`done\`, or status \`in-review\` with an outcome line ending \`to sign-off\`" <<<"$step0"'
check "Step 0 skips duplicate detection, seam conformance and documentation conformance" \
  'grep -q "skip Agent 1 (duplicate detection), Agent 4 (seam conformance) and Agent 5 (documentation conformance)" <<<"$step0"'
check "Step 0 skips the covered_by_review project checks" 'grep -q "covered_by_review" <<<"$step0"'
check "orphan detection, complexity, the other project checks and the expert panel still run" \
  'grep -q "Orphan detection, complexity, the other project checks and the expert panel still run" <<<"$step0"'
check "Step 2 leaves out what Step 0 skipped" 'grep -q "leaving out the ones Step 0 skipped" "$SKILL"'
check "the report states the skips and why" 'grep -q "Review phase settled: spec <slug> is <status>; skipped" "$SKILL"'
check "the project-check contract documents covered_by_review" 'grep -q "^- \*\*Covered by the review phase:\*\*" "$SKILL"'

echo "== the covered_by_review key"
fm() { yq --front-matter=extract "$1" "$2" 2>/dev/null; }
eq "the template carries covered_by_review: false" "$(fm '.covered_by_review' "$TEMPLATE")" "false"
eq "commit-hygiene is covered by the review phase" "$(fm '.covered_by_review' "$REPO_ROOT/.workflow/pr-quality/commit-hygiene.md")" "true"
check "payload-bookkeeping is not" '! grep -q "covered_by_review: true" "$REPO_ROOT/.workflow/pr-quality/payload-bookkeeping.md"'

echo "== Step 0's commands in a fixture repo"
R=$WORK/repo
git_init_repo "$R"
mkdir -p "$R/.workflow/pr-quality" "$R/.workflow/specs/012-alpha" "$R/.workflow/specs/done/011-old" "$R/.workflow/specs/013-beta"
printf 'readme\n' >"$R/README.md"
git_commit_all "$R" "base"
git -C "$R" update-ref refs/remotes/origin/main HEAD
# spec_md DIR STATUS : write a spec.md with only the status key.
spec_md() { printf -- '---\nstatus: %s\n---\n# Spec\n' "$2" >"$R/$1/spec.md"; }
spec_md .workflow/specs/012-alpha in-review
spec_md .workflow/specs/done/011-old "done"
spec_md .workflow/specs/013-beta draft
printf -- '---\ncovered_by_review: true\n---\n# Covered\n' >"$R/.workflow/pr-quality/covered.md"
printf -- '---\ncovered_by_review: false\n---\n# Runs\n' >"$R/.workflow/pr-quality/runs.md"
printf '# No frontmatter\n\n## Objective\n\nx: y\n' >"$R/.workflow/pr-quality/plain.md"
FIND=$(block 1)
LIST=$(block 2)
check "Step 0 has its two bash blocks" '[ -n "$FIND" ] && [ -n "$LIST" ]'
# status_on BRANCH : switch the fixture to BRANCH and print what Step 0's first block prints there.
status_on() {
  git -C "$R" switch -q -C "$1" main
  (cd "$R" && bash -c "$FIND" 2>/dev/null)
}
git -C "$R" add -A >/dev/null
git -C "$R" commit -q -m "specs and checks"
git -C "$R" update-ref refs/remotes/origin/main HEAD
eq "a spec/ branch prints its spec's status, and no outcome before any triage pass" "$(status_on spec/012-alpha)" "in-review"
eq "a spec/ branch whose spec is in the Done folder prints done" "$(status_on spec/011-old)" "done"
eq "a spec/ branch of a draft spec prints draft" "$(status_on spec/013-beta)" "draft"
printf '## 2026-11-01 Review pass 1\n\nOutcome: rework 1 of 5\n\n## 2026-11-02 Review pass 2\n\nOutcome: clean, to sign-off\n' >"$R/.workflow/specs/013-beta/design-log.md"
git -C "$R" switch -q main
git -C "$R" add -A >/dev/null
git -C "$R" commit -q -m "triage passes"
git -C "$R" update-ref refs/remotes/origin/main HEAD
eq "a spec with triage passes prints its status and its last outcome line" "$(status_on spec/013-beta)" "draft"$'\n'"Outcome: clean, to sign-off"
git -C "$R" switch -q -C fix/touch-one main
printf 'more\n' >>"$R/.workflow/specs/012-alpha/spec.md"
git -C "$R" commit -q -am "touch 012"
eq "another branch takes the one spec folder its diff touches" "$( (cd "$R" && bash -c "$FIND" 2>/dev/null) )" "in-review"
printf 'more\n' >>"$R/.workflow/specs/013-beta/spec.md"
git -C "$R" commit -q -am "touch 013"
eq "two spec folders in the diff print nothing" "$( (cd "$R" && bash -c "$FIND" 2>/dev/null) )" ""
eq "a branch with no spec and no spec folder in its diff prints nothing" "$(status_on fix/no-spec)" ""
eq "the covered project checks are listed, a file with no frontmatter left out" \
  "$( (cd "$R" && bash -c "$LIST" 2>/dev/null) )" ".workflow/pr-quality/covered.md"
t "the listing exits 0" 0 bash -c "cd '$R' && $LIST"

shellcheck_files "shellcheck: pr-quality-docs suite" "$TESTS_DIR/lint/pr-quality-docs.sh"
finish
