# T03: Workflow conventions file

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: T1

**What to build:** The rules every step file follows live once, in `.agents/skills/feature-workflow/references/conventions.md`, which the router loads together with the first step file (D7, D10). It holds, for specs and initiatives: one writer per state with the `status-transition.sh` forms and exit codes 0/1/2, the size budget, set the step then write with the guarded-writes table (Done folder and path-only rewrite rows included), never grow the spec mid-build (as a pointer to `modules/discovered-work.md`, the one home of the escalation classes, D23), the sub-agent write rule with both scopes (spec: only its own result file; initiative: nothing), the progress line with both call forms (`--spec-dir` and bare `<6.x>`), the Codex write-guard row and the other-skills row (spec Assumptions). In the same change:

- `SKILL.md` drops §5 and the Modules table, removes the `modules:` and `progressive_loading:` frontmatter keys (D14), and says to load `references/conventions.md` with the first step file.
- The router's §4 gate table merges into the questioning-loop Entry seed table (owner and status-call columns); each gate's step file keeps its status call, and the router keeps only the 5.6 call it owns (D3).
- `modules/large-path.md` Conventions keeps only the initiative parts (IT forms, the 6.x step table with term gates, Main ref, Commit point) and points to conventions for the rest.
- Summaries of the escalation rule outside `discovered-work.md` (router §5, review-triage) become one-line pointers; review-triage keeps its Phase 4 proof, verdict and bucket steps (D23).
- Every link to `../SKILL.md#5-conventions-every-module-follows`, `#progress-line` and the other moved anchors is re-pointed.

**Seam:** the conventions file as loaded text, checked by `lint/shared-rule-homes` (each marker in one file) and `lint/md-links` (every link resolves); existing pins re-pointed where they name a moved section.

**Acceptance criteria:**

- [ ] These markers appear verbatim in `references/conventions.md` and in no other file `lint/shared-rule-homes` scans: `Exit 0 done; 1 environment error`, `These files are written only from the main session, only at these steps.`, `| File | Allowed steps |`, `Lead every phase or step update`, `Sub-agents write only their own result file`, `write only on exit 0 (advisory)`.
- [ ] The guarded-writes table steps still match the step constants in `scripts/check-write.sh`.
- [ ] `**scope-expanding**` appears only in `modules/discovered-work.md`.
- [ ] `SKILL.md` frontmatter has no `modules:` or `progressive_loading:` key, and `tests/run-all.sh --suite lint/frontmatter` passes.
- [ ] `tests/run-all.sh --suite lint/md-links` passes; every other existing suite passes, re-pointed only where it names a moved file or section (`tests/lint/done-folder-docs.sh` pins the Done folder bullet; `tests/lint/review-escalation-docs.sh` pins the Modules-table deferred-handoff row and the router's "Never grow" text).
- [ ] `PROVENANCE.md` names `skills/feature-workflow/references/conventions.md`.

**Predicted files:** `.agents/skills/feature-workflow/SKILL.md`, `.agents/skills/feature-workflow/references/conventions.md`, `.agents/skills/feature-workflow/modules/large-path.md`, `.agents/skills/feature-workflow/modules/questioning-loop.md`, `.agents/skills/feature-workflow/modules/discovery.md`, `.agents/skills/feature-workflow/modules/review-triage.md`, `.agents/skills/feature-workflow/modules/discovered-work.md`, `PROVENANCE.md`, `tests/lint/done-folder-docs.sh`, `tests/lint/review-escalation-docs.sh`

**Phase 1 tests:** None (`lint/shared-rule-homes` goes green only once the small path is folded, T7).

**Size:** M (10 files, about 350 changed lines).

**Mode:** afk.

**Notes:** Launch rules and the Host notes Launch row are T4's; leave them in place here. Shares `PROVENANCE.md` with T1 under an approved `parallel_with`.
