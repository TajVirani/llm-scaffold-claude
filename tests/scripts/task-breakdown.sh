#!/usr/bin/env bash
# Suite: task-breakdown helpers (feature-workflow/scripts): task-waves.sh (predicted-file overlap, implied edges, parallel_with,
#   cycles, waves, JSON), rules-setting.sh (## Workflow settings, task_review, main_branch, read from the checkout an agent worktree sits
#   in; task_review read as local with its reason when origin is on no PR host), open-task-pr.sh (gh / glab stubs on PATH, skip paths,
#   --record; never the network) and run-toolchain.sh test scoping (other unfinished tasks' Phase 1 tests excluded, test_scoped,
#   --exclude-unfinished, unscoped warning). JRN-006: each spec folder form for task-waves.sh and open-task-pr.sh task mode,
#   and each initiative folder form for open-task-pr.sh --record, gives the exit code and message it gave before the shared
#   normaliser, except that open-task-pr now refuses an absolute path outside the specs or initiatives root.
#   JRN-004 (spec 008): rules-setting.sh pr_template, against a fixture git repo holding .github/pull_request_template.md,
#   reads workflow without a Workflow settings block or the key (with a default note on stderr), reads workflow, prints the
#   host template path back, refuses a missing file, an absolute, `..`, leading-dash or non-.md path, `project` and `other`
#   with exit 1 naming the value, refuses a path value when --cwd is outside git, and reads workflow from the project-setup
#   rules.md template.
# shellcheck disable=SC2016  # check expressions are single-quoted and eval'd on purpose
# shellcheck source=../lib/common.sh
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"
# shellcheck source=../fixtures/workflow-folders.sh
source "$TESTS_DIR/fixtures/workflow-folders.sh"
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
eq "main_branch default main (no git)" "$(RS main_branch --rules "$WORK/nope.md" 2>/dev/null)" main
printf '## Workflow settings\n\n```yaml\nmain_branch: release/2.x\n```\n' > "$WORK/r.md"
eq "main_branch read" "$(RS main_branch --rules "$WORK/r.md")" release/2.x
printf '## Workflow settings\n\n```yaml\nmain_branch: "-x"\n```\n' > "$WORK/r.md"
t "main_branch invalid -> 1"       1 RS main_branch --rules "$WORK/r.md"
printf '## Workflow settings\n\n```yaml\nmain_branch: "@branch"\n```\n' > "$WORK/r.md"
t "main_branch @branch (the spec token, not a branch name) -> 1" 1 RS main_branch --rules "$WORK/r.md"
MB=$WORK/mb; git_init_repo "$MB"; git_commit_all "$MB" init
eq "main_branch default main without origin/HEAD" "$(RS main_branch --cwd "$MB" 2>/dev/null)" main
git -C "$MB" update-ref refs/remotes/origin/develop HEAD; git -C "$MB" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/develop
eq "main_branch default from origin/HEAD" "$(RS main_branch --cwd "$MB" 2>/dev/null)" develop
mkdir -p "$WORK/p/.workflow"; printf '## Workflow settings\n\n```yaml\nmain_branch: release/9\n```\n' > "$WORK/p/.workflow/rules.md"
git -C "$WORK/p" worktree add -q "$WORK/p/.workflow/.worktrees/s001_t1" -b task/001-demo/T01-x 2>/dev/null
eq "rules of the checkout an agent worktree sits in, from the agent worktree" "$(RS main_branch --cwd "$WORK/p/.workflow/.worktrees/s001_t1")" release/9
eq "a separate worktree reads its own rules (none here: the default)" "$(RS main_branch --cwd "$WORK/p-wt" 2>/dev/null)" main
echo "== rules-setting.sh task_review and the PR host"
TR=$WORK/tr; git_init_repo "$TR"; git_commit_all "$TR" init
printf '## Workflow settings\n\n```yaml\ntask_review: pr-blocking\n```\n' > "$WORK/trr.md"
eq "no origin: pr reads local" "$(RS task_review --cwd "$TR" 2>/dev/null)" local
eq "no origin: the note says why" "$(RS task_review --cwd "$TR" 2>&1 >/dev/null | tail -n 1)" "rules-setting.sh: task_review is pr, read as local: there is no origin remote"
git -C "$TR" remote add origin "$WORK/elsewhere.git"
eq "a local-path origin: pr reads local" "$(RS task_review --cwd "$TR" 2>/dev/null)" local
eq "a local-path origin: the note names it" "$(RS task_review --cwd "$TR" 2>&1 >/dev/null | tail -n 1)" \
  "rules-setting.sh: task_review is pr, read as local: the origin remote $WORK/elsewhere.git is neither on GitHub nor on GitLab"
