#!/usr/bin/env bash
# Suite: D85 task-breakdown helpers (feature-workflow/scripts): task-waves.sh (predicted-file overlap, implied edges, parallel_with,
#   cycles, waves, JSON), rules-setting.sh (## Workflow settings, task_review), open-task-pr.sh (gh / glab stubs on PATH, skip paths,
#   --record; never the network) and run-toolchain.sh test scoping (other unfinished tasks' Phase 1 tests excluded, test_scoped,
#   --exclude-unfinished, unscoped warning).
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
preflight

new_workdir
copy_agents "$WORK/scaffold"
S="$WORK/scaffold/.agents/skills/feature-workflow/scripts"
TW() { bash "$S/task-waves.sh" "$@"; }
RS() { bash "$S/rules-setting.sh" "$@"; }

echo "== task-waves.sh: overlap rule"
pair() { # want a b
  printf -- "---\ntasks:\n  - {id: T1, status: pending, depends_on: [], predicted_files: ['%s']}\n  - {id: T2, status: pending, depends_on: [], predicted_files: ['%s']}\n---\n" "$2" "$3" > "$WORK/pair.md"
  eq "overlap $2 ~ $3" "$(TW --tasks-file "$WORK/pair.md" --json 2>/dev/null | jq -r '.overlaps[0].matches[0].rule // "none"')" "$1"
}
pair identical      src/a.ts       src/a.ts
pair identical      src/a.ts       ./src/a.ts
pair none           src/a.ts       src/b.ts
pair glob-match     'src/*.ts'     src/a.ts
pair none           'src/*.ts'     src/x/a.ts
pair glob-match     'src/**'       src/x/a.ts
pair glob-match     'src/**/a.ts'  src/a.ts
pair glob-match     src/           src/x/y.ts
pair glob-match     'src/?.ts'     src/a.ts
pair none           'src/?.ts'     src/ab.ts
pair none           'src/[ab].ts'  src/c.ts
pair glob-intersect 'src/lib/**'   'src/lib/**/*.ts'
pair none           'src/lib/**'   'src/*.css'
pair none           'src/*.ts'     'src/*.css'
pair glob-intersect 'src/a*'       'src/*b'
pair none           'a/**'         'b/**'
pair none           src/a.ts       src/a.ts.bak

echo "== task-waves.sh: graph"
cat > "$WORK/t.md" <<'EOF'
---
tasks:
  - {id: T1, status: pending, depends_on: [], predicted_files: [src/a.ts, src/lib/], size: {files: 2, est_lines: 50, points: S}, mode: afk, parallel_with: [T3]}
  - {id: T2, status: pending, depends_on: [], predicted_files: [src/a.ts, src/b.ts], size: {files: 2, est_lines: 80, points: M}, mode: hitl, parallel_with: []}
  - {id: T3, status: pending, depends_on: [], predicted_files: ['src/lib/**/*.ts'], size: {files: 3, est_lines: 90, points: S}, mode: afk, parallel_with: [T1]}
  - {id: T4, status: pending, depends_on: [T2], predicted_files: [src/b.ts], size: {files: 1, est_lines: 5, points: S}, mode: afk, parallel_with: []}
  - {id: T5, status: split-out, depends_on: [], predicted_files: [src/a.ts]}
---
EOF
out=$(TW --tasks-file "$WORK/t.md" --json 2>"$WORK/err"); rc=$?
eq "graph rc" "$rc" 0
eq "waves" "$(jq -c '[.waves[] | .tasks]' <<<"$out")" '[["T1","T3"],["T2"],["T4"]]'
eq "implied edge T2<-T1" "$(jq -c .implied_edges <<<"$out")" '[{"task":"T2","depends_on":"T1"}]'
eq "T1/T3 parallel_with" "$(jq -r '.overlaps[] | select(.a=="T1" and .b=="T3") | .resolution' <<<"$out")" parallel_with
eq "T2/T4 ordered" "$(jq -r '.overlaps[] | select(.a=="T2" and .b=="T4") | .resolution' <<<"$out")" ordered
eq "split-out left out" "$(jq -r '[.tasks[].id] | index("T5")' <<<"$out")" null
eq "T2 overlaps" "$(jq -c '.tasks[] | select(.id=="T2") | .overlaps' <<<"$out")" '["T1","T4"]'
eq "no warnings" "$(jq -c .warnings <<<"$out")" '[]'
txt=$(TW --tasks-file "$WORK/t.md" 2>/dev/null)
check "text: wave lines" 'grep -q "^- Wave 1: T1, T3$" <<<"$txt" && grep -q "^- Wave 2: T2$" <<<"$txt"' "$txt"
check "text: dashed implied edge" 'grep -q "T1 -.->|overlap| T2" <<<"$txt" && grep -q "T2 --> T4" <<<"$txt"' "$txt"
check "text: quiz table row" 'grep -q "^| 2 | T2 | M | hitl | T1, T4 |$" <<<"$txt"' "$txt"
check "text: overlap row" 'grep -q "^| T1, T2 | \`src/a.ts\` | identical | implied: T2 depends_on T1 |$" <<<"$txt"' "$txt"

