# T02: PR template and its check script

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** The PR template `assets/pr-template.md` with the ten sections in order, each a `##` heading followed by guidance naming the evidence it is filled from, and `check-pr-body.sh`, which tells sign-off whether a filled body is fit to publish. In workflow mode it checks the ten headings are present, in order and non-empty, and that the Risk and Reversibility scores are on their scales, with Irreversible requiring Risk: High. In project mode (`--project-template <path>`) it checks only that every `##` heading of that template is present and non-empty.

**Seam:** The `check-pr-body.sh <file> [--project-template <template file>]` CLI (exit 0 silent; exit 1 with one `<field>: <problem>` line per fault on stdout; exit 2 for usage or a missing file on stderr), plus the template's headings, driven from `tests/scripts/check-pr-body.sh` with bodies built by `tests/fixtures/pr-template.sh`.

**Acceptance criteria:**

- [ ] The template holds, in order: Link to issue; What changed; Why the change; Why this approach; Special things to note; How to test; Blast radius; Risk and reversibility; Areas, concepts and seams changed; How to undo this PR. Each has at least one non-blank guidance line naming its evidence source (`codebase-map.md` module-audit row: Why ← spec.md, Approach ← design-log, Seams ← codebase-map, How to test ← report "How to verify", Notes and risk ← report "Known gaps"/"Deferred", Blast radius ← `budget-check.sh` `files`). Link to issue says to use the fixed stub line naming `.workflow/deferred/spec-issue-creation.md` until issues exist. How to undo says to state why when the change cannot be undone, with Risk: High (D5).
- [ ] Fault lines follow the Phase 1 contract: the section heading as field with "missing", "empty" or "order"; `Risk` / `Reversibility` with the bad value; the Irreversible rule naming "Irreversible"; a missing Risk line as `Risk: ...`. Scores are read as the first word after the colon (`Risk: Medium - <reason>`). Every fault is reported, not just the first.
- [ ] The script follows the validator family shape (`check-review-findings.sh`): full header (File, Purpose, Usage, stdout, Exit, Called by, Notes, Sources), `PROG=`, `die`/`usage`, bash 3.2, read-only.
- [ ] `PROVENANCE.md` marks both files implemented, not stubs.
- [ ] `tests/scripts/check-pr-body.sh` passes; shellcheck clean; TGT-007 (≤ 1 s best of 3 on the template).

**Predicted files:** `.agents/skills/feature-workflow/assets/pr-template.md`, `.agents/skills/feature-workflow/scripts/check-pr-body.sh`, `PROVENANCE.md`

**Phase 1 tests:** `tests/scripts/check-pr-body.sh`

**Size:** S (3 files, about 180 changed lines).

**Mode:** afk.

**Notes:** Template and check stay in one task because JRN-001 fills the template and checks the result in one case (approved at 2.1). Guidance lines in the template must not themselves look like filled content in a way that hides an empty section from the check: decide how the check tells guidance from content (for example HTML comments) and keep `tests/fixtures/pr-template.sh`'s body builder working (it keeps `## ` headings and drops other template lines). `PROVENANCE.md` is also edited by spec 006 in a parallel checkout; touch only the two 008 entries.