git -C "$TR" remote set-url origin https://github.com/o/r.git
eq "a GitHub origin: pr stays pr" "$(RS task_review --cwd "$TR" 2>/dev/null)" pr
git -C "$TR" remote set-url origin git@gitlab.com:o/r.git
mkdir -p "$TR/.workflow" && cp "$WORK/trr.md" "$TR/.workflow/rules.md"
eq "a GitLab origin: pr-blocking stays pr-blocking" "$(RS task_review --cwd "$TR")" pr-blocking
git -C "$TR" remote remove origin
eq "no origin: pr-blocking reads local" "$(RS task_review --cwd "$TR" 2>/dev/null)" local
eq "--rules reads the file as written, with no host check" "$(RS task_review --rules "$WORK/trr.md" --cwd "$TR")" pr-blocking

echo "== rules-setting.sh pr_template (JRN-004, spec 008)"
# The host template repo also holds files at ../t.md, -t.md and .github/t.txt, so those values are refused for their
# shape, not because the file is missing.
PTR=$WORK/pt-repo
git_init_repo "$PTR"
mkdir -p "$PTR/.github"
printf '## Summary\n\n## Testing\n' > "$PTR/.github/pull_request_template.md"
printf 'not markdown\n' > "$PTR/.github/t.txt"
printf '## Summary\n' > "$PTR/-t.md"
printf '## Summary\n' > "$WORK/t.md"
git_commit_all "$PTR" "host PR template"
PT_OUTSIDE_GIT=$WORK/pt-outside-git
mkdir -p "$PT_OUTSIDE_GIT"
# pt_rules VALUE : write $WORK/pt.md with pr_template set to VALUE under ## Workflow settings.
pt_rules() { printf '## Workflow settings\n\n```yaml\npr_template: "%s"\n```\n' "$1" > "$WORK/pt.md"; }
# pt_refused NAME VALUE : pr_template set to VALUE, read against the host template repo, exits 1 naming VALUE.
pt_refused() {
  local out rc
  pt_rules "$2"
  out=$(RS pr_template --cwd "$PTR" --rules "$WORK/pt.md" 2>&1)
  rc=$?
  eq "$1" "$rc:$(grep -qF -- "$2" <<<"$out" && echo named)" "1:named"
}
printf '## Ownership\n\n```yaml\nmodules: {}\n```\n' > "$WORK/pt.md"
eq "JRN-004 pr_template without a Workflow settings block -> workflow" "$(RS pr_template --cwd "$PTR" --rules "$WORK/pt.md" 2>/dev/null)" workflow
pt_note=$({ RS pr_template --cwd "$PTR" --rules "$WORK/pt.md" >/dev/null; } 2>&1)
eq "JRN-004 pr_template without a Workflow settings block notes the default" "$(grep -q default <<<"$pt_note" && echo noted)" noted
printf '## Workflow settings\n\n```yaml\ntask_review: local\n```\n' > "$WORK/pt.md"
eq "JRN-004 pr_template key absent -> workflow" "$(RS pr_template --cwd "$PTR" --rules "$WORK/pt.md" 2>/dev/null)" workflow
pt_note=$({ RS pr_template --cwd "$PTR" --rules "$WORK/pt.md" >/dev/null; } 2>&1)
eq "JRN-004 pr_template key absent notes the default" "$(grep -q default <<<"$pt_note" && echo noted)" noted
pt_rules workflow
eq "JRN-004 pr_template workflow read" "$(RS pr_template --cwd "$PTR" --rules "$WORK/pt.md")" workflow
pt_rules .github/pull_request_template.md
eq "JRN-004 pr_template host template path printed back" "$(RS pr_template --cwd "$PTR" --rules "$WORK/pt.md")" .github/pull_request_template.md
pt_refused "JRN-004 pr_template .github/missing.md (no such file) -> 1 naming it" .github/missing.md
pt_refused "JRN-004 pr_template /abs/t.md (absolute) -> 1 naming it" /abs/t.md
pt_refused "JRN-004 pr_template ../t.md (leaves the repo) -> 1 naming it" ../t.md
pt_refused "JRN-004 pr_template -t.md (leading dash) -> 1 naming it" -t.md
pt_refused "JRN-004 pr_template .github/t.txt (not .md) -> 1 naming it" .github/t.txt
pt_refused "JRN-004 pr_template project -> 1 naming it" project
pt_refused "JRN-004 pr_template other -> 1 naming it" other
pt_refused "JRN-004 pr_template @template_path (the spec token, not a path) -> 1 naming it" @template_path
pt_rules .github/pull_request_template.md
pt_out=$(GIT_CEILING_DIRECTORIES=$WORK RS pr_template --cwd "$PT_OUTSIDE_GIT" --rules "$WORK/pt.md" 2>&1)
pt_rc=$?
eq "JRN-004 pr_template path with --cwd outside git -> 1 saying so" "$pt_rc:$(grep -qi git <<<"$pt_out" && echo said)" "1:said"
eq "JRN-004 the project-setup rules.md template reads pr_template workflow" "$(RS pr_template --rules "$RULES_T" 2>/dev/null)" workflow
# generate-boundary-config ignores the section (reads Ownership and Shared core only)
GB=$WORK/gb; mkdir -p "$GB/.workflow"; cp "$RULES_T" "$GB/.workflow/rules.md"
printf '\n## Workflow settings\n\n```yaml\ntask_review: pr-blocking\n```\n' >> "$GB/.workflow/rules.md"
gb_out=$(bash "$WORK/scaffold/.agents/skills/project-setup/scripts/generate-boundary-config.sh" --print-intermediate "$GB" 2>&1)
# shellcheck disable=SC2034  # gb_rc is read inside the eval-ed check string below
gb_rc=$?
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
  "pr list") [ -z "\${STUB_EXISTING:-}" ] || echo "\$STUB_EXISTING" ;;
  "mr list") if [ -n "\${STUB_EXISTING:-}" ]; then echo "[{\\"web_url\\": \\"\$STUB_EXISTING\\"}]"; else echo "[]"; fi ;;
  "pr create") echo "Creating pull request..."; echo "https://github.com/o/r/pull/12" ;;
  "mr create")
    if [ -n "\${STUB_MR_ERROR:-}" ]; then echo "POST https://gitlab.com/api/v4/projects/o%2Fr/merge_requests: \$STUB_MR_ERROR" >&2; exit 1; fi
    echo "Creating merge request"; echo "!5 T2: cart total (task/007-shop/T02-cart)"; echo " https://gitlab.com/o/r/-/merge_requests/5" ;;
  "mr view") echo "{\\"web_url\\": \\"https://gitlab.com/o/r/-/merge_requests/\$3\\"}" ;;