yq --front-matter=process -i '.tasks[2].parallel_with = []' "$WORK/t.md"
out=$(TW --tasks-file "$WORK/t.md" --json 2>"$WORK/err")
eq "one-sided parallel_with -> edge" "$(jq -c '[.implied_edges[] | select(.task=="T3")]' <<<"$out")" '[{"task":"T3","depends_on":"T1"}]'
check "one-sided parallel_with warns" 'grep -q "only T1 lists the other" "$WORK/err"' "$(cat "$WORK/err")"

printf -- "---\ntasks:\n  - {id: T1, status: pending, depends_on: [T2]}\n  - {id: T2, status: pending, depends_on: [T1]}\n---\n" > "$WORK/c.md"
t "cycle -> 2"                     2 TW --tasks-file "$WORK/c.md"
printf -- "---\ntasks:\n  - {id: T1, status: pending, depends_on: [T9]}\n---\n" > "$WORK/c.md"
t "unknown depends_on -> 2"        2 TW --tasks-file "$WORK/c.md"
printf -- "---\ntasks:\n  - {id: T1, status: pending, depends_on: [], parallel_with: [T7]}\n---\n" > "$WORK/c.md"
t "unknown parallel_with -> 2"     2 TW --tasks-file "$WORK/c.md"
printf -- "---\ntasks:\n  - {id: T1, status: pending, depends_on: []}\n  - {id: T1, status: pending, depends_on: []}\n---\n" > "$WORK/c.md"
t "duplicate id -> 2"              2 TW --tasks-file "$WORK/c.md"
printf -- "---\ntasks:\n  - {id: T10, status: pending, depends_on: [T2]}\n  - {id: T2, status: pending, depends_on: []}\n---\n" > "$WORK/c.md"
eq "numeric id order" "$(TW --tasks-file "$WORK/c.md" --json 2>/dev/null | jq -c '[.waves[].tasks]')" '[["T2"],["T10"]]'
t "usage: no args -> 1"            1 TW
t "missing file -> 1"              1 TW --tasks-file "$WORK/none.md"

git_init_repo "$WORK/p"
mkdir -p "$WORK/p/.workflow/specs/001-demo"
cp "$WORK/t.md" "$WORK/p/.workflow/specs/001-demo/tasks.md"
git_commit_all "$WORK/p" init
git -C "$WORK/p" worktree add -q "$WORK/p-wt" -b wt 2>/dev/null
t "--spec-dir from main"           0 TW --spec-dir .workflow/specs/001-demo --cwd "$WORK/p"
t "--spec-dir from a worktree"     0 TW --spec-dir .workflow/specs/001-demo --cwd "$WORK/p-wt"
t "bad spec dir -> 1"              1 TW --spec-dir .workflow/specs/demo --cwd "$WORK/p"

