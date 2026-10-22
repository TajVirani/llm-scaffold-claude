# T07: Guards and launches from an initiative

Index: [../tasks.md](../tasks.md) · Blocked by: T1 Initiative paths, ignore block and installer entries; T2 Large track in the step list and progress line; T8 The research task type · Parallel with: None

**What to build:** The write guards and the launch resolver understand initiatives. `check-write.sh` gains a class for `initiative.md`: a Write or Edit to it is allowed only while the initiative's `.step` is at a `6.x` writer step (the steps `modules/large-path.md` marks as writing `initiative.md`), `questions.md` is writable at any step, and the Tier A gate also scans `.workflow/initiatives/*/.step`, so a glossary write with an initiative at a `6.x` term-gate step and no spec in flight is allowed and one at any other `6.x` step is denied. The class is reachable through the existing `--only` values the hook adapters pass, so no hook changes. `resolve-launch.sh` gains the `research` task type (header `spec_dir` only, whole profile not required) and lets `spec_dir` name an initiative folder for `research`, `fact-lookup`, `retrieval` and `library-evaluation`, resolving the model as for any type.

**Seam:** `check-write.sh --cwd <dir> --path <file> [--only spec|tier-a|tier-b]` exit code and reason, driven through `spec-single-writer-guard.sh` and `tier-a-write-guard.sh` with PreToolUse JSON on stdin (`tests/hooks/initiative-write-guards.sh`); `resolve-launch.sh --requirements` JSON and `--host claude|codex --task-type research` with a header whose `spec_dir` is an initiative folder (`tests/scripts/resolve-launch-initiative.sh`).

**Acceptance criteria:**

- [ ] JRN-006's sequence holds: `initiative.md` denied at a non-writer `6.x` step, allowed at a writer step, `questions.md` allowed, the glossary allowed at a term-gate step with no spec in flight and denied at another `6.x` step, each with the guard's reason text; a sub-agent write to `initiative.md` and any write to an initiative `.step` are denied.
- [ ] The `initiative.md` class falls under an existing `--only` value (`spec` for the single-writer guard, as the backlog-item class does), so `spec-single-writer-guard.sh`, `tier-a-write-guard.sh` and `codex-write-guard.sh` evaluate it without edits; the writer-step and term-gate lists are constants beside `SPEC_STEPS` and are the ids `steps.tsv` holds after T2.
- [ ] A spec in flight still decides a Tier A write as today; `tests/scripts/status-transition-check-write.sh` and `tests/hooks/write-guards.sh` stay green, with their pins updated only where the new step lists change an expected list.
- [ ] `resolve-launch.sh --requirements` lists `research` with its D31 fields (`spec_dir` only); a `research` header with `spec_dir: .workflow/initiatives/001-<slug>` resolves to a prompt and a model, as does `fact-lookup` from the same folder; a missing folder and a path that is neither a spec nor an initiative folder are denied with the existing reason shape; the `tests/scripts/resolve-launch.sh` type loop includes `research`.
- [ ] `tests/hooks/initiative-write-guards.sh` and `tests/scripts/resolve-launch-initiative.sh` pass.

**Predicted files:** `.agents/skills/feature-workflow/scripts/check-write.sh`, `.agents/skills/feature-workflow/scripts/resolve-launch.sh`, `tests/scripts/status-transition-check-write.sh`, `tests/scripts/resolve-launch.sh`.

**Phase 1 tests:** `tests/hooks/initiative-write-guards.sh`, `tests/scripts/resolve-launch-initiative.sh`.

**Size:** M (4 files, about 220 changed lines).

**Mode:** afk.

**Notes:** Carries the guard and launch halves of migration M5 (D30) and the launch side of M6 (D20). Initiative paths come from `WF_INITIATIVES` (T1). The spec folder format pinned by `FORMATS.spec_dir` stays; add an initiative format beside it rather than loosening the spec one, and keep the `:265` missing-dir deny. The `research` model is read from `.agents/agents/research.md` (T8) first, then `.workflow/model-map/research.md`, else 00.14, exactly as for other types.
