# 1.4 Known-bad runs: 009-slim-workflow-context

Scratch worktree `.workflow/.worktrees/s009_known_bad`, detached at 1a059ce (spec branch after the 1.2 merge), removed afterwards. No browser suite: this repo has no `e2e-browser` work type, so 1.3 built nothing and step 2 (injected API fault) does not apply.

## 1. Baseline (the feature does not exist yet)

- Command: `tests/run-all.sh -v` (the `test` key of `.workflow/profiles/test-harness.md`). Output: [harness.txt](harness.txt).
- Exit code: 1. `TOTAL passed=4347 failed=49 skipped=0 xfail=0 (75 suites)`.
- Failed suites are exactly the six new or rewritten ones; the other 69 pass. Every failure is a `FAIL` assertion line and every suite reaches its summary row; no `unbound variable`, `command not found` or syntax error. (One `find: … No such file or directory` on stderr at harness.txt:1188 comes from the existing `scripts/generate-boundary-config` suite, which passes.)

| Journey | Suite | Failed | First failing assertion |
| --- | --- | --- | --- |
| JRN-005 | `scripts/term-list` | 13 | the stub prints nothing: line, alias and `--define` checks fail; "--define of an unknown term exits non-zero" |
| JRN-009 | `lint/affected-area` | 1 | "discovery 0.2.1 holds a fenced bash command" |
| JRN-006 | `lint/shared-rule-homes` | 3 | "host launch rows: fork_turns: in exactly one file"; "leave the small path: only in modules/questioning-loop.md"; "modules/small-path.md no longer exists" |
| JRN-007 | `lint/small-path-docs` | 25 | SKILL.md still has `modules` and `progressive_loading`; no "On the small path:" notes; small-path.md still exists |
| JRN-003 | `lint/step-routing` | 3 | "every 0.x id is held by exactly one step file" (small-path.md also holds 0.1.4, 0.2.4, 0.2.5, 0.3.3, 0.3.22, 0.3.8–0.3.19); 5.4, 5.5, 5.7; 0.3.20 has 2 holders |
| JRN-001, JRN-002 | `lint/workflow-load-size` | 4 | "new-feature start: every counted file exists" (conventions.md missing); "new-feature start is at most 45000 bytes" (59713 counted of the files that exist); "implementation resume: every counted file exists"; "the term list prints the glossary's terms" |
| JRN-010 | `tests/run-all.sh` | exit 1 | the six suites above |

Passing assertions inside these suites are the checks the split must keep true (rule markers already in one file, 1.x–4.x step ids, JRN-008's padded-fixture checks of the measuring function, `lint/frontmatter`).

## 2. Targeted fault for the suite that is green on the baseline

`lint/md-links` (JRN-004) passes on the baseline because no link under `.agents/` is broken today, and its fixture half already proves it fails on a missing heading and a missing file. To prove the `.agents/` half can go red:

- Fault: appended a link to `../SKILL.md#no-such-heading` and one to `modules/no-such-file.md` to `.agents/skills/feature-workflow/modules/sign-off.md` in the scratch worktree.
- Command: `tests/run-all.sh -v --suite lint/md-links`. Output: [md-links-fault.txt](md-links-fault.txt).
- Exit code: 1. "every relative link and anchor in the markdown under .agents/ resolves" fails naming both links (`sign-off.md:259`).

## 3. Mutation testing

Skipped: StrykerJS does not apply to a bash and markdown change and is not installed. The change modifies existing behaviour only by moving text, which the new suites pin directly.