echo "== rules-setting.sh"
RULES_T="$WORK/scaffold/.agents/skills/project-setup/assets/docs/rules.md"
eq "template default pr" "$(RS task_review --rules "$RULES_T" 2>/dev/null)" pr
printf '## Workflow settings  \n\n```yaml\ntask_review: local\n```\n\n## Other\n\n```yaml\ntask_review: pr\n```\n' > "$WORK/r.md"
eq "local read" "$(RS task_review --rules "$WORK/r.md")" local
printf '## Workflow settings\n\n```yaml\ntask_review: pr-blocking\n```\n' > "$WORK/r.md"
eq "pr-blocking read" "$(RS task_review --rules "$WORK/r.md")" pr-blocking
printf '## Workflow settings\n\nnone yet\n' > "$WORK/r.md"
eq "no block -> default" "$(RS task_review --rules "$WORK/r.md" 2>/dev/null)" pr
printf '## Workflow settings\n\n```yaml\nother: 1\n```\n' > "$WORK/r.md"
eq "no key -> default" "$(RS task_review --rules "$WORK/r.md" 2>/dev/null)" pr
eq "missing rules.md -> default" "$(RS task_review --rules "$WORK/nope.md" 2>/dev/null)" pr
printf '## Workflow settings\n\n```yaml\ntask_review: maybe\n```\n' > "$WORK/r.md"
t "bad value -> 1"                 1 RS task_review --rules "$WORK/r.md"
printf '## Workflow settings\n\n```yaml\n- a\n```\n' > "$WORK/r.md"
t "not a map -> 1"                 1 RS task_review --rules "$WORK/r.md"
t "unknown key -> 1"               1 RS nope --rules "$WORK/r.md"
mkdir -p "$WORK/p/.workflow"; printf '## Workflow settings\n\n```yaml\ntask_review: local\n```\n' > "$WORK/p/.workflow/rules.md"
eq "main checkout rules from worktree cwd" "$(RS task_review --cwd "$WORK/p-wt")" local
# generate-boundary-config ignores the section (reads Ownership and Shared core only)
GB=$WORK/gb; mkdir -p "$GB/.workflow"; cp "$RULES_T" "$GB/.workflow/rules.md"
printf '\n## Workflow settings\n\n```yaml\ntask_review: pr-blocking\n```\n' >> "$GB/.workflow/rules.md"
gb_out=$(bash "$WORK/scaffold/.agents/skills/project-setup/scripts/generate-boundary-config.sh" --print-intermediate "$GB" 2>&1); gb_rc=$?
check "boundary generator ignores ## Workflow settings" '[ $gb_rc -eq 0 ] && ! grep -q task_review <<<"$gb_out"' "$gb_out"

echo "== open-task-pr.sh (stubbed gh / glab, no network)"
P=$WORK/pr
git_init_repo "$P"
mkdir -p "$P/.workflow/specs/007-shop/artifacts/T2" "$P/bin"
cat > "$P/.workflow/specs/007-shop/spec.md" <<'EOF'
---
status: in-progress
spec_branch: spec/007-shop
---
EOF
cat > "$P/.workflow/specs/007-shop/tasks.md" <<'EOF'
---
tasks:
  - {id: T1, title: "light", status: in-progress, capability: CAP-001, depends_on: [], touches_core: false, work_type: null, branch: null}
  - {id: T2, title: "cart total", status: in-progress, capability: CAP-001, depends_on: [], touches_core: false, work_type: null, file: tasks/T02-cart.md, branch: task/007-shop/T02-cart, pr: null}
---
EOF
touch "$P/.workflow/specs/007-shop/artifacts/T2/mini-review.yaml"
git_commit_all "$P" init
git -C "$P" branch spec/007-shop; git -C "$P" branch task/007-shop/T02-cart
git init -q --bare "$WORK/origin.git"
STUBLOG=$WORK/stub.log
for cli in gh glab; do
  cat > "$P/bin/$cli" <<EOF
#!/usr/bin/env bash
echo "$cli \$*" >> "$STUBLOG"
case "\$1 \$2" in
  "auth status") [ -z "\${STUB_NOAUTH:-}" ] ;;
  "pr list"|"mr list") [ -z "\${STUB_EXISTING:-}" ] || echo "\$STUB_EXISTING" ;;
  "pr create") echo "Creating pull request..."; echo "https://github.com/o/r/pull/12" ;;
  "mr create") echo "Creating merge request"; echo "!5 T2: cart total (task/007-shop/T02-cart)"; echo " https://gitlab.com/o/r/-/merge_requests/5" ;;
esac
EOF
  chmod +x "$P/bin/$cli"
