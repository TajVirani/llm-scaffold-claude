# T02: Review lessons accept the Done folder

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** A review lesson whose origin spec has moved into the Done folder stays valid: `review-lessons.sh validate` accepts `origin_spec: .workflow/specs/done/NNN-slug` and a slug in the same class `wf_norm_folder` accepts (uppercase, `.`, `_`), and still rejects a path outside `.workflow/specs/` (D3, D13). The `check-pr-body.sh` header stops promising that 5.8 publishes the body unchanged: it is unchanged apart from the spec path the move rewrites (D14).

**Seam:** The `review-lessons.sh validate <file>` CLI (stdout lines, exit code), driven by `tests/scripts/review-lessons.sh`.

**Acceptance criteria:**

- [ ] `validate` accepts `origin_spec` values `.workflow/specs/012-x`, `.workflow/specs/done/012-x`, `.workflow/specs/00010-a.b_C-d` and `.workflow/specs/done/00010-a.b_C-d`.
- [ ] `validate` rejects `.workflow/specs/done`, `.workflow/specs/done/x`, `.workflow/specs/done/012-x/extra`, `.workflow/specs/work-backlog`, `specs/012-x` and any path outside `.workflow/specs/`, with the error line naming the rule.
- [ ] The script's header comment states the new rule (the template header changes with it in T4).
- [ ] `check-pr-body.sh` header lines 3 and 28 say 5.8 publishes the body unchanged apart from the spec path the move rewrites; no behaviour of `check-pr-body.sh` changes.
- [ ] `tests/scripts/review-lessons.sh` and `tests/scripts/check-pr-body.sh` pass; shellcheck clean.

**Predicted files:** `.agents/skills/feature-workflow/scripts/review-lessons.sh`, `.agents/skills/feature-workflow/scripts/check-pr-body.sh`

**Phase 1 tests:** `tests/scripts/review-lessons.sh`

**Size:** S (2 files, about 20 changed lines).

**Mode:** afk.

**Notes:** The rule text in the script and in `assets/review-lessons.md` must stay in step ("a change to the rules changes both"); T4 changes the template header to the same rule. The `check-pr-body.sh` change is comment lines only. `lint/done-folder-docs` (owned by T4) checks the header wording.
