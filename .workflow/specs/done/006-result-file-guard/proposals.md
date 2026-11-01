# Proposals: Sub-agents can write their own result file

Spec: [spec.md](spec.md) · Report: [report.md](report.md)

Status values: `proposed` · `approved` · `modified` · `rejected`

## Capabilities

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P2 | `.workflow/capabilities.md` | CAP-007 \| Sub-agents file their own result file: implementation (Phase 1 and Phase 3), integration and profile-mini-review agents write it to `<main checkout>/<spec_dir>/artifacts/<id>/`; Phase 1 and integration run in orchestrator-made agent worktrees with no isolation, confined and stop-audited by name; an artifacts gate refuses any merge that changes `artifacts/`; `install.sh` resolves a differing hook matcher per group on upgrade \| [.workflow/specs/done/006-result-file-guard](specs/done/006-result-file-guard/spec.md) | Without it, 0.3.1 would not find this capability when a later request touches result files, agent worktrees or installer matchers, and could plan a duplicate. | spec.md § Capabilities | approved | |
| P3 | `.workflow/capabilities.md` | CAP-008 \| Read-only commands pass the worktree guard: a confined agent may run allowlisted reads (cat, head, tail, grep, rg, ls, wc, print-only `sed -n`, find, git log/show/diff/status, yq, jq) joined by `\|` or `&&` from the main checkout without the leading `cd`; writing flags and shell forms still need it \| [.workflow/specs/done/006-result-file-guard](specs/done/006-result-file-guard/spec.md) | Without it, 0.3.1 would not find the read allowlist when a later request widens or narrows what the guard allows. | spec.md § Capabilities | approved | |

## Decisions

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P4 | `.workflow/GLOSSARY.md` | **Artifacts gate**: the check `check-merge-artifacts.sh` runs before every merge into the spec branch (1.2, 1.3, 3.2, 3.16, the light-path fast-forward); it refuses a branch or commit that adds, changes or deletes anything under `<spec_dir>/artifacts/` since its merge-base with the spec branch. _Avoid_: merge gate (too broad), artifacts check | Without one term, agents and docs name it three ways ("merge gate", "artifacts check", "the gate"), and a reader cannot tell it from the 3.x quality gates. | T2, T5; spec.md § Capabilities | approved | |

## Pitfalls

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P5 | `.workflow/decisions/pitfalls.md` | ## Fill a brief's path placeholders with what the launch really gives the agent. What happened: `tests/hooks/worktree-guard.sh` filled every `worktree`, `checkout` and `launched` placeholder in the extracted result-file command with the agent worktree, so the integration and Phase 1 briefs passed while their "checkout you were launched in" meant the main checkout under the new no-isolation launch; review pass 1 caught it (F1, high). Where: `tests/hooks/worktree-guard.sh` placeholder filler; `.agents/agents/*.md` command templates. Spec: .workflow/specs/done/006-result-file-guard. Prevented by: the guard suite fills a `launched` placeholder with the main checkout and checks the filled command starts with `cd <agent worktree> &&`. | Without it, a test that extracts a command from a doc can again substitute the expected value and hide a wrong doc. | F1 (review pass 1), rework 1 | approved | |

## Profiles

| Id | Target | Proposed text | Why removing it would change agent behaviour | Origin | Status | Decision |
| --- | --- | --- | --- | --- | --- | --- |
| P1 | `.workflow/profiles/shell-scripts.md` § Mini-review checklist | replace: Every error path reaches `die()` or the guard's deny output; nothing is silently swallowed. -> Every error path reaches `die()` or the guard's deny output; nothing is silently swallowed, except a silent exit the hook's header documents as intended (for example a stop the audit does not cover). | Without the exception a reviewer fails a documented silent exit (the integration stop with no transcript, ruled in design-log "Discovered work: codex-integration-missing-transcript") on every review. | T1 mini-review r2 out_of_scope_noticed (`artifacts/T1/mini-review-r2.yaml`), step 3.7 | approved | |
