# T04: Launching reference

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (Term-list script), T3 (Workflow conventions file) · Parallel with: None

**What to build:** How to launch a sub-agent lives once, in `.agents/skills/feature-workflow/references/launching.md`, read by a step file at the step that launches (D2). It holds the launch header and `LAUNCH ERROR:` rule, `resolve-launch.sh --requirements`, the 00.14 and 00.19 denies, the Claude and Codex Launch rows of today's Host notes, and every Codex task-name form (`s<NNN>_…` and the initiative `i<NNN>_…` forms, D10). The router keeps only the resume-offer row; the question-rounds row goes to the questioning loop, which already has its own round format. Codex launch details repeated in step files (discovery, questioning-loop, review-triage, implementation-orchestrator, verification-setup, large-path) become a pointer to `launching.md`, and every `../SKILL.md#host-notes` link and plain-text "SKILL.md Host notes" reference is re-pointed.

**Seam:** `launching.md` as loaded text, checked by `lint/shared-rule-homes` and `lint/md-links`.

**Acceptance criteria:**

- [ ] These markers appear verbatim in `references/launching.md` and in no other scanned file: `Every launch prompt starts with the launch header on its first line`, ``a full-history fork may ignore the spawn `model` override``, `` `hooks/codex-pre-spawn.sh` denies a malformed name ``.
- [ ] No file under `.agents/` links `SKILL.md#host-notes` or says "SKILL.md Host notes".
- [ ] Every step id in `--step` and `step <dir> <id>` calls is still a row of `steps.tsv` (`lint/step-list` passes).
- [ ] `lint/md-links` and every other existing suite pass, re-pointed only where a suite names a moved section (`tests/lint/small-path-docs.sh` keeps its `s<NNN>_review_combined` assertion pointed at wherever that Codex name now lives).
- [ ] `PROVENANCE.md` names `skills/feature-workflow/references/launching.md`.

**Predicted files:** `.agents/skills/feature-workflow/SKILL.md`, `.agents/skills/feature-workflow/references/launching.md`, `.agents/skills/feature-workflow/modules/discovery.md`, `.agents/skills/feature-workflow/modules/questioning-loop.md`, `.agents/skills/feature-workflow/modules/review-triage.md`, `.agents/skills/feature-workflow/modules/implementation-orchestrator.md`, `.agents/skills/feature-workflow/modules/verification-setup.md`, `.agents/skills/feature-workflow/modules/large-path.md`, `.agents/skills/feature-workflow/modules/sign-off.md`, `.agents/skills/feature-workflow/modules/deferred-handoff.md`, `PROVENANCE.md`, `tests/lint/small-path-docs.sh`

**Phase 1 tests:** None.

**Size:** M (12 files, about 300 changed lines).

**Mode:** afk.

**Notes:** The edge from T1 orders their `PROVENANCE.md` rows; the work does not depend on the term-list script.
