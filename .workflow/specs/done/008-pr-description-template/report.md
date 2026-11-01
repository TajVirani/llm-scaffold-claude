# Report: PR description template

Spec: [spec.md](spec.md) · Verification plan: [verification-plan.md](verification-plan.md) · Baseline: `a36d149d8cf9b181f1aaf5c3917fb75b7b536534` · Head: `d8929b4` (code last changed at `2058ccd`)

## Summary

Sign-off now fills a ten-section PR template (`assets/pr-template.md`) into `pr-body.md` at 5.4, checks it with the new `check-pr-body.sh`, has the stakeholder approve the exact text at 5.5, and publishes it unchanged at 5.8 as the PR/MR description or the local merge message; a `pr_template` setting lets a project use its own host PR/MR template instead. The full harness passes (3166/3166, 58 suites), every target that can be measured passes, and this spec's own `pr-body.md` passes the check. The main gap: `gh pr create --body-file` has never run against a live `gh` (not installed here, and this spec merges locally).

## Capabilities

| Capability | Result | Evidence |
| --- | --- | --- |
| CAP-006 PR template for the Sign-off PR | PASS (5.4 fill and check; the 5.8 publish runs after approval) | [E2], [E3], [E4] |

## Tests and CI

| Suite | Command | Result | Evidence |
| --- | --- | --- | --- |
| Unit and integration (3.9, rework 1) | `tests/run-all.sh` | `TOTAL passed=3166 failed=0 skipped=0 xfail=0 (58 suites)`; exit 0 | [E1] |
| Unit and integration (5.4) | `run-toolchain.sh --task-id sign-off-5.4 --work-type test-harness --reuse` (lint, then `tests/run-all.sh`) | lint exit 0; `TOTAL passed=3166 failed=0 skipped=0 xfail=0 (58 suites)`; exit 0; a fresh run, not reused | [E2] |
| CI | none | not run: this repo has no CI; `tests/run-all.sh` by hand is the whole gate (`AGENTS.md`) | none |

Tool audit (3.5) per task:

| Task | Result | Output |
| --- | --- | --- |
| T1 | clean: lint pass, test pass; typecheck, format, boundary skipped (no command) | [artifacts/T1/](artifacts/T1/) |
| T2 | clean: lint pass, test pass; typecheck, format, boundary skipped (no command) | [artifacts/T2/](artifacts/T2/) |
| T3 | clean: lint pass, test pass; typecheck, format, boundary skipped (no command) | [artifacts/T3/](artifacts/T3/) |
| T4 | clean: lint pass, test pass; typecheck, format, boundary skipped (no command) | [artifacts/T4/](artifacts/T4/) |
| T5 | clean: lint pass, test pass; typecheck, format, boundary skipped (no command) | [artifacts/T5/](artifacts/T5/) |
| T6 | clean: lint pass, test pass; typecheck, format, boundary skipped (no command) | [artifacts/T6/](artifacts/T6/) |

## Targets vs measured

| Target | Threshold | Measured | Result | Command | Raw output |
| --- | --- | --- | --- | --- | --- |
| TGT-001 Script lint clean | exit 0; 0 shellcheck findings | 0 shellcheck findings, exit 0 | PASS | `script-lint` (verification-plan.md) | [E5] |
| TGT-002 Harness lint clean | exit 0; 0 shellcheck findings | 0 shellcheck findings, exit 0 | PASS | `harness-lint` | [E6] |
| TGT-003 Agent-docs lint clean | exit 0; each lint suite reports 0 failed | failed=0 in frontmatter, step-list, symlinks, upstream-lineage; exit 0 | PASS | `agent-docs-lint` | [E7] |
| TGT-004 `gh --template` beside a body flag under `.agents/` | `0` printed | 0 | PASS | `template-flag` | [E8] |
| TGT-005 Changed scripts no suite names | `0` printed | 0 | PASS | `script-coverage` | [E9] |
| TGT-006 New `.agents/` files missing from manifest or PROVENANCE | `0` printed | 0 | PASS | `asset-coverage` | [E10] |
| TGT-007 `check-pr-body.sh` wall time | real ≤ 1 s, best of 3 | 0.13 s | PASS | `check-time` | [E11] |
| TGT-008 Line coverage of changed shell code | not measured | not measured: no bash coverage tool, and the spec bans new dependencies (stakeholder decision, 1.1) | not measured | none | none |

## Journeys

| Journey | Result | Artifacts |
| --- | --- | --- |
| JRN-001 A well-filled body passes | PASS | `scripts/check-pr-body` 47/47 [E2] |
| JRN-002 Each bad shape is caught | PASS | `scripts/check-pr-body` 47/47 [E2] |
| JRN-003 Project mode checks the project's headings | PASS | `scripts/check-pr-body` 47/47 [E2] |
| JRN-004 The setting reads with its default | PASS | `scripts/task-breakdown` 132/132 [E2] |
| JRN-005 The PR and the local merge carry the approved body | PASS (recording stand-ins for `gh` and `glab`) | `scripts/sign-off-pr` 30/30 [E2] |
| JRN-006 Sign-off and setup text say the new steps | PASS | `scripts/sign-off-pr` 30/30 [E2] |
| JRN-007 This spec signs off with its own template | PASS at 5.4; the 5.8 re-check and local merge follow approval | [artifacts/sign-off-5.4/check-pr-body.txt](artifacts/sign-off-5.4/check-pr-body.txt) [E3] |

Behaviour verification: the suites run the real `check-pr-body.sh`, `rules-setting.sh` and the 5.8 publish block (extracted from `modules/sign-off.md`) against fixture repos. At this spec's own 5.4, `pr-body.md` was filled from the workflow template and `check-pr-body.sh` exited 0 on it with no output [E3]; `rules-setting.sh pr_template` printed `workflow` with the default note, since this repo sets no key and has no host template [E4].

