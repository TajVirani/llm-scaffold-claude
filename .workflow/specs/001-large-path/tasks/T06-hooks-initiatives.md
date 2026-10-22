# T06: Hooks know initiatives

Index: [../tasks.md](../tasks.md) · Blocked by: T1 Initiative paths, ignore block and installer entries; T3 Templates admit initiatives · Parallel with: None

**What to build:** A session that starts in a project with initiatives is offered them. `session-start-resume.sh` lists every initiative that is `exploring`, or `planned` with an emitted spec not yet `done`, each once, with its status, its `.step` and the count of questions left `researching`; it finds initiatives in the working tree and, for a folder that exists only on an `initiative/*` branch, by reading `initiative.md` from that branch tip with `git show`, and a `done` initiative is omitted. The Codex pre-spawn hook accepts the `i<NNN>_<type>` task-name form for a launch from an initiative (an existing initiative folder, on disk or on its branch) and keeps denying malformed names. The settings templates deny edits to `.workflow/initiatives/*/.step` as they deny the spec marker.

**Seam:** Hook stdin and stdout JSON: the `additionalContext` text of `session-start-resume.sh` (the oracle in `tests/hooks/session-start-initiatives.sh`), the deny JSON and exit code of `codex-pre-spawn.sh`, and the deny list the install merges from `claude-settings.template.json` (`tests/scripts/install.sh`).

**Acceptance criteria:**

- [ ] After a conversion the resume offer names the initiative, not the deleted spec (JRN-001); with IQ1 `researching` it reports one pending research question, and after IQ1 is settled none (JRN-002).
- [ ] With an initiative committed only on `initiative/001-<slug>` and the checkout on main, the offer lists it from the branch tip; after a local merge it lists it from main; in both cases once, with status, step and the research count (JRN-004).
- [ ] The offer's wording follows the fixture's oracle (`tests/fixtures/initiative.sh`: the line starts `- .workflow/initiatives/NNN-slug:` and carries `status <s>`, `step <id>` and `research pending: <n>`), and the hook tells the reader to resume an initiative through the `feature-workflow` skill's large path.
- [ ] `codex-pre-spawn.sh` accepts `i001_research` when `.workflow/initiatives/001-*` exists, denies `s001_research` for a research launch with a reason, denies `i002_research` and `i009_fact_lookup` when no such initiative exists, and leaves every spec-form name unchanged (`tests/hooks/codex-adapters.sh` stays green).
- [ ] `claude-settings.template.json` adds `Edit(.workflow/initiatives/*/.step)` to `permissions.deny`, `claude-settings.template.md` explains it, `codex-config.template.toml` extends its comment, and `tests/scripts/install.sh` (the deny-list pin at its line 231) expects the new entry; the install suite passes.
- [ ] `pre-launch.sh` passes a `research` launch whose header `spec_dir` names an initiative folder through to `resolve-launch.sh` unchanged (no hook-side rejection of the folder shape); if nothing in it needs to change, leave it untouched and say so.
- [ ] Initiative paths come from `WF_INITIATIVES` in `workflow-paths.sh`, never spelled out; hook logic stays thin, with no business logic that belongs in a skill script.

**Predicted files:** `.agents/hooks/session-start-resume.sh`, `.agents/hooks/codex-pre-spawn.sh`, `.agents/hooks/pre-launch.sh`, `.agents/hooks/claude-settings.template.json`, `.agents/hooks/claude-settings.template.md`, `.agents/hooks/codex-config.template.toml`, `tests/scripts/install.sh`.

**Phase 1 tests:** `tests/scripts/initiative-conversion.sh`, `tests/scripts/initiative-transition.sh`, `tests/hooks/session-start-initiatives.sh`, `tests/hooks/codex-pre-spawn-initiative.sh`.

**Size:** M (7 files, about 220 changed lines).

**Mode:** afk.

**Notes:** Carries the hook half of migration M5 and the template part of M1 (D17, D26). The first two suites also exercise T4's script; this task owns them because its merge completes them (T4 and T6 share wave 2 and merge in id order). `git show <ref>:<path>` is the agreed idiom for reading a folder that is not in the working tree (D26); the hook reads `initiative.md` and the branch's `questions.md` that way and never checks the branch out. `tests/scripts/install.sh` overlaps with T1, which runs first; rebase your pin on T1's merged version.