done
OTP() { env PATH="$P/bin:$PATH" bash "$S/open-task-pr.sh" "$@"; }
SPECD=.workflow/specs/007-shop
out=$(OTP $SPECD T2 --cwd "$P" 2>/dev/null); eq "no origin -> skipped" "$out" "skipped: no origin remote"
git -C "$P" remote add origin https://github.com/o/r.git
git -C "$P" config remote.origin.pushurl "$WORK/origin.git"
out=$(OTP $SPECD T1 --cwd "$P" 2>/dev/null); rc=$?
check "light-path task (branch null) -> skipped, rc 0" '[ $rc -eq 0 ] && grep -q "^skipped: task T1 has no branch" <<<"$out"' "$out"
: > "$STUBLOG"
out=$(OTP $SPECD T2 --cwd "$P" --record 2>"$WORK/err"); rc=$?
eq "gh: url printed" "$out" "https://github.com/o/r/pull/12"
eq "gh: rc 0" "$rc" 0
check "gh: create args" 'grep -q "^gh pr create --base spec/007-shop --head task/007-shop/T02-cart --title T2: cart total --body" "$STUBLOG"' "$(cat "$STUBLOG")"
check "gh: body names task file and mini-review" 'grep -q "tasks/T02-cart.md" "$STUBLOG" && grep -q "mini-review.yaml" "$STUBLOG"' "$(cat "$STUBLOG")"
check "pushed both branches to origin" 'git -C "$WORK/origin.git" show-ref --verify --quiet refs/heads/spec/007-shop && git -C "$WORK/origin.git" show-ref --verify --quiet refs/heads/task/007-shop/T02-cart'
eq "--record wrote pr" "$(yq --front-matter=extract '.tasks[1].pr' "$P/$SPECD/tasks.md")" "https://github.com/o/r/pull/12"
out=$(STUB_EXISTING="https://github.com/o/r/pull/9" OTP $SPECD T2 --cwd "$P" 2>/dev/null)
eq "gh: existing PR reused" "$out" "https://github.com/o/r/pull/9"
out=$(STUB_NOAUTH=1 OTP $SPECD T2 --cwd "$P" 2>/dev/null); rc=$?
check "gh not logged in -> skipped rc 0" '[ $rc -eq 0 ] && grep -q "^skipped: gh is not logged in" <<<"$out"' "$out"
out=$(env PATH="/usr/bin:/bin:$(dirname "$(command -v yq)")" bash "$S/open-task-pr.sh" $SPECD T2 --cwd "$P" 2>/dev/null)
eq "gh missing -> skipped" "$out" "skipped: gh not installed"
git -C "$P" remote set-url origin git@gitlab.com:o/r.git
: > "$STUBLOG"
out=$(OTP $SPECD T2 --cwd "$P" 2>/dev/null)
eq "glab: url printed" "$out" "https://gitlab.com/o/r/-/merge_requests/5"
check "glab: create args" 'grep -q "^glab mr create --target-branch spec/007-shop --source-branch task/007-shop/T02-cart" "$STUBLOG"' "$(cat "$STUBLOG")"
git -C "$P" remote set-url origin https://example.org/o/r.git
out=$(OTP $SPECD T2 --cwd "$P" 2>/dev/null)
check "unknown host -> skipped" 'grep -q "^skipped: origin host is neither GitHub nor GitLab" <<<"$out"' "$out"
git -C "$P" remote set-url origin https://github.com/o/r.git
mkdir -p "$P/.workflow"; printf '## Workflow settings\n\n```yaml\ntask_review: local\n```\n' > "$P/.workflow/rules.md"
out=$(OTP $SPECD T2 --cwd "$P" 2>/dev/null); eq "task_review local -> skipped" "$out" "skipped: task_review is local"
rm -f "$P/.workflow/rules.md"
out=$(OTP $SPECD T2 --cwd "$P" --dry-run 2>/dev/null)
check "dry run prints commands" 'grep -q "^gh pr create --base spec/007-shop" <<<"$out" && grep -q "^dry-run:" <<<"$out"' "$out"
t "bad task id -> 1"               1 OTP $SPECD X2 --cwd "$P"
t "unknown task -> 1"              1 OTP $SPECD T9 --cwd "$P"

