# Proposals: Review lessons: a Phase 4 lens for retrospective lessons

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/profiles/test-harness.md` § Toolchain | replace: `lint: "git ls-files -z -- 'tests/*.sh' \| xargs -0 shellcheck -x -P SCRIPTDIR"` -> `lint: "git ls-files -z -co --exclude-standard -- 'tests/*.sh' \| xargs -0 shellcheck -x -P SCRIPTDIR"` | Without it, a suite file an implementation agent has written but not yet committed is skipped by the toolchain's lint; the agent's run passes, the commit leaves the tree hash unchanged, and the stop audit reuses that run, so the new file is never shellchecked by the toolchain (only by the suite's own `shellcheck_files` assertion and the 4.3 target after the commit). | discovered work `lint-skips-untracked-tests` at 1.2, dismissed 00.25 No (design-log 2026-10-22) | proposed | |
| P2 | `.workflow/profiles/shell-scripts.md` § Toolchain | replace: `lint: "git ls-files -z -- '.agents/hooks/*.sh' '.agents/lib/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' \| xargs -0 shellcheck -x -P SCRIPTDIR"` -> the same with `git ls-files -z -co --exclude-standard -- ...` | The same gap for a new script under `.agents/`: a toolchain run before the first commit lints only tracked files. | same as P1 | proposed | |
