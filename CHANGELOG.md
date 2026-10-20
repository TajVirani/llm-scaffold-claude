# Changelog

All notable changes to llm-code-wiki are documented here.
Versions follow [Semantic Versioning](https://semver.org/).

## [2.0.0] — 2026-09-14

Resets the repository for workflow 2.0 and includes the build-out that followed (previously listed under Unreleased), which builds the workflow 2.0 scaffold on top of the reset.

### Added
- **Workflow skills.** `feature-workflow` (entry point, phase modules, discovered-work and deferred-handoff modules, templates, shared scripts), `project-setup`, `regenerate-caches`, `domain-modeling` (first-party, adapted from upstream) and `retrospective`.
- **Agents.** Twelve sub-agent definitions in `.agents/agents/`, with `.claude/agents` symlinked to them.
- **Hooks.** Launch resolution (`pre-launch`), post-implementation audit, write guards for specs, Tier A and Tier B, boundary-config sync, evidence capture, session-start resume, and a first-party destructive-git guard; thin Claude adapters over host-neutral shared scripts.
- **Discovered work and size budget.** Out-of-scope findings block the spec for a user ruling, feed a work backlog, and a soft size budget triggers the same protocol (D56-D58, D66-D69).
- **`install.sh` and `.agents/install-manifest.txt`.** Installs only the first-party payload into a target project, creates the Claude shim, merges settings, and can upgrade in place; `--dry-run` and `--force` supported (D11, D36, D72).
- **Codex shim.** `.codex/README.md` plus Codex hook, permission and agent-generator templates that `install.sh` merges into a target's `.codex/` (D9, D40, D66, D67).
- **`PROVENANCE.md`.** First-party versus vendored inventory of `.agents/`.
- **Tests.** `tests/run-all.sh` with a shared library and one suite per script and hook; end-to-end install and hook verification records under `PLAN/`.
- **`deeper-prompt` skill (D73).** First-party skill and discovery step 0.3.22: rewrites the request into a deeper prompt the stakeholder agrees to, on first entry to the questioning loop only. Ships in the payload.
- **Vendored copies (D74).** A first-party asset that needs a vendored file at runtime gets its own copy with a `Copied from` header and LICENSE, tracked in the scaffold-only `vendor-copies.json`. `pr-quality` now reads `references/codebase-design.md` instead of the removed `improve-codebase-architecture/LANGUAGE.md`.
- **Project-owned content in shipped skills (D75).** `design-pattern-doc` conventions (`docs/design-pattern-doc/conventions.md`) and `pr-quality` project-specific modules (`docs/pr-quality/`) are read from the target project when present; the skills ship generic templates only and install never overwrites the project copies. Athena originals are archived under `PLAN/archive/`.
- **Plan and decision docs.** `PLAN/`, `assetlist.md` (decisions D1+), `checklist.md`, `GLOSSARY.md` with the workflow vocabulary.
- **`project-standards` skill and `standards-discovery` agent (D80).** Sets up and refreshes a project's standards: greenfield interview or brownfield discovery, a staging baseline and one approval ledger, written to `docs/rules.md`, work profiles, ADRs (including `0001-project-baseline`), `docs/pr-quality/` checks, per-profile lint config and a managed `AGENTS.md` block; `project-setup` now delegates rules and profile filling to it. `standards-discovery` is the twelfth task type (strong tier, header optional).
- **`context-bridge.js` status line ships (D79).** The user's own `hooks/context-bridge.js` is first-party, in the install manifest, and wired as `statusLine` in the Claude settings template; `install.sh` keeps a different user `statusLine` with a warning (replaced with `--force`). It prints a context-usage bar and writes `<tmpdir>/claude-ctx-<session_id>.json`; nothing reads that file yet.
- **Context bar on by default on both hosts (D83).** Claude: the status line script is renamed `hooks/context-bridge.cjs` (contents unchanged) so it no longer crashes in targets whose `package.json` sets `"type": "module"`. Codex: `install.sh` adds `[tui] status_line = ["model-with-reasoning", "context-remaining", "current-dir", "git-branch"]` to `.codex/config.toml` in its own marker block, keeping a `[tui]` table the user already has with a warning.
- **Phase progress line (D84).** Every orchestrator update to the stakeholder leads with `Phase 1 of 6 · step 23 of 47 — Discovery: Compute the frontier (0.3.8)`, printed by `feature-workflow/scripts/step-progress.sh` from the ordered step list `feature-workflow/references/steps.tsv`; the light path counts its 4 phases. Display only: step ids, guards and scripts are unchanged. `tests/lint/step-list.sh` keeps the list in step with the decision flow.
- **Per-task files and a spec branch (D85).** Task breakdown writes `tasks.md` as an index (records with predicted files, S/M/L size, `afk`/`hitl` mode, approved `parallel_with` overlaps, waves table) plus one `tasks/T<nn>-<slug>.md` per task from the new `feature-workflow/assets/task.md`. Each spec runs on `spec/NNN-slug` (baseline = its first commit; Phase 1 committed there, red by design until the last wave); the orchestrator creates `task/NNN-slug/T<nn>-<slug>` branches and `.workflow/.worktrees/` worktrees on both hosts, pauses before `hitl` tasks, merges in id order, opens a non-blocking task PR/MR by default (`task_review` in `.workflow/rules.md`), and sign-off merges the spec branch into main through a PR. 2.6 also checks predicted files; 3.15 counts from the new `impl_base_revision`, so Phase 1 files never count.

### Changed
- **Reset to implement workflow 2.0.** The 1.x wiki scaffold is retired in full and the repository is reset to a clean base for workflow 2.0. The distribution unit moves from `.claude/` to `.agents/` so the scaffold is agent-agnostic rather than Claude Code-specific; all project-relative `.claude/` paths inside retained skills and commands are updated to `.agents/`.
- **Claude Code shim.** `.claude/` is reduced to `settings.json` (hooks, permissions, plugins, output style) plus `skills`, `commands`, and `output-styles` symlinks into `.agents/`. Claude Code does not discover `.agents/` natively, so the shim is what registers the scaffold with it; other agents read `.agents/` directly.
- **`AGENTS.md` replaces `CLAUDE.md`.** Project instructions move to the agent-agnostic `AGENTS.md`. `CLAUDE.md` remains as a one-line `@AGENTS.md` import.
- **Vendored skills are temporary; lineage moves to `upstream-lineage.json` (D77).** We ship a first-party version of everything that affects how agents work and delete each vendored skill once that version exists and its lineage is recorded; vendored skills still never install. Add-ons unrelated to how agents work (anti-slop Oxlint plugins) install from upstream at a pinned commit. The scaffold-only `upstream-lineage.json` replaces `vendor-copies.json` and records every derived asset (`copy`, `derived`, `pinned-addon`) so vendor updates can be diffed from the pinned commit.
- **Vendored skills deleted except the two being rewritten (D78).** `handoff` (the session-handoff owner) and `writing-for-agents` get first-party rewrites; every other vendored skill and the unverified `wrap-up` are deleted with their `skills-lock.json` entries. First-party `Sources:` lines now cite upstream `<repo>/<path>@<commit>`, and the local `grill-with-docs` additions `REFERENCE-DOC.md` and `TEMPLATE.html` moved to `feature-workflow/references/` as first-party files. Anti-slop stays a pinned add-on fetched from upstream.
- **Vendored skills refreshed from upstream, with the D71 policy.** Vendored skills (mattpocock/skills, dmmulroy/anti-slop, claude-night-market) are scaffold-repo tooling and upstream reference only. They are never installed into target projects and first-party assets do not depend on them at runtime. `grill-me` stays in `skills-lock.json` (its hash matches the vendored folder).
- **Commands migrated to skills.** The `pr-quality` and `pr-review-data` commands are now skills; the workflow ships no commands (D27). The `.claude/commands` symlink is gone.
- **Renamed upstream skills.** `diagnose` is `diagnosing-bugs` and `to-issues` is `to-tickets`.
- **`evidence-capture` fires on failing suites.** It is now also wired to `PostToolUseFailure`, so a browser suite that exits non-zero still files its evidence (fixes E2E bug F-1).
- **`AGENTS.md`** explains the scaffold repo versus target project split and the full layout.
- **Target-project layout: everything under `.workflow/` (D81).** In a target, the glossary, rules, capabilities, decisions, caches, pr-quality checks, design-pattern-doc conventions, profiles, model map, `agent-overrides.yaml`, specs, deferred items, tools, the `data-structure-audit` state file (`.workflow/data-structure-audit-state.jsonl`, moved out of scaffold-owned `.agents/`) and the staging, handoff and worktree dirs now live in one committed folder, `.workflow/`, created by `project-setup`. `e2e/`, the app's own files and root tool configs stay at root. The paths in the D75 and D80 entries above and in earlier entries refer to the pre-D81 layout. No migration, since 2.0.0 is unreleased. The model map stays sub-agents only; there is no main-session model file.
- **`project-standards` interview has mandatory coverage; `project-setup` runs it first (D82).** The greenfield interview must cover libraries per framework and concern, folder methodology with a layout tree, naming, and patterns at the depth of an architecture document; a shorter fast path runs only on explicit request. `project-setup` now runs the interview before offering example profiles and before installing any toolchain.

### Removed
- **Wiki system.** `wiki/` (all notes, `Rules.md`, `_templates/`, `topic-index.md`, inbox archives), the `wiki-curator`, `wiki-recall`, and `module-author` sub-agents, the `inbox-stop.sh` and `recall-prompt.sh` hooks and their `Stop`/`UserPromptSubmit` registrations, and the `wiki-digest`, `wiki-recall`, `wiki-rules`, `wiki-modules`, `wiki-code-crawler`, and `inbox-update` skills. `MODULES-IMPLEMENTATION.md` design handoff.
- **Install and update flow.** `INSTALL.md`, `VERSION`, `dist-manifest.txt`, and the `wiki-install` and `wiki-update` skills.
- **Tests and CI.** `tests/` (static, hook, and install end-to-end layers) and `.github/workflows/test.yml`.
- **Docs.** `docs/` including ADR 0001 (MODULES ownership and detection).
- **`skills-lock.json` (D79).** No vendored skills remain (D78), so the lock file is gone; upstream commits live in `upstream-lineage.json` and the frontmatter lint treats every skill as first-party.
- **Athena-specific content in `pr-quality`, `deps-audit` and `deps-update` (D79).** Removed outright rather than made project-owned: `pr-quality` (now 1.3.0) `seam-conformance` reads `docs/rules.md` § Ownership and `docs/cache/modules.md`; `deps-*` take commands from the work profile's Toolchain block and workspaces from the root `package.json`.

### Migration
- No upgrade path from 1.x. Consumers on the 1.x wiki scaffold should stay on the `main` branch history at tag/version 1.3.3; workflow 2.0 is a fresh start.
- **Upgrade note (D75).** Projects that got `.agents/skills/design-pattern-doc/conventions.md`, or pr-quality's `modules/legend-state-review.md` / `modules/project-pitfalls.md`, from an earlier install will have them pruned on upgrade. Copy them first to `docs/design-pattern-doc/conventions.md` / `docs/pr-quality/`, or take athena's originals from `PLAN/archive/`.

## [1.3.3] — 2026-05-10

### Fixed
- **`/wiki-digest` aborted with `Shell command failed for pattern "!P=\"${ARGUMENTS:-wiki/inbox/_session.md}\"; cat \"$P\" 2>/dev/null"`.** Three `!`-injected backtick blocks in `wiki-digest/SKILL.md` (entry-count, archive-session, cat-session) used `${ARGUMENTS:-wiki/inbox/_session.md}` to default a path. Bash's `${VAR:-default}` syntax around `${ARGUMENTS}` (a Claude-Code-substituted skill variable) collides with the harness's own preprocessing of `${ARGUMENTS}` and causes the harness to reject the command. Fixed by splitting the form into bare `$ARGUMENTS` (which the harness substitutes cleanly) feeding a regular bash variable, then defaulting that: `P="$ARGUMENTS"; P="${P:-wiki/inbox/_session.md}"; …`. Same flavor of harness-fragility as the multi-line `!`-injection bug fixed in 1.3.2 and the awk `$N`-expansion bug fixed in 1.3.0 — bash works fine when run directly, breaks only through the harness.

### Added
- **`tests/static.sh` lints `${ARGUMENTS:-…}` in `!`-injected blocks.** Reject any `!`-block matching `\$\{ARGUMENTS[:-]` and point at the safe pattern. Caught all three occurrences in wiki-digest in CI.

### Changed
- **wiki-digest "Resolve the session inbox path" prose updated** to document the `P="$ARGUMENTS"; P="${P:-default}"` pattern and explain the `${ARGUMENTS:-…}` collision, with a pointer to the `tests/static.sh` lint that enforces it.

### Migration
- **No manual migration required.** Fix activates the moment the new `wiki-digest/SKILL.md` lands via `/wiki-update`. Behavior of `/wiki-digest` is identical otherwise — only the argument-default literal layout changed.

## [1.3.2] — 2026-05-09

### Fixed
- **`/wiki-modules` aborted with `eval: line 13: syntax error near unexpected token \`done'`.** Two of the skill's `!`-injected backtick blocks (the prefix-cluster member listing and the Signal-3 external-fan-in computation) spanned multiple physical lines. Claude Code's skill harness mangles multi-line ` !\`...\` ` blocks — the trailing `done` lands on its own eval line with no matching `do`, and bash rejects it. Both blocks are now collapsed onto single lines using `;` separators; behavior is identical. Same kind of latent harness-fragility bug as the `!`-injection `$N` expansion bug fixed in 1.3.0 (both surface only when the skill actually executes, not from reading the source).

### Added
- **`tests/lib/extract-bang-blocks.sh`** — extracts `!`-injected backtick blocks from a SKILL.md (single-line and multi-line, indent-aware so it doesn't false-positive on mid-prose mentions of ` !`syntax` `).
- **`tests/static.sh` lints `!`-injection blocks** — for every SKILL.md, runs `bash -n` on each extracted block AND rejects any block that spans more than one physical line. The multi-line lint is the defensive rule that would have caught `/wiki-modules` before a user did. Adds 3 PASS lines (one per skill that uses `!`-injection: wiki-code-crawler, wiki-digest, wiki-modules) → L1 grows from 55 → 58 checks.

### Changed
- **`/wiki-modules` implementation note expanded** — the existing "no `awk`" caveat now also documents the "no multi-line `!`-injection" rule, with a pointer to the `tests/static.sh` lint that enforces both.

### Migration
- **No manual migration required.** The fix activates the moment the new `wiki-modules/SKILL.md` lands via `/wiki-update`. Behavior of the cluster-detection signals is unchanged — only the bash literal layout differs.

## [1.3.1] — 2026-05-09

### Added
- **Default permissions seeded into `.claude/settings.json` on install.** `/wiki-install` Block 2 and `/wiki-update` Step 5 now write `Read(wiki/inbox/_session.md)`, `Edit(wiki/inbox/_session.md)`, `Write(wiki/inbox/_session.md)` into `permissions.allow`. Without these, the auto-wiki capture path triggers a permission prompt every Stop-hook fire (i.e. after every code-edit turn). The fresh-create branch (Case A) writes the block via heredoc; the merge branch (Case B/C) runs an `upsert_permission` jq filter that skips entries already present and never removes user-added ones. `/wiki-update` backfills the same three entries on existing installs that pre-date this feature, also without disturbing user-added permissions. Manual no-jq fallback documented in `.claude/skills/wiki-install/SETTINGS-SNIPPET.md`.
- **`tests/` shell-based test harness** — three layers, no Claude needed. `tests/static.sh` (L1) walks `dist-manifest.txt`, validates frontmatter on every SKILL.md and agent .md, runs `bash -n` on hooks plus every fenced ` ```bash ` block in every SKILL.md. `tests/hooks.sh` (L2) unit-tests both hook scripts with synthetic JSON input — covers `stop_hook_active`, kill switches, noop/artifact branches, brainstorm-fallback (uses `LCW_BRAINSTORM_TURNS=3` for speed), recall fire/noop/wiki-only/cooldown. `tests/install-e2e.sh` (L3) extracts the install/update bash blocks and runs them in tmpdir fixtures, asserting `settings.json` shape, idempotence, user-permission preservation, and the wiki-update Step-5 backfill path. `tests/run-all.sh` runs all three; supply layer names to run a subset. L3 skips cleanly when `jq` is missing.
- **`.github/workflows/test.yml`** — runs `tests/run-all.sh` on push to main and on every pull request. Installs `jq` so L3 runs. Keeps the scaffold honest as it evolves.

### Fixed
- **`$CLAUDE_PROJECT_DIR` token verification was always failing on Case B/C of the settings.json merge.** `/wiki-install` Block 2 and `/wiki-update` Step 5 verify post-merge that the literal `$CLAUDE_PROJECT_DIR` token survived (i.e., wasn't shell-expanded into a hardcoded install-time path). The verification used `grep -q '"$CLAUDE_PROJECT_DIR"/...'` but jq writes the JSON value with the inner double-quotes serialized as `\"$CLAUDE_PROJECT_DIR\"`, so the unescaped pattern never matched and the merge aborted. Fixed by switching to `grep -qF '\"$CLAUDE_PROJECT_DIR\"/...'` to byte-match the JSON-escaped form. The L3 install-e2e harness caught this. Same flavor of latent bug as the `!`-injection `$N` expansion bug fixed in 1.3.0 — captured in the new `RESEARCH::jq-json-escape-grep-verification` inbox entry for the next `/wiki-digest` run.

### Migration
- **No manual migration required.** Existing installs gain the three default permission entries on the next `/wiki-update`; the merge skips entries already present, so re-runs converge to a zero-content-diff. The B3 verification fix activates the moment the new `/wiki-update` lands the new `wiki-install/SKILL.md` and `wiki-update/SKILL.md` files.

## [1.3.0] — 2026-05-09

### Added
- **`docs/adr/0001-modules-ownership-and-detection.md`** — formal ADR codifying that `/wiki-modules` is the sole writer to `wiki/MODULES/`. The wiki-curator no longer writes MODULES notes; `@ MODULES::<slug>` handles in `_session.md` surface as `MODULES-VIA-DIGEST-DEPRECATED` plan rows during digest with no write performed.
- **`module-author` subagent** (`.claude/agents/module-author.md`) — dispatched in parallel by `/wiki-modules`, one per qualifying cluster. Reads its cluster's children, applies pre-author and post-author depth gates, and writes `wiki/MODULES/<slug>.md` plus the matching `### Modules` row in `wiki/topic-index.md`.
- **`/design-pattern-doc` skill** — discover and document a multi-file design pattern in the codebase. Produces a ground-truth doc plus a drift report against existing project documentation. Use for cross-cutting patterns and subsystem wiring.

### Changed
- **`/wiki-modules` cluster-detection signals rebased per ADR 0001** — three deterministic signals: S1 filename prefix ≥3 notes (bootstrap), S2 single-dominant-tag intersection across all members (replaces the prior top-2 mode test — admits clusters whose members diverge into specialized topics past one shared concept), S3 external fan-in: ≥1 note outside the cluster links to ≥2 distinct cluster members (replaces the prior intra-cluster-link density test — measures whether the cluster has an external interface, not just internal cohesion).
- **`/wiki-digest` no longer pre-computes module-cluster signals.** Trigger 7 (Rules.md §12 row 7) was removed from the digest pipeline. `/wiki-modules` owns the orientation layer end-to-end. The wiki-digest skill body is leaner: input gathering for the curator, archive-then-write, post-write link audit, lifecycle cleanup.
- **`wiki-curator` write surface narrowed.** Curator never writes `wiki/MODULES/<slug>.md` and never modifies `wiki/Rules.md` or `wiki/_templates/`. Path-safety denylist: `wiki/Rules.md`, `wiki/_templates/**`, `wiki/MODULES/**`.

### Fixed
- **`!`-injection `$N` expansion bug.** Claude Code's skill `!`-injection layer expands `$N` references in awk scripts to empty strings before the shell sees them, breaking field access. All cluster-detection bash blocks in `/wiki-modules` now use `cut`/`sed` + a `while read` loop instead of `awk`. An inline implementation note in the skill body warns future edits not to re-introduce awk; the underlying bug is documented at `wiki/RESEARCH/skill-bash-injection-dollar-n-expansion.md`.

### Migration
- **No manual migration required.** Existing `wiki/MODULES/` notes from previous versions remain valid. The next `/wiki-modules` run audits each existing module against current cluster signals and re-authors qualifying clusters from scratch (failed-gate clusters surface as `STALE-MODULE` warnings — files are NOT auto-deleted).
- **If you previously relied on `/wiki-digest` to auto-create module notes via the trigger-7 pre-evaluation:** that path is gone. Run `/wiki-modules` manually to refresh the orientation layer.

## [1.2.0] — 2026-05-06

### Added
- **`MODULES/` orientation layer** — sixth wiki category for ~6–10 cluster summaries per project that link down to the existing ARCHITECTURE/FUNCTIONS/RESEARCH/DIAGRAMS detail layer. Module slugs are bare single-concept kebab identifiers (`scheduling`, not `scheduler-overview`). Updates Rules.md §2 (category table), §5 (slug rules + cross-category collision), §11 (`### Modules` / `### Notes` H3 split in topic-index, ≤100 combined cap), §12 (new trigger 7 row — module-cluster shape), and adds new §13 (1-of-2 same-concept rule for MODULES — tag overlap dropped because parent/child relationships structurally share tags).
- **New `_templates/module.md`** — 7-H2 inner skeleton: Purpose, Boundary, Triggers, Storage, Behavior, Rules & Invariants, Children. Children groups detail-note links by H4 sub-headings (`#### From ARCHITECTURE`, etc.).
- **Curator deletion-test gate (Step 5a)** — every CREATE/EDIT routed to MODULES must satisfy ≥5 of 7 inner H2s with `Purpose` + `Boundary` mandatory. Failures convert to surface-only `SHALLOW-MODULE` rows (no write). Threshold lives in the curator prompt — tunable without amending Rules.md.
- **Curator trigger 7** — module-cluster detection from four deterministic signals (S1 ≥3 wiki-link/basename references; S2 ≥3 of 4 keyword categories — trigger/storage/executor/outcome; S3 ≥2 distinct dominant domain tags; S4 word band 150–1000). Pre-evaluated by `wiki-digest` skill body in bash and emitted as labeled prompt sections (`### Trigger 7 signals: S1=N, S2=…, S3=N, S4=N`) so the curator applies the all-four rule deterministically. Fork fallback path computes signals via Read/Grep when `disableSkillShellExecution: true`.
- **New `SLUG-COLLISION` plan row** — surface-only when a MODULES slug equals an existing basename in another category; user decides whether to rename or merge.
- **`/wiki-modules` slash command** (`.claude/skills/wiki-modules/SKILL.md`) — read-only manual scan that proposes MODULES notes for clusters lacking one (filename-prefix + tag-overlap + link-graph signals) AND audits existing MODULES notes for broken children, deprecated links, unlinked candidates, and scope drift. Emits both sections in one run.
- **Recall agent orienting/narrow query split** — orienting prompts ("what is", "how does", "overview of", "explain") prefer `### Modules` bullets; narrow prompts (specific function, endpoint, error, value) hit `### Notes` directly; mixed-intent returns both.
- **Optional MODULES auto-handle in `inbox-update`** — soft hint that emits `@ MODULES::<slug>` when a turn touches ≥4 ARCHITECTURE/FUNCTIONS notes sharing ≥2 tags AND the user's message reads as synthesis. The curator's trigger 7 still validates; auto-handles that don't earn the route are dropped as `SHALLOW-MODULE`.
- **Topic-index H3 split** — `### Modules` (orientation, `Module: MODULES/<slug>.md` form) above `### Notes` (detail, `Files: PATH1, PATH2` form). The curator's Step 9 performs a one-time additive restructure on the first MODULES write for indexes that predate this rollout.
- **Install scaffolding** — `wiki-install` Block 1 now creates `wiki/MODULES/`; precondition list includes the new `wiki-modules` skill.

### Migration
- **Existing wikis automatically restructure on first MODULES write.** No manual action required — the curator's Step 9 detects the absence of `### Modules` and inserts `### Modules` (empty) and `### Notes` headings around the existing flat bullet list, preserving order. Surfaces a one-line note in the digest summary.
- **Optional pre-migration restructure** — to land the H3 split before any MODULES note is written, manually insert `### Modules\n\n### Notes` headings around the existing bullets in `wiki/topic-index.md` (or copy `wiki/topic-index.seed.md` as a template). Otherwise, the first `/wiki-digest` that creates a MODULES note will do the restructure for you.
- **No content moves.** Children of MODULES notes stay listed in `### Notes` flatly — they are NOT removed when a parent module is added. The MODULES note is purely additive orientation.

## [1.1.0] — 2026-05-01

### Changed
- **Wiki-link contract switched to piped form `[[note-basename|Display Title]]`.** Bare `[[Title]]` is now forbidden because Obsidian's default resolver matches against filenames (kebab-case per Rules.md §5), not H1 titles — bare links to kebab-case files did not resolve and clicking them created blank notes at the vault root. Updates Rules.md §3 + §7, all 7 templates in `wiki/_templates/`, the wiki-curator agent (validation, split-backlink rewrite using slug-keyed grep, post-write audit becomes file-existence check on basename), the wiki-recall agent output format, the wiki-digest audit description, and the install-skill `topic-index.seed.md`.

### Migration
- **Existing wikis must rewrite inbound links from bare to piped form.** Run a deterministic transform: for every `[[X]]` (no pipe) in `wiki/**/*.md`, compute basename = X.lower().replace(' ', '-'); if a file with that basename exists in the wiki, replace with `[[basename|X]]`. Skip code blocks and HTML comments. Audit afterward: every `[[Y|Z]]` must have a matching `wiki/**/<Y>.md`. The new curator's Step 8 audit will surface any remaining bare links as contract violations.

## [1.0.0] — 2026-04-30

### Added
- Initial public release.
- `/wiki-install`, `/wiki-digest`, `/wiki-recall`, `/wiki-update` slash commands.
- Stop hook (`inbox-stop.sh`) — capture path; nudges Claude to update `wiki/inbox/_session.md` after every assistant turn.
- UserPromptSubmit hook (`recall-prompt.sh`) — recall path; injects wiki-recall instruction on planning-intent prompts.
- Brainstorm-fallback every-N-turns capture for design conversations with no code edits (`LCW_BRAINSTORM_TURNS` env var, default 10).
- Distribution manifest (`dist-manifest.txt`) with optional per-line update policy column (`overwrite` default, `keep` for user-owned wiki seeds).
- Version stamping: `/wiki-install` writes upstream `VERSION` to `.claude/llm-code-wiki.version` so `/wiki-update` can compare.

### Migration
- (none — first release)