echo "== run-toolchain.sh test scoping (D85)"
Q=$WORK/q
git_init_repo "$Q"
mkdir -p "$Q/.workflow/profiles" "$Q/.workflow/specs/002-q"
cat > "$Q/.workflow/profiles/sc.md" <<'P'
## Toolchain
```yaml
lint: "true"
test: "echo full; exit 1"
test_scoped: "echo \"excl=[$WF_EXCLUDE_TESTS] own=[$WF_TASK_TESTS] id=$WF_TASK_ID base=$WF_IMPL_BASE\"; cat \"$WF_EXCLUDE_TESTS_FILE\" > scoped-excl.txt; true"
```
P
cat > "$Q/.workflow/profiles/plain.md" <<'P'
## Toolchain
```yaml
test: "exit 1"
```
P
printf -- '---\nstatus: in-progress\nimpl_base_revision: abc123\n---\n' > "$Q/.workflow/specs/002-q/spec.md"
cat > "$Q/.workflow/specs/002-q/tasks.md" <<'EOF'
---
tasks:
  - {id: T1, status: done, work_type: sc, tests: [t/one.test.ts]}
  - {id: T2, status: in-progress, work_type: sc, tests: [t/two.test.ts]}
  - {id: T3, status: pending, work_type: sc, tests: ["t/three a.test.ts", t/three-b.test.ts]}
  - {id: T4, status: split-out, work_type: sc, tests: [t/four.test.ts]}
  - {id: T5, status: pending, work_type: plain}
---
EOF
git_commit_all "$Q" init
RT() { bash "$S/run-toolchain.sh" "$@"; }
EVQ=$Q/.workflow/specs/002-q/artifacts
out=$(RT --spec-dir .workflow/specs/002-q --task-id T2 --cwd "$Q" 2>/dev/null); rc=$?
eq "scoped: rc 0 (test_scoped used)" "$rc" 0
eq "scoped: result flags" "$(jq -c '.results[] | select(.key=="test") | [.status, .scoped, .excluded]' <<<"$out")" '["pass",true,3]'
check "scoped: env passed" 'grep -q "excl=\[t/three a.test.ts t/three-b.test.ts t/four.test.ts\] own=\[t/two.test.ts\] id=T2 base=abc123" "$EVQ/T2/toolchain.txt"' "$(cat "$EVQ/T2/toolchain.txt")"
eq "scoped: exclude file one per line" "$(wc -l < "$Q/scoped-excl.txt" | tr -d ' ')" 3
eq "scoped: own tests file" "$(cat "$EVQ/T2/task-tests.txt")" "t/two.test.ts"
out=$(RT --spec-dir .workflow/specs/002-q --task-id gate-3.9-w1 --work-type sc --exclude-unfinished --cwd "$Q" 2>/dev/null)
eq "gate: excludes all unfinished (T2,T3,T4)" "$(jq -c '.results[] | select(.key=="test") | .excluded' <<<"$out")" 4
out=$(RT --spec-dir .workflow/specs/002-q --task-id gate-final --work-type sc --cwd "$Q" 2>/dev/null); rc=$?
eq "gate without flag: full test runs, fails" "$rc" 1
eq "gate without flag: not scoped" "$(jq -c '.results[] | select(.key=="test") | has("scoped")' <<<"$out")" false
yq --front-matter=process -i '.tasks[] |= (.status = "done")' "$Q/.workflow/specs/002-q/tasks.md"
out=$(RT --spec-dir .workflow/specs/002-q --task-id T2 --cwd "$Q" 2>/dev/null); rc=$?
eq "nothing unfinished: full test runs (whole suite must pass)" "$rc" 1
yq --front-matter=process -i '.tasks[2].status = "pending"' "$Q/.workflow/specs/002-q/tasks.md"
out=$(RT --spec-dir .workflow/specs/002-q --task-id T5 --cwd "$Q" 2>"$WORK/err"); rc=$?
eq "no test_scoped + red unfinished tests: rc 0" "$rc" 0
eq "unscoped status" "$(jq -r '.results[] | select(.key=="test") | .status' <<<"$out")" unscoped
check "unscoped warning in json and stderr" 'jq -e ".warnings | length == 1" <<<"$out" >/dev/null && grep -q "test_scoped" "$WORK/err"' "$out"
out=$(RT --spec-dir .workflow/specs/002-q --task-id T3 --cwd "$Q" --skip test 2>/dev/null)
eq "--skip test still wins" "$(jq -r '.results[] | select(.key=="test") | .status' <<<"$out")" skipped

shellcheck_files "shellcheck: D85 scripts" "$S/task-waves.sh" "$S/rules-setting.sh" "$S/open-task-pr.sh" "$S/run-toolchain.sh"
finish