esac
EOF
  chmod +x "$P/bin/$cli"
done
OTP() { env PATH="$P/bin:$PATH" bash "$S/open-task-pr.sh" "$@"; }
SPECD=.workflow/specs/007-shop
out=$(OTP $SPECD T2 --cwd "$P" 2>/dev/null); eq "no origin -> task_review reads local, skipped with the reason" "$out" "skipped: task_review is pr, read as local: there is no origin remote"
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
out=$(STUB_EXISTING="https://gitlab.com/o/r/-/merge_requests/9" OTP $SPECD T2 --cwd "$P" 2>/dev/null)
eq "glab: existing MR reused from the JSON list" "$out" "https://gitlab.com/o/r/-/merge_requests/9"
out=$(STUB_MR_ERROR="409 {message: [Another open merge request already exists for this source branch: !7]}" OTP $SPECD T2 --cwd "$P" 2>/dev/null)
eq "glab: 409 reuses the MR it names" "$out" "https://gitlab.com/o/r/-/merge_requests/7"
out=$(STUB_MR_ERROR="500 Internal Server Error" OTP $SPECD T2 --cwd "$P" 2>/dev/null)
eq "glab: an error quoting an API URL is skipped, not recorded" "$out" "skipped: glab did not return a PR/MR URL"
git -C "$P" remote set-url origin https://example.org/o/r.git
out=$(OTP $SPECD T2 --cwd "$P" 2>/dev/null)
eq "unknown host -> task_review reads local, skipped with the reason" "$out" "skipped: task_review is pr, read as local: the origin remote https://example.org/o/r.git is neither on GitHub nor on GitLab"
git -C "$P" remote set-url origin https://github.com/o/r.git
mkdir -p "$P/.workflow"; printf '## Workflow settings\n\n```yaml\ntask_review: local\n```\n' > "$P/.workflow/rules.md"
out=$(OTP $SPECD T2 --cwd "$P" 2>/dev/null); eq "task_review local -> skipped" "$out" "skipped: task_review is local"
rm -f "$P/.workflow/rules.md"
out=$(OTP $SPECD T2 --cwd "$P" --dry-run 2>/dev/null)
check "dry run prints commands" 'grep -q "^gh pr create --base spec/007-shop" <<<"$out" && grep -q "^dry-run:" <<<"$out"' "$out"
t "bad task id -> 1"               1 OTP $SPECD X2 --cwd "$P"
t "unknown task -> 1"              1 OTP $SPECD T9 --cwd "$P"
out=$(OTP --help 2>/dev/null); rc=$?
check "--help prints the task-mode usage on stdout, rc 0" \
  '[ $rc -eq 0 ] && [ "$out" = "usage: open-task-pr.sh <spec-dir> <task-id> [--cwd <dir>] [--record] [--dry-run]" ]' "rc=$rc $out"

