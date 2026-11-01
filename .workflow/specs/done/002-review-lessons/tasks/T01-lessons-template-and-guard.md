# T01: Lessons file template and the 5.7 guard class

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** The project's review-lessons file gets a home and a gate. A new template, `.agents/skills/feature-workflow/assets/review-lessons.md`, is the empty lessons file every project starts from: a header comment with the entry rules and two runnable commands (`validate:` and `next-id:`), then one fenced YAML block holding `lessons: []`. The write guard learns the file: `check-write.sh` classifies `.workflow/review-lessons.md` as a Tier A class of its own, `review-lessons`, allowed from the main session at step `5.7` only and denied everywhere else, so `tier-a-write-guard.sh` allows the retrospective's write at 5.7 and denies any other. The feature-workflow `SKILL.md` guarded-writes table and the hook's header say so.

**Seam:** `check-write.sh --cwd <repo> --path .workflow/review-lessons.md [--agent <id>]` exit codes and messages (`tests/scripts/check-write-tier-a.sh`), and the hook's allow or deny JSON on a Write payload (`tests/hooks/write-guards.sh`). The template's own commands, extracted from its header (`sed -n 's/^validate: //p'`, likewise `next-id: `) and run as `bash -c "$cmd" _ <file>`, are the oracle `tests/lint/review-lessons.sh` (owned by T6) and the retrospective (T5) use.

**Acceptance criteria:**

- [ ] `.agents/skills/feature-workflow/assets/review-lessons.md` exists: an HTML comment header stating the entry rules from `data-model.md` § Review lesson (`id` matches `^RL-[0-9]{3,}$`, unique, the next id is the highest present plus one and an id is never reused; `symptom` non-empty; `paths` at least one repo-relative glob in the Ownership-block syntax, no absolute path, no `..`; `origin_spec` matches `^\.workflow/specs/[0-9]{3}-[a-z0-9-]+$`; `date` is `YYYY-MM-DD`; optional `retired` is an ISO date and then `enforced_by` is required and non-empty), one line `validate: <command>` and one line `next-id: <command>`, each a bash command that reads the file path from `"$1"` (bash 3.2, awk to cut the fenced block, mikefarah yq v4 and jq only), then one fenced ` ```yaml ` block holding `lessons: []`. Comments give reasons in plain words and cite no decision id or workflow path.
- [ ] `validate:` exits 0 on the template itself and on a file holding one entry or a retired entry (unquoted ISO dates accepted), and non-zero on each of: a retired entry without `enforced_by`, two entries with one id, an empty `paths`, an absolute path in `paths`, a bad `origin_spec`, a bad `date`, a `lessons` that is not a list.
- [ ] `next-id:` prints `RL-001` for the template, `RL-002` after `RL-001`, and still `RL-002` when `RL-001` is retired.
- [ ] `check-write.sh` classifies the path (case-insensitive, built from `WF_REVIEW_LESSONS` like the other `P_` prefixes) as `CLASS=tier-a KIND=review-lessons`, with `REVIEW_LESSONS_STEPS="5.7"`: exit 0 and `allow:` when the newest in-flight spec's `.step` is `5.7`; exit 2 with a deny naming 5.7 on stderr at `0.3.7`, `5.3`, `4.9`, `0.1.4` and with no feature in flight; exit 2 for a sub-agent (`--agent`) at 5.7; `--only tier-a` includes it. No other class changes.
- [ ] `tier-a-write-guard.sh` allows a Write payload for the file at 5.7 and prints the deny JSON otherwise; its logic is unchanged and its header Goals line names `.workflow/review-lessons.md` at 5.7.
- [ ] `.agents/skills/feature-workflow/SKILL.md` "Set the step, then write" table gains the row `.workflow/review-lessons.md` → `5.7`.
- [ ] `tests/scripts/check-write-tier-a.sh` and `tests/hooks/write-guards.sh` pass in full (the JRN-004 assertions and every earlier one); `tests/scripts/check-write-paths.sh` still passes.

**Predicted files:** `.agents/lib/workflow-paths.sh` (shared core, through integration), `.agents/skills/feature-workflow/assets/review-lessons.md`, `.agents/skills/feature-workflow/scripts/check-write.sh`, `.agents/skills/feature-workflow/SKILL.md`, `.agents/hooks/tier-a-write-guard.sh`, `tests/scripts/check-write-tier-a.sh`, `tests/hooks/write-guards.sh`.

**Phase 1 tests:** `tests/scripts/check-write-tier-a.sh`, `tests/hooks/write-guards.sh`.

**Size:** M (7 files, about 160 changed lines).

**Mode:** afk.

**Notes:** Shared-core request (touches_core): add `WF_REVIEW_LESSONS="$WF_DIR/review-lessons.md"` to `.agents/lib/workflow-paths.sh` beside `WF_RULES`, same form and comment style, so `check-write.sh` and every later consumer name the lessons file through one variable; the consumer contract is a repo-relative path. Carries migrations M1 (the variable), M2 (the guard class, the SKILL.md row, the hook header) and the feature-workflow half of M3 (the template; T6 adds the project-setup row). The template lives under feature-workflow because both `retrospective` and `project-setup` may depend on it and on nothing else they share (D9). The hook header line (hooks module) and the SKILL.md row were granted to this task at the 2.1 quiz. The fixture lesson text in `tests/fixtures/review-lessons.sh` is the only lesson text; the template holds an empty list.
