# Proposals: Review lessons: a Phase 4 lens for retrospective lessons

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/profiles/test-harness.md` § Toolchain | replace: `lint: "git ls-files -z -- 'tests/*.sh' \| xargs -0 shellcheck -x -P SCRIPTDIR"` -> `lint: "git ls-files -z -co --exclude-standard -- 'tests/*.sh' \| xargs -0 shellcheck -x -P SCRIPTDIR"` | Without it, a suite file an implementation agent has written but not yet committed is skipped by the toolchain's lint; the agent's run passes, the commit leaves the tree hash unchanged, and the stop audit reuses that run, so the new file is never shellchecked by the toolchain (only by the suite's own `shellcheck_files` assertion and the 4.3 target after the commit). | discovered work `lint-skips-untracked-tests` at 1.2, dismissed 00.25 No (design-log 2026-10-22) | proposed | |
| P2 | `.workflow/profiles/shell-scripts.md` § Toolchain | replace: `lint: "git ls-files -z -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' \| xargs -0 shellcheck -x -P SCRIPTDIR"` -> the same with `git ls-files -z -co --exclude-standard -- ...` | The same gap for a new script under `.agents/`: a toolchain run before the first commit lints only tracked files. | same as P1 | proposed | |
| P3 | `.workflow/profiles/agent-docs.md` § Toolchain | replace: `lint: "tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/step-list && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage"` -> `lint: "tests/run-all.sh --suite lint/frontmatter && tests/run-all.sh --suite lint/symlinks && tests/run-all.sh --suite lint/upstream-lineage"` (the `test` key, scoped through `test_scoped`, already runs `lint/step-list` and excludes it while it is another task's red Phase 1 pin) | Without it, an agent-docs task in the same wave as a task that changes the step list cannot pass 3.5 or the stop audit until that task merges: the lint key runs `lint/step-list` with no scoping, and the `&&` chain also stops the later lint suites from running (T3 of this spec, stopped `profile-wrong` at 3.3). An alternative with the same effect is `run-toolchain.sh` applying the exclusion list to lint suites. | T3 `profile-wrong` at 3.3 (design-log 2026-10-22, Implementation wave 1) | proposed | |
