---
cache_stamps:
  modules: 58019c8c55ed4443f78f085b13abdfb5d96c28ea
  flows: 58019c8c55ed4443f78f085b13abdfb5d96c28ea
  architecture: 58019c8c55ed4443f78f085b13abdfb5d96c28ea
---

# Codebase map: The single writers keep the validator's diagnostic

Affected area: module `feature-workflow` (owns `.agents/skills/feature-workflow/**`): `scripts/status-transition.sh`, `scripts/initiative-transition.sh`; their suites in module `tests`: `tests/scripts/status-transition-tasks.sh`, `tests/scripts/status-transition-specs.sh`, `tests/scripts/initiative-transition.sh`.

## Relevant code

| Item | What it does today | Source |
| --- | --- | --- |
| set-task record lookup and field edits | One record by id; status table, work_type once, capability only at 5.3, pr http(s) or null | `.agents/skills/feature-workflow/scripts/status-transition.sh:240-314` |
| set-task write and validate | `mktemp` copy, yq process edit on the copy, validator with `-e`, stdout and stderr to `/dev/null`, `mv` only on pass | `status-transition.sh:315-322` |
| set-task refusal | Exits 1 via default `die`; message names `$TASKS` and `assets/tasks.md`; temp copy removed | `status-transition.sh:318-321`; `die` at `:92` |
| Step marker | Written only after the move, only with `--step` | `status-transition.sh:323-327` |
| TASKS_VALIDATOR | One boolean over all `.tasks[]`; text equal to the template's (suite asserts) | `status-transition.sh:146-165`; `assets/tasks.md:53-72` |
| write_validated | Copy to `mktemp`, apply EXPR (failure: exit 1 `cannot update`), validate with `-e` and both streams to `/dev/null`, move on pass | `.agents/skills/feature-workflow/scripts/initiative-transition.sh:158-168` |
| write_validated refusal | Exits 2 `refusing to write $file: the result fails the validator of its template in feature-workflow/assets` | `initiative-transition.sh:163-165` |
| write_validated callers | set-pr (`:242`, `:249`), set-question (`:295`, QUESTIONS_VALIDATOR), set-slice (`:346`), status (`:377`) | `initiative-transition.sh` |
| Validators | INITIATIVE_VALIDATOR, QUESTIONS_VALIDATOR, copies of the template validators | `initiative-transition.sh:119-155` |
| Documented exits | status-transition: exit 1 includes "schema failure"; initiative-transition: exit 2 includes "a result the template validator rejects" | `status-transition.sh:78`; `initiative-transition.sh:50-51` |
| Set-task validator tests | Invalid tasks.md refused with exit 1, sha unchanged; bad-field list exit 1; no temp files left; validator text equality | `tests/scripts/status-transition-tasks.sh:99-126, 191-216` |
| Initiative validator test | Refusal exit 2, cksum unchanged; `refused` helper checks exit 2 and non-empty stderr | `tests/scripts/initiative-transition.sh:96-101`; `tests/fixtures/initiative.sh:178-184` |
| yq failure shim | A PATH `yq` that fails only for one expression, then execs the real yq | `tests/scripts/initiative-transition.sh:107-115` |
| Test runner | `t` compares exit code only | `tests/lib/common.sh:51-57` |

No suite asserts the text of either refusal message.

## Seams and interfaces

| Interface | Shape (signature, type, contract) | Callers | Source |
| --- | --- | --- | --- |
| `status-transition.sh set-task <spec-dir> <T<n>> [...]` | Exit 0 written; 1 usage, environment or validator refusal; 2 illegal transition | implementation-orchestrator, review-triage, discovered-work modules; `open-task-pr.sh:190`; SKILL.md | `status-transition.sh:7`, `:240-330` |
| `initiative-transition.sh status \| step \| set-slice \| set-question \| set-pr` | Exit 0; 1 usage or environment; 2 illegal or validator refusal | large-path module; `open-task-pr.sh:187` | `initiative-transition.sh:9-19`, `:50-52` |
| `write_validated FILE VALIDATOR EXPR` | Copy replaces FILE only when VALIDATOR is true | five callers above | `initiative-transition.sh:158-168` |

## Prior decisions

| Decision or item | What it says | Source |
| --- | --- | --- |
| Rules, Ownership | `feature-workflow` owns `.agents/skills/feature-workflow/**`; `tests` owns `tests/**`; these scripts are not shared core | `.workflow/rules.md` § Ownership, § Shared core |
| Rules, Cross-cutting | Bash; `# File:` header is the interface doc; body comments give reasons | `.workflow/rules.md` § Cross-cutting policy |
| Rules, Required versions | bash 3.2; mikefarah yq v4 only | `.workflow/rules.md` § Required versions |
| shell-scripts profile | Never swallow an error; an exit-code change updates `# Exit:` and its test together | `.workflow/profiles/shell-scripts.md:23-24` (cited by library-evaluation) |
| Capabilities | No row covers the single writers or their validators | `.workflow/capabilities.md` |

## Library options

### Capture of validator stderr

Verdict: Use existing yq; build the capture in the two scripts. Recommended shape (from the return): run the validator without `-e`, capture stdout, send stderr to a temp file; a non-zero exit or stderr text is a validator error reported with yq's text; stdout `true` writes; `false` refuses as today; anything else is an error. The validator text is unchanged.

| Option | Fit | Licence | Maintenance | Security | Cost |
| --- | --- | --- | --- | --- | --- |
| yq v4, keep `-e`, match stderr text "no matches found" | caution: depends on yq/cobra wording | pass: MIT | pass: v4.54.1 | unknown | pass |
| yq v4, drop `-e`, read printed `true`/`false` and exit code | pass | pass: MIT | pass | unknown | pass |
| Do nothing | fail: hides yq errors (shell-scripts profile) | - | - | - | - |
| Python yq or another YAML tool | reject: banned by rules | - | - | - | - |

Evidence:
- official: https://mikefarah.gitbook.io/yq/llms-full.txt (`-e`: exit status when no matches, null or false)
- registry: https://api.deps.dev/v3/systems/go/packages/github.com%2Fmikefarah%2Fyq%2Fv4; https://api.deps.dev/v3/projects/github.com%2Fmikefarah%2Fyq
- repository: https://github.com/mikefarah/yq; https://github.com/mikefarah/yq/releases; `pkg/yqlib/printer.go`, `cmd/evaluate_sequence_command.go`, `yq.go`, `cmd/root.go` on master
- upstream: https://raw.githubusercontent.com/spf13/cobra/main/command.go

Risks: matching stderr text breaks when yq or cobra wording changes; the no-`-e` shape assumes `false` on stdout (verified below).

## Not found

- Shelf match: none of the 21 `.workflow/deferred/` files. Reported by retrieval.
- Cache wording: `.workflow/cache/flows.md` says write_validated validates "the updated initiative.md"; it validates any file it is given (questions.md too). Content imprecision, not a stale stamp. Reported by retrieval.
- Main-session probes, mikefarah yq v4.54.1: with `-e`, a false result prints `false`, rc 1 and stderr `Error: no matches found`; a runtime error prints nothing, rc 1, stderr `Error: <diagnostic>`. Without `-e`, false prints `false` with rc 0 and no stderr; true prints `true` rc 0; a runtime error rc 1 with the diagnostic.
