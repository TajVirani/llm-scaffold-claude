---
origin_spec: .workflow/specs/done/005-cache-build-followups
created: 2026-10-28
---

# Main-checkout resolver

**Summary:** Every script, hook and agent doc finds the main checkout through the shared `wf_main_root` helper instead of its own copy.
**Mode:** AFK
**Origin:** [005-cache-build-followups](../specs/done/005-cache-build-followups/spec.md), 0.3.17 scope decision, design-log entry 2026-10-28 Scope decision: main-checkout resolver

## Goal

Anything that needs the main checkout's root gets the same answer from one place, including from a worktree whose git common dir is not named `.git`.

## Background

Spec 005 adds `wf_main_root` to the shared library and moves only the six feature-workflow scripts that also normalise a workflow folder path onto it (decision D5). The other copies were left out because the deeper prompt ruled out moving other copied helpers; they are a separate refactor across hooks, other skills and agent docs.

**Current behaviour:** around fifteen other places compute the main checkout themselves. Some use the full lookup (git common dir, then the worktree list), some take `dirname` of the common dir and skip the fallback, so a separate git dir gives the wrong root. Agent docs inline the expression. One copy resolves symlinks (`cd -P`) and returns a status; the rest do not. One script uses an absolute spec folder path as given, with no normalising.

**Desired behaviour:** each script and hook sources the shared helper; agent docs point at one documented command; every caller handles a non-`.git` common dir the same way; a script that takes a spec folder normalises it through `wf_norm_folder`.

## Constraints

- `.agents/lib/` is shared core: it changes only through the integration agent, between batches.
- Each caller keeps its own error message and exit code; the helper returns a status.
- bash 3.2, shellcheck clean.

## Decisions already made

- `wf_main_root` and `wf_norm_folder` live in `.agents/lib/workflow-paths.sh` (design-log D4 in [.workflow/specs/done/005-cache-build-followups/design-log.md](../specs/done/005-cache-build-followups/design-log.md)).
- Only the six normaliser scripts moved in spec 005 (D5).

## Evidence

- Full-lookup inline copy: `.agents/skills/feature-workflow/scripts/rules-setting.sh:73-75`, as of commit `d6edbc9`.
- Status-returning copy with `cd -P`: `.agents/skills/feature-workflow/scripts/check-write.sh:141-149`, as of `d6edbc9`.
- `dirname` of the common dir without the worktree fallback: `.agents/skills/feature-workflow/scripts/run-toolchain.sh:141-142`, `check-worktree-scope.sh:89-90`, `resolve-launch.sh:263-265`, as of `d6edbc9`.
- Absolute spec folder used as given: `.agents/skills/feature-workflow/scripts/run-toolchain.sh:144-147`, as of `d6edbc9`.
- Hooks: `.agents/hooks/codex-pre-spawn.sh:28,60-62`, `pre-launch.sh:64-66`, `session-start-resume.sh:56-58`, `rules-boundary-config-sync.sh:45-47`, `evidence-capture.sh:75`, `post-implementation-audit.sh:79,217`, as of `d6edbc9`.
- Agent docs: `.agents/agents/implementation.md:75,95`, `integration.md:65,79`, `profile-mini-review.md:70`; `.agents/skills/handoff/SKILL.md:18`, as of `d6edbc9`.
- Reported by module-audit (lib, feature-workflow) at 0.4.6 of spec 005; can wait.

## Acceptance criteria

- [ ] No script or hook under `.agents/` computes the main checkout outside `wf_main_root`.
- [ ] Agent docs name one command for the main checkout.
- [ ] A test runs each converted caller from a worktree whose common dir is not `.git` and gets the main checkout.
- [ ] Exit codes and messages of every converted caller are unchanged.
- [ ] `tests/run-all.sh` passes and shellcheck is clean.

## Out of scope

- The six feature-workflow scripts spec 005 already moved.
- Changing the path constants in workflow-paths.sh.