echo "== run-toolchain.sh test scoping"
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
eq "nothing unfinished, own tests listed: test_scoped runs, rc 0" "$rc" 0
eq "nothing unfinished, own tests listed: scoped flags" "$(jq -c '.results[] | select(.key=="test") | [.scoped, .own, .excluded]' <<<"$out")" '[true,1,0]'
yq --front-matter=process -i '.tasks[2].status = "pending"' "$Q/.workflow/specs/002-q/tasks.md"
out=$(RT --spec-dir .workflow/specs/002-q --task-id T5 --cwd "$Q" 2>"$WORK/err"); rc=$?
eq "no test_scoped + red unfinished tests: rc 0" "$rc" 0
eq "unscoped status" "$(jq -r '.results[] | select(.key=="test") | .status' <<<"$out")" unscoped
check "unscoped warning in json and stderr" 'jq -e ".warnings | length == 1" <<<"$out" >/dev/null && grep -q "test_scoped" "$WORK/err"' "$out"
out=$(RT --spec-dir .workflow/specs/002-q --task-id T3 --cwd "$Q" --skip test 2>/dev/null)
eq "--skip test still wins" "$(jq -r '.results[] | select(.key=="test") | .status' <<<"$out")" skipped

echo "== JRN-006 spec and initiative folder forms"
folder_fixture_repo "$WORK/folders"
SPEC_REASON="spec dir must be .workflow/specs/NNN-slug"
# The fixture has no origin, so task_review reads local and an accepted folder reaches that skip, the first after the folder is read.
TASK_MODE_ACCEPTED="0|open-task-pr.sh: skipped: task_review is pr, read as local: there is no origin remote"
RECORD_ACCEPTED="0|open-task-pr.sh: skipped: no origin remote"
while IFS='|' read -r form cwd arg; do
  eq "JRN-006 task-waves takes the $form spec folder as before" \
    "$(folder_outcome TW --spec-dir "$arg" --cwd "$cwd")" \
    "$(folder_expected "$form" "$cwd" "$arg" task-waves.sh 1 "$SPEC_REASON" "0|")"
  eq "JRN-006 open-task-pr task mode takes the $form spec folder as before, an absolute path elsewhere now refused" \
    "$(folder_outcome bash "$S/open-task-pr.sh" "$arg" T1 --cwd "$cwd" --dry-run)" \
    "$(folder_expected "$form" "$cwd" "$arg" open-task-pr.sh 1 "$SPEC_REASON" "$TASK_MODE_ACCEPTED")"
done < <(folder_inputs spec)
while IFS='|' read -r form cwd arg; do
  eq "JRN-006 open-task-pr --record takes the $form initiative folder as before, an absolute path elsewhere now refused" \
    "$(folder_outcome bash "$S/open-task-pr.sh" --head spec/001-alpha --base main --title x --record "$arg" --cwd "$cwd" --dry-run)" \
    "$(folder_expected "$form" "$cwd" "$arg" open-task-pr.sh 2 "--record must be .workflow/initiatives/NNN-slug" "$RECORD_ACCEPTED")"
done < <(folder_inputs initiative)

shellcheck_files "shellcheck: task-breakdown scripts" "$S/task-waves.sh" "$S/rules-setting.sh" "$S/open-task-pr.sh" "$S/run-toolchain.sh"
finish
