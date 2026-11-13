# T01: Handoff skill writes per-run session handoffs in the session's checkout

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** A session that follows the handoff skill writes its session handoff into `.workflow/.handoff/` of the checkout it works in, under a name no other run uses, in a folder git ignores by itself. A session given a handoff by path resumes from it without asking and deletes it once it has written its successor or finished the work.

**Seam:** The one fenced bash block of `### 1. Locate` in `.agents/skills/handoff/SKILL.md`, extracted and run as written by `tests/scripts/handoff-skill.sh` with `stem` set; and the literal wording of the `## Resume` section.

**Acceptance criteria:**

- [ ] `### 1. Locate` holds exactly one fenced bash block that names `.gitignore`. Run with `stem` set, it sets `root` to the top level of the current checkout (`git rev-parse --show-toplevel`, else `$PWD`), creates `$root/.workflow/.handoff/`, writes `$root/.workflow/.handoff/.gitignore` holding exactly `*` when it is missing, and sets `file` to `$root/.workflow/.handoff/<stem>--<YYYYMMDDTHHMMSSZ>-<4 chars of [a-z0-9]>.md`, a path that does not exist yet. The block passes shellcheck and runs on bash 3.2 (JRN-001, JRN-002, JRN-003).
- [ ] The Locate prose says the file goes in the session's own checkout, never another checkout; the stem is the spec folder name or the topic; a session never replaces or overwrites another handoff. The "read it and replace it" rule is gone.
- [ ] Write step 4 tells the user the full path of the file and that a fresh session started in the same folder is offered it, or can be given the path.
- [ ] `## Resume` says a handoff named by path in the session's first message is resumed `without asking`, and that once you have written your own handoff or finished the work you `delete the handoff you resumed from`. A handoff under an old name (`<NNN-slug | topic>.md`) is resumed the same way (JRN-006).
- [ ] Resume's drift step sets its own `root` (the session's checkout) and no longer points at Write step 1; the order read, spec, drift, Verify, Next action stays.
- [ ] The frontmatter `description` and the comment in `assets/handoff.md` describe the per-checkout folder, the new name and the folder's own `.gitignore`; frontmatter keys and body sections are unchanged.
- [ ] `tests/run-all.sh --suite scripts/handoff-skill` passes, and `lint/frontmatter` still passes.

**Predicted files:** `.agents/skills/handoff/SKILL.md`, `.agents/skills/handoff/assets/handoff.md`

**Phase 1 tests:** `tests/scripts/handoff-skill.sh`

**Size:** S (2 files, about 60 changed lines).

**Mode:** afk.

**Notes:** The skill may depend on no other module (`.workflow/rules.md` Ownership), so the block stays inline and calls no script. Decisions: design-log D5-D8 and the Assumed entry on which rules.md the drift check reads. Module findings: codebase-map.md § Module audit (standalone-skills).
