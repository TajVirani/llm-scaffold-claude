# T05: Project mode reads every heading level

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** `check-pr-body.sh --project-template <path>` judges a body against every heading of a project's own PR/MR template, whatever its level, so a GitHub template written with `###` headings works (D19). The shipped workflow template's issue stub line names no file of this scaffold repo (F1).

**Seam:** The `check-pr-body.sh <file> --project-template <template file>` CLI (exit 0 silent; exit 1 one `<field>: <problem>` line per fault; exit 2 usage, unreadable template or a template with no headings), driven from the `JRN-003` cases of `tests/scripts/check-pr-body.sh`.

**Acceptance criteria:**

- [ ] Project mode reads every ATX heading `#` to `######` of the template; each must appear in the body at the same level with the same text and be non-empty; a section runs to the next heading of the same or a higher level, so a heading holding only deeper subsections is filled; no order check.
- [ ] Exit 2 only for a template with no headings at all or one that cannot be read; the `# Exit:` header says so. A template with only `###` headings works.
- [ ] Workflow mode is unchanged (ten `##` sections, order, scores, the Risk-heading guard).
- [ ] `assets/pr-template.md` Link to issue guidance gives a project-neutral stub line (e.g. "No tracker issue yet: the workflow does not create one when a spec starts."), naming no `.workflow/` file of this repo.
- [ ] `tests/scripts/check-pr-body.sh` passes (44 cases); shellcheck clean; TGT-007 still ≤ 1 s.

**Predicted files:** `.agents/skills/feature-workflow/scripts/check-pr-body.sh`, `.agents/skills/feature-workflow/assets/pr-template.md`

**Phase 1 tests:** `tests/scripts/check-pr-body.sh`

**Size:** S (2 files, about 60 changed lines).

**Mode:** afk.

**Notes:** Triage pass 1 F4 (D19) and F1. The suite selector is the same one T2 (done) lists; selectors are per suite.