## Review outcome

- Review cycles: 2, one pass each. Cycle 1 ended in a 4.5 loop back (F4, settled as D19 and D20); cycle 2 ended in rework 1 of 5. Findings F1-F9: 7 patched (F1, F2, F4, F5, F7, F8, F9), 2 routed to proposals and applied at 5.3 (F3 as P1, F6 as P2), 0 dismissed. Failed lenses: none. (See design-log.md triage entries.)
- Follow-up review recommended: no. Rework 1 patched no verified high finding, so its own gates were its check.

## Known gaps

- TGT-008 line coverage: not measured (no bash coverage tool; no new dependencies). TGT-005 and the 3.7 checklist stand in.
- `gh pr create --body-file` has not run against a live `gh`: `gh` is not installed here, JRN-005 uses recording stand-ins, and this spec's 5.8 takes the local merge route (origin is a local path). The flag is cited from the gh manual at 0.2.5. `glab mr create --help` lists `--description-file` and `--yes`.
- The 5.8 local merge leaves its message temp file in `$TMPDIR` when the switch or the merge fails (T4 3.8 note, left for triage, not filed).
- Content drift between the 5.5 approval and 5.8 is not detected: 5.8 reruns only the shape check (D17, by decision).
- Evidence-based filling is enforced by the template guidance and 5.4 only; `check-pr-body.sh` checks shape, not truth (review-end-state `not_verifiable`).
- No CI; typecheck, format and boundary have no command in the touched profiles, so ownership was checked by hand (review-standards `not_checked`). Cycle 2's end-state lens did not re-read cycle 1's pass files.
- No task PRs were opened: `open-task-pr.sh` skips when origin is neither GitHub nor GitLab.
- The impact classification's row "this repo's `.workflow/rules.md` documents the key" was not proposed at 5.2: a commented default line changes no agent behaviour. The key's documentation ships in the `project-setup` rules template.

## Deferred

- [.workflow/deferred/spec-issue-creation.md](../../../deferred/spec-issue-creation.md): create a tracker issue when a spec starts, so "Link to issue" has a target (scope decision, 0.3.17)
- [.workflow/deferred/workflow-settings-home.md](../../../deferred/workflow-settings-home.md): one central home for workflow settings (scope decision, 0.3.17)
- [.workflow/deferred/initiative-pr-template.md](../../../deferred/initiative-pr-template.md): a filled description for the initiative PR (scope decision, 0.3.17)
- Not this spec's file: [.workflow/deferred/comment-id-lint.md](../../../deferred/comment-id-lint.md) gained one line at T6, widening the shelved lint to asset-template guidance comments.

## How to verify

1. `tests/run-all.sh`: ends `TOTAL passed=3166 failed=0 skipped=0 xfail=0 (58 suites)`.
2. `tests/run-all.sh --suite scripts/check-pr-body`, `--suite scripts/sign-off-pr`, `--suite scripts/task-breakdown`: each `failed=0`.
3. `.agents/skills/feature-workflow/scripts/check-pr-body.sh .workflow/specs/done/008-pr-description-template/pr-body.md`: exit 0, no output.
4. `.agents/skills/feature-workflow/scripts/rules-setting.sh pr_template`: prints `workflow`, with a default note on stderr.
5. After 5.8: `git log -1 --format=%B main` shows the subject, a blank line, then `pr-body.md` verbatim.

## Evidence

- [E1] [artifacts/gate-3.9-rework1/](artifacts/gate-3.9-rework1/)
- [E2] [artifacts/sign-off-5.4/toolchain.txt](artifacts/sign-off-5.4/toolchain.txt), [toolchain.json](artifacts/sign-off-5.4/toolchain.json)
- [E3] [artifacts/sign-off-5.4/check-pr-body.txt](artifacts/sign-off-5.4/check-pr-body.txt)
- [E4] [artifacts/sign-off-5.4/rules-setting.txt](artifacts/sign-off-5.4/rules-setting.txt)
- [E5] [artifacts/review/pass-1/targets/script-lint-clean.txt](artifacts/review/pass-1/targets/script-lint-clean.txt)
- [E6] [artifacts/review/pass-1/targets/harness-lint-clean.txt](artifacts/review/pass-1/targets/harness-lint-clean.txt)
- [E7] [artifacts/review/pass-1/targets/agent-docs-lint-clean.txt](artifacts/review/pass-1/targets/agent-docs-lint-clean.txt)
- [E8] [artifacts/review/pass-1/targets/gh-template-passed-beside-a-body-flag-anywhere-under-agents.txt](artifacts/review/pass-1/targets/gh-template-passed-beside-a-body-flag-anywhere-under-agents.txt)
- [E9] [artifacts/review/pass-1/targets/scripts-added-or-changed-since-the-baseline-that-no-suite-names.txt](artifacts/review/pass-1/targets/scripts-added-or-changed-since-the-baseline-that-no-suite-names.txt)
- [E10] [artifacts/review/pass-1/targets/files-added-under-agents-since-the-baseline-missing-from-the-manifest-or-a-listed-directory-or-from-provenance-md.txt](artifacts/review/pass-1/targets/files-added-under-agents-since-the-baseline-missing-from-the-manifest-or-a-listed-directory-or-from-provenance-md.txt)
- [E11] [artifacts/review/pass-1/targets/wall-time-of-check-pr-body-sh-on-one-body.txt](artifacts/review/pass-1/targets/wall-time-of-check-pr-body-sh-on-one-body.txt)
