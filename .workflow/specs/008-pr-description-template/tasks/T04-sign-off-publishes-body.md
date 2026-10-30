# T04: Sign-off fills, approves and publishes the PR body

Index: [../tasks.md](../tasks.md) · Blocked by: T1 (`pr_template` setting), T2 (PR template and its check), T3 (project-setup asks `pr_template`) · Parallel with: None

**What to build:** Sign-off produces the Sign-off PR description from evidence and sends exactly the approved text. 5.2 adds a `pr_template` proposal row when the key is unset and a host template exists at one of the D15 locations, offering each found path plus `workflow` (D14). 5.4 reads `rules-setting.sh pr_template`, stops and asks when it fails (D13), fills `pr-body.md` beside `report.md` from `assets/pr-template.md` (or the named host template's headings), and runs `check-pr-body.sh` (with `--project-template <path>` for a path). 5.5 shows the full text of `pr-body.md` for approval. 5.8 reruns the check, then publishes through the D11 block: `gh pr create ... --body-file`, `glab mr create ... --description-file`, never `--template`, or a local `git merge --no-ff -F` whose message is a Conventional Commits subject, a blank line and `pr-body.md`.

**Seam:** The 5.8 publish block (the fenced `bash` block right after `<!-- 5.8 publish commands -->` in `modules/sign-off.md`, using `SPEC_DIR`, `SPEC_BRANCH`, `MAIN`, `SUBJECT`) run against stand-in `gh`/`glab` and a fixture repo, plus text checks of sign-off, `SKILL.md` and project-setup, all in `tests/scripts/sign-off-pr.sh`.

**Acceptance criteria:**

- [ ] The publish block holds one-line `gh pr create` (`--base "$MAIN" --head "$SPEC_BRANCH" --body-file "$SPEC_DIR/pr-body.md"`), `glab mr create` (`--target-branch`, `--source-branch`, `--description-file`) and local-merge commands; it switches to `$MAIN` before merging, builds the message from `SUBJECT` and `pr-body.md`, and passes shellcheck.
- [ ] 5.2 names `pr_template`; 5.4 names `pr-template.md`, `pr-body.md`, `check-pr-body.sh` and the stop-and-ask on a failing setting; 5.5 shows the "full text" of `pr-body.md`; 5.8 names `check-pr-body.sh`, `--body-file`, `--description-file`.
- [ ] The design-log Sign-off entry shape in `assets/design-log.md` gains a line recording the body approval.
- [ ] `SKILL.md` lists `assets/` `pr-template.md` among the templates and `pr-body.md` among the per-feature files.
- [ ] `open-task-pr.sh`'s comment that its host-to-CLI choice "mirrors ... the sign-off PR step" stays true.
- [ ] `tests/scripts/sign-off-pr.sh` passes (JRN-005, JRN-006, including T3's three project-setup cases); agent-docs lint suites pass.

**Predicted files:** `.agents/skills/feature-workflow/modules/sign-off.md`, `.agents/skills/feature-workflow/SKILL.md`, `.agents/skills/feature-workflow/assets/design-log.md`

**Phase 1 tests:** `tests/scripts/sign-off-pr.sh`

**Size:** S (3 files, about 90 changed lines).

**Mode:** afk.

**Notes:** Order 5.4 → 5.5 → 5.9 → 5.7 → 5.8: the approved body cannot cite later commits; 5.4 runs after 5.3, so `CAP-NEW-` ids are already rewritten. A 5.6 change request returns through 5.4/5.5 and refills `pr-body.md`. Keep 5.8's go-ahead and push-only-what-was-asked rules. `SKILL.md` may also be touched by spec 006 in a parallel checkout; keep the edit to the assets line.
