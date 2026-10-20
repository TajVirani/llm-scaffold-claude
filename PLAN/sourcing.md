# Sourcing plan for checklist §4

> **Path note (D81, 2026-10-19).** This plan was drafted before target-project workflow data moved under `.workflow/`. Target-side paths named below (`docs/rules.md`, `docs/capabilities.md`, `docs/decisions/`, `docs/cache/`, `profiles/`, `model-map/`, `agent-overrides.yaml`, `specs/`, `deferred/`, `.cache-staging/`) now live at `.workflow/<same path>`, with `docs/rules.md` and `docs/capabilities.md` becoming `.workflow/rules.md` and `.workflow/capabilities.md`. Template source paths under `skills/*/assets/` are scaffold paths and are unaffected.

> Scaffold-only (D30). For every item in `checklist.md` §4, this lists the reference material to build it from, so nothing is invented. It also sets the build conventions every builder must follow, and the batch plan. Drafted 2026-10-15 from:
>
> - `checklist.md` §4, `PLAN/decision-flow-reference.md`, `assetlist.md` (D1–D55) and `PROVENANCE.md`;
> - each stub's header comment, the vendored skills and the local spec-kit plugin;
> - upstream repos (read-only), and an external survey of agent-skill repos. The survey is merged below; its original lived in a temporary scratchpad.

## Conventions used in this file

- **Path shorthand.**
  - `skills/`, `agents/`, `hooks/`: under `.agents/`.
  - `NM-speckit/`: `~/.claude/plugins/cache/claude-night-market/spec-kit/1.3.7/` (local, read-only).
  - `BMAD:`: `github.com/bmad-code-org/BMAD-METHOD` at `main`.
  - `MP:`: `github.com/mattpocock/skills` at `main`.
  - `SK:`: `github.com/github/spec-kit`.
  - External repos in the survey tables: `https://github.com/<repo>/blob/main/<path>`.
- **Coverage.**
  - FULL: the source covers it; adapt it. For scripts and hooks, FULL means the stub plus the decisions fully specify the behaviour (pure engineering).
  - PARTIAL: some parts are ours; the cell says which.
  - NONE: needs an external source, briefed under [Gaps](#gaps-needing-external-sources).
- **Licences** (checked through the GitHub API, 2026-10-15).
  - MP: MIT.
  - BMad: MIT ("Copyright (c) 2025 BMad Code, LLC"); the names and logos are trademarks.
  - SK: MIT.
  - anti-slop (`dmmulroy/anti-slop`): MIT. Its vendored `eslint-stylistic` piece is also MIT, with its own LICENSE.
  - NM (claude-night-market, athola): MIT.
  - FP: first-party, this repo. Plan: `PLAN/` and `assetlist.md`, first-party.
- **Vendored skills are temporary reference only (D10, D77).** Adapt their text into first-party files, credit the source in `PROVENANCE.md` and record the lineage (`derived` or `copy`) in `upstream-lineage.json`. Nothing may call them at runtime; each is deleted once its first-party version exists.

## Build conventions (every builder sub-agent must follow these)

1. **Read before writing.** Before writing anything, read:
   - every source listed for your item, in this file's tables and in the [External candidates](#external-candidates-per-item) table;
   - the stub's header comment.

   Fetch upstream files that are not on disk read-only (raw GitHub URL or WebFetch). If you cannot fetch a listed source, say so in your report rather than guessing its content.
2. **Adapt, never invent.** Every behaviour must trace to the plan (`PLAN/decision-flow-reference.md`, `assetlist.md` D1–D55, the stub) or to a listed source. If something is needed that neither covers, stop and report it as a gap. Do not fill it in.
3. **Licences.** Copy text only from MIT or Apache-2.0 sources. Lifting a pattern or structure needs no notice; copying substantial text does. Never copy from:
   - hesreallyhim/awesome-claude-code (CC BY-NC-ND 4.0; use it for discovery only).
   - anthropics/skills `docx`, `pdf`, `pptx`, `xlsx` (proprietary, "All rights reserved") and `doc-coauthoring` (no LICENSE).
   - Any anthropics/skills or openai/skills skill without an Apache-2.0 `LICENSE.txt`.
   - openai/skills `notion-*` (© Notion Labs).
   - ComposioHQ/awesome-claude-skills and travisvn/awesome-claude-skills (no licence).
   - davila7/claude-code-templates (mixed per-component licences, unclear provenance). Go to the upstream source instead.
   - Any repo with no licence file (all rights reserved by default), or with a proprietary or non-commercial licence.

   BMad: do not use "BMad" or "BMAD-METHOD" in any name, and do not imply endorsement (trademark). BMad skills are Jinja-templated (`render_skill.py`): lift structure and prose from `workflow.md` and `references/`, never the templating.
4. **Attribution.**
   - Copied MIT text (substantial): keep the copyright notice in a `LICENSE` or `NOTICE` file in the skill folder, as `install-anti-slop/assets/anti-slop/vendor/eslint-stylistic/` does.
   - Adapted Apache-2.0 text: keep the NOTICE and attribution, and state that you changed it.
   - Every built file records its sources:
     - skill or agent frontmatter: a `sources:` key, if the format allows it;
     - otherwise: a `Sources:` line in the header comment;
     - scripts: a `# Sources:` comment.
5. **Provenance.** In the same change, record each built item in `PROVENANCE.md` as "first-party, adapted from <repo>/<path> (<licence>)", and flip its status from stub to implemented.
6. **Style.** Match the existing first-party skills.
   - Put frontmatter first.
   - Use progressive disclosure through `modules/` and `assets/` (see `skills/pr-quality/SKILL.md`, `skills/data-structure-audit/`).
   - Write per `skills/writing-for-agents/SKILL.md`: context pointers, completion criteria, positive phrasing.
   - Keep each `SKILL.md` under about 500 lines, with detail in modules or references.
7. **Decisions.** Follow D1–D55. In particular:
   - the launch header is the D37 ```` ```yaml launch-header ```` block;
   - YAML is read with mikefarah `yq` v4 (D38);
   - the post-implementation audit finds its task as D39 says;
   - built workflow skills are model-invocable (D41);
   - anti-slop is fetched at setup time at a pinned commit (D42);
   - Codex enforcement uses `.codex/hooks.json` only for events a live run has verified (D40).
8. **Scripts and hooks.**
   - Use only Bash, `jq` and mikefarah `yq` v4.
   - Start with `#!/usr/bin/env bash` and `set -euo pipefail`. Keep scripts shellcheck-clean when `shellcheck` is available.
   - Follow the hook contract for exit codes and output:
     - PreToolUse emits `hookSpecificOutput.permissionDecision` JSON: allow or deny with a reason, plus `updatedInput` for `pre-launch.sh`.
     - SubagentStop emits `{"decision":"block","reason":…}` to block.
     - Shared scripts exit 0 for allow or clean, and 2 for deny, with the reason on stderr (as in the `check-write.sh` stub).
   - Take worktree-sensitive paths from the payload `cwd` (D18).
   - Test with fixture JSON in the session scratchpad.
9. **Stub markers.** Remove these only when the item is actually implemented, not when it is partly drafted:
   - the `STUB: describes intended contents only. Not implemented.` line;
   - the `STUB (not implemented).` description prefix;
   - for skills, `disable-model-invocation: true`. Built workflow skills are model-invocable (D41), so remove it when you implement the skill (`domain-modeling` is already done).
10. **Checklist.** When the item is implemented, tick its `checklist.md` §4 entry (`[x]`, with a short "Done:" note).
11. **Ownership.** Edit only the files your batch slot owns (see [Build order](#build-order-batches)). If another file needs a change, report it to the coordinator instead of editing it.

## Corrections found while sourcing (all applied in Batch 0)

1. **`agents/module-audit.md`** pointed to the removed `improve-codebase-architecture/LANGUAGE.md`. Fixed: it now points to `skills/codebase-design/SKILL.md` (+ `DEEPENING.md`), and `assetlist.md` is updated too.
2. **`grilling` already batches.** Fixed in `assetlist.md` and the `questioning-loop` stub. Current `grilling` asks the whole frontier per round, with recommended answers and fact sub-agents. Only defer-to-deep-dive, the host question UI and the term and scope gates are ours. The checklist §1 `grill-with-docs` review item still stands.
3. **The wayfinder handoff template no longer exists.** Fixed: `assets/deferred.md`, `modules/deferred-handoff.md` and `assetlist.md` now cite `skills/triage/AGENT-BRIEF.md`, `skills/triage/OUT-OF-SCOPE.md` and `skills/handoff/SKILL.md`. The HITL/AFK tag still comes from wayfinder.
4. **Upstream `domain-modeling` exists and already uses GLOSSARY naming.** Noted in the stub and in both format-file headers. Batch 1C replaces `assets/GLOSSARY-FORMAT.md` and `assets/ADR-FORMAT.md` with fresh copies of `MP:skills/engineering/domain-modeling/{GLOSSARY-FORMAT,ADR-FORMAT}.md`, then adapts the paths (`docs/adr/` → `docs/decisions/adr/`). Not copied yet.
5. **Spec Kit ships no `data-model` template.** Fixed: the `assets/data-model.md` stub and the reference doc's Sources row now point to Phase 1 of `SK:templates/commands/plan.md`. Local copy: `NM-speckit/commands/speckit-plan.md` lines 61–65.
6. **Provenance.** Fixed: `PROVENANCE.md` lists `proof-of-work` and `clear-context` as vendored from claude-night-market (MIT). The checklist §1 item is updated; 5 items remain unverified.
7. **Older names.** Fixed `to-issues` → `to-tickets` in `assetlist.md`. Resolved: the vendored `code-review` was refreshed to upstream mattpocock/skills 3da8c01 (2026-10-07) and has no local customisation.
8. **Launch header syntax.** Decided as D37: a fenced ```` ```yaml launch-header ```` block holding `task_type` plus the D31 fields, parsed with yq. Applied to `assetlist.md`, the reference doc, `claude-settings.template.md`, and every stub that mentions the header (11 agents, the router, the modules, `resolve-launch.sh`, `pre-launch.sh`).
9. **yq flavour.** Decided as D38: mikefarah `yq` v4, reading frontmatter with `--front-matter=extract`. Applied to every stub that mentions yq, and to `install.sh`.
10. **Audit task lookup.** Decided as D39: parse the header from the first user message in `agent_transcript_path`. Applied to the `post-implementation-audit.sh` stub, the reference doc's hooks row and `claude-settings.template.md`.

---

## 4 (pre). Stub guard

| Path | Primary source(s) | Coverage | Licence | Depends on |
| --- | --- | --- | --- | --- |
| `disable-model-invocation: true` on the 5 stub skills (`feature-workflow`, `project-setup`, `regenerate-caches`, `domain-modeling`, `retrospective`) | mattpocock/skills `skills/productivity/writing-for-agents/SKILL-MECHANICS.md` @ 49dd158 (Invocation) | FULL (done in Batch 0) | MP | none; removed per skill when that skill is built |

## 4a. Templates: project-setup (D8)

| Path | Primary source(s) | Coverage | Licence | Depends on |
| --- | --- | --- | --- | --- |
| `skills/project-setup/assets/GLOSSARY.md` | `MP:skills/engineering/domain-modeling/GLOSSARY-FORMAT.md` (heading, Language, Relationships, Flagged ambiguities). The stub says to reference the format rather than copy it: ship a near-empty skeleton. | FULL | MP | 4c `domain-modeling/assets/GLOSSARY-FORMAT.md` (wording must match) |
| `skills/project-setup/assets/docs/rules.md` | Prose sections: `BMAD:skills/bmad-project-context/references/template.md` (Policy, "a prohibition names the alternative", terse imperative lines) and its `references/best-practices.md` (the line test). Section list: reference doc "Persistent files" 00.3. | PARTIAL: the YAML schema for Ownership and Shared core (module → owned paths → allowed deps; shared-core paths) is ours (D15, D20). Shape it to map cleanly onto dependency-cruiser `forbidden` rules (gap G9). | BMad, Plan | It defines the schema `generate-boundary-config.sh` and `resolve-launch`/`integration` read: build it first. |
| `skills/project-setup/assets/docs/capabilities.md` | Entry format from `BMAD:skills/bmad-spec/assets/spec-template.md` (Capabilities: `CAP-n`, intent, success). Fields: reference doc 00.2. | PARTIAL: the index layout (CAP-### → description → introducing spec link) is ours and small. | BMad, Plan | 4b `spec.md` (CAP ID format) |
| `skills/project-setup/assets/docs/decisions/pitfalls.md` | Entry fields: reference doc 00.4 and "Pitfalls: observed failure only". Admission tone: `BMAD:skills/bmad-project-context/references/best-practices.md` (Known pitfalls). | FULL (plan-specified) | Plan, BMad | none |
| `skills/project-setup/assets/profiles/TEMPLATE.md` | The five sections are fixed in reference doc "Work profiles" and 00.16. Line test and "Conventions that differ from defaults" / "Running and verifying": `BMAD:.../bmad-project-context/references/template.md`. TS/JS lint rule naming: `skills/install-anti-slop/SKILL.md` step 3 (rule list). | PARTIAL: the Toolchain YAML keys (`lint`, `typecheck`, `format`, `boundary`, `e2e`; D15) and the extraction-stable headings are ours. | Plan, BMad, anti-slop | It defines the schema `run-toolchain.sh`, `resolve-launch.sh` (checklist slice) and `evidence-capture.sh` read. |
| `skills/project-setup/assets/profiles/examples/test-harness.md` | Test philosophy: `skills/tdd/tests.md`, `skills/tdd/mocking.md`, `skills/tdd/SKILL.md` (seams, anti-patterns). Mocking discipline as a lint rule: anti-slop `no-module-mocking`. | PARTIAL: needs a concrete example stack and commands (gap G2) | MP, anti-slop | `profiles/TEMPLATE.md` |
| `skills/project-setup/assets/profiles/examples/e2e-browser.md` | Nothing in the repo covers browser e2e conventions. | NONE: gap G1 (Playwright conventions: trace, screenshot and video, outputDir, JRN tagging, console and network capture) | — | `profiles/TEMPLATE.md`; `evidence-capture.sh` depends on it |
| `skills/project-setup/assets/model-map/TEMPLATE.md` | Fields and tiers: reference doc 00.11, D12, D23, D35. Claude aliases (`haiku`, `sonnet`, `opus`) are Claude Code built-ins. | PARTIAL: Codex aliases per tier need research (gap G8). | Plan | none (`resolve-launch.sh` reads it) |

## 4b. Templates: feature-workflow and regenerate-caches (D8)

| Path | Primary source(s) | Coverage | Licence | Depends on |
| --- | --- | --- | --- | --- |
| `skills/feature-workflow/assets/spec.md` | Body: `BMAD:skills/bmad-spec/assets/spec-template.md`, an exact match for Why / Capabilities (`CAP-n` intent + success) / Constraints / Non-goals / Success signal, plus optional Assumptions and Open Questions. Frontmatter status states: reference doc "Status" (adapted from BMad). | FULL. The frontmatter fields (`status`, `baseline_revision`, `followup_review_recommended`, `deferred[]`, `blocked_condition`, `light_path`) are listed in the plan; the Links and Known gaps (D29) sections are ours and trivial. | BMad, Plan | It defines the schema `status-transition.sh`, `session-start-resume.sh` and `check-write.sh` read. |
| `skills/feature-workflow/assets/codebase-map.md` | Spine ideas from `skills/design-pattern-doc/TEMPLATE.md` (inventory tables, cite file paths, "Known gaps"). Sections: the stub plus reference doc "Sub-agent task types" (what each agent returns). | PARTIAL: the section-per-agent layout and `cache_stamps` frontmatter are ours | FP, Plan | 4b `cache-frontmatter.md` (stamp format) |
| `skills/feature-workflow/assets/design-log.md` | Round anatomy (question, options, recommendation, verbatim answer, superseded decisions): `skills/grill-with-docs/REFERENCE-DOC.md` (Rounds, Anatomy). Index-not-store discipline: `skills/wayfinder/SKILL.md` ("Decisions so far"). Triage entry fields: `BMAD:skills/bmad-code-review/step-03-triage.md` (id, source, verdict, evidence). | PARTIAL: the entry-shape catalogue (placement, deferral, impact classification, triage, retro notes) is ours | MP, BMad | none |
| `skills/feature-workflow/assets/data-model.md` | `SK:templates/commands/plan.md` Phase 1, locally `NM-speckit/commands/speckit-plan.md` l.61–65: entity, fields, relationships, validation rules, state transitions. Invalid-state framing: `skills/data-structure-audit/references/invalid-states.md`. | PARTIAL: no upstream template file exists (correction 5). The create / extend / refactor / unchanged classification (0.4.4) and migration ordering are ours. | SK (MIT), NM (MIT), FP | none |
| `skills/feature-workflow/assets/verification-plan.md` | Test scenarios: Spec Kit `quickstart.md` role (`NM-speckit/skills/shared/modules/artifact-structure.md`). Testable criteria: `NM-speckit/skills/spec-writing/modules/success-criteria-patterns.md`, `skills/proof-of-work/modules/acceptance-criteria.md`. | PARTIAL: the `JRN-###` journeys, fixtures/oracles and targets sections are ours (plan-specified) | NM, Plan | 4b `spec.md` (CAP links) |
| `skills/feature-workflow/assets/tasks.md` | Slice rules and per-ticket fields: `skills/to-tickets/SKILL.md` (vertical-slice rules, blocking edges, local-ticket template). Phases and dependency ordering: `SK:templates/tasks-template.md`, `NM-speckit/skills/task-planning/modules/{dependency-patterns,phase-structure}.md`. | PARTIAL: the `tasks:` YAML frontmatter schema (`id`, `status`, `work_type`, `depends_on[]`, `touches_core`, `capability`; D15) is ours | MP, SK, NM | It defines the schema `status-transition.sh`, `resolve-launch.sh` and `run-toolchain.sh` read. |
| `skills/feature-workflow/assets/deferred.md` | Durable, behavioural brief with current vs desired behaviour, acceptance and out-of-scope: `skills/triage/AGENT-BRIEF.md`. Concept-per-file and durable reasons: `skills/triage/OUT-OF-SCOPE.md`. "Reference, don't duplicate; redact": `skills/handoff/SKILL.md`. HITL/AFK tag: `skills/wayfinder/SKILL.md` (Ticket Types). | FULL. The frontmatter (`origin_spec`, `created`, `severity`, `superseded_by`) is plan-specified. | MP, Plan | none |
| `skills/feature-workflow/assets/proposals.md` | "Proposed remediation awaiting human application" with owners: `BMAD:skills/bmad-retrospective/references/retro-document.md` (Action items). Mechanical (tool rule) vs judgement (checklist line): `skills/retro/SKILL.md` (Coding standards). | PARTIAL: per-line approval status (`proposed`, `approved`, `modified`, `rejected`) and the "why removing it changes agent behaviour" field are ours (D21) | BMad, MP | none |
| `skills/feature-workflow/assets/report.md` | Evidence-before-claim structure: `skills/proof-of-work/modules/validation-protocols.md`, `.../acceptance-criteria.md`. "Behavior verification" or an explicit note that it was not exercised: `BMAD:.../retro-document.md`. | PARTIAL: the section layout (test output, targets vs measured, journeys → artifacts, D29 gaps) is ours | NM (MIT), BMad | `verification-plan.md` (targets, JRN IDs) |
| `skills/retrospective/assets/retrospective.md` | `BMAD:skills/bmad-retrospective/references/retro-document.md`: frontmatter `verdict`, plus Summary, Findings with disposition, Behavior verification, Previous-retro follow-through, Action items, Acceptance verdict. | FULL. Drop the epic/ticket fields; add pointers to pitfalls.md, design-log.md and model-map/overrides (D35). | BMad | none |
| `skills/regenerate-caches/assets/cache-frontmatter.md` | Fields: reference doc "Persistent files" 00.5–00.7. "Verified <date> against <sha>" stamp idiom: `BMAD:.../bmad-project-context/references/template.md`. Commit anchoring: `skills/data-structure-audit/references/incremental.md`. | PARTIAL: the body shape per cache type and the determinism rules need gap G6 | Plan, BMad, FP | none (it defines the schema `publish-cache.sh` and `cache-stamp-check.sh` read) |

## 4c. Standalone skills

| Path | Primary source(s) | Coverage | Licence | Depends on |
| --- | --- | --- | --- | --- |
| `skills/domain-modeling/SKILL.md` | `MP:skills/engineering/domain-modeling/SKILL.md`: challenge against the glossary, sharpen fuzzy language, scenarios, cross-check with code, update GLOSSARY inline, offer ADRs sparingly (three-part test). Scope it to the term gates and 0.3.7, and add the `status-transition.sh step` call (D16). | FULL | MP | 4d `status-transition.sh` (by name only) |
| `skills/domain-modeling/assets/adr.md` | `ADR-FORMAT.md` Template + Optional sections (Status frontmatter incl. `superseded by ADR-NNNN`) | FULL | MP | `ADR-FORMAT.md` |
| `skills/domain-modeling/assets/GLOSSARY-FORMAT.md`, `ADR-FORMAT.md` | Re-copy from `MP:skills/engineering/domain-modeling/` (already GLOSSARY-named; correction 4). Then change `docs/adr/` → `docs/decisions/adr/` and add superseded marking. | FULL | MP | none |
| `skills/project-setup/SKILL.md` | Anti-slop step: `skills/install-anti-slop/SKILL.md` (fresh-install steps 1–5) with `scripts/install.mjs` and `assets/anti-slop/**`. Bundle them under `project-setup/assets/` (the stub's open choice; bundling keeps it offline and preserves `vendor/eslint-stylistic/LICENSE` and `UPSTREAM.md`). Interactive setup flow: `skills/setup-matt-pocock-skills/SKILL.md`. Human-only steps: `skills/wizard/SKILL.md`. Seeding rules: D12, D23, D26, D35. | PARTIAL: toolchain install for non-TS/JS work types has no source (gap G11); Codex aliases (G8) | anti-slop (MIT, keep LICENSE), MP, Plan | 4a templates; `generate-boundary-config.sh` |
| `skills/project-setup/scripts/generate-boundary-config.sh` | Engineering: yq parse of `rules.md` blocks → adapter. Script style: `skills/data-structure-audit/scripts/audit_scope.sh`. | PARTIAL: dependency-cruiser config format needs its docs (gap G9) | FP | 4a `docs/rules.md` schema |
| `skills/retrospective/SKILL.md` | `BMAD:skills/bmad-retrospective/` (`workflow.md`, `references/{evidence-gathering,acceptance-verdict,team-discussion,retro-document}.md`; `scripts/git_evidence.py` is optional prior art). Improvement categories and "mechanical → tool rule, judgement → checklist": `skills/retro/SKILL.md`. Model-observation routing: D35. | FULL | BMad, MP | `retrospective.md` template; 4d `status-transition.sh` |

## 4d. Helper scripts (D7): pure engineering

All are bash + `jq`/`yq`, specified by their stub headers, the reference doc "Helper scripts" table and the D-numbers. They need no external skill. Shared prior art: `hooks/block-destructive-git.sh` (stdin JSON and `jq`, `set -euo pipefail`) and `skills/data-structure-audit/scripts/audit_scope.sh` (git anchoring, sub-commands).

| Path | Primary source(s) | Coverage | Licence | Depends on |
| --- | --- | --- | --- | --- |
| `skills/feature-workflow/scripts/status-transition.sh` | Stub; reference doc "Status" table (legal transitions); D15, D16, D18 (`git rev-parse --git-common-dir`), D29 | FULL | FP | 4b `spec.md` + `tasks.md` frontmatter schemas; D38 |
| `skills/feature-workflow/scripts/resolve-launch.sh` | Stub; D31 header table; D35 precedence; reference doc "Sub-agent task types" | FULL (implements the D37 header parser) | FP | 4a `model-map/TEMPLATE.md`, `agent-overrides.yaml`, `profiles/TEMPLATE.md` headings; 4b `tasks.md`; 4f agent `models:` frontmatter key name (fixed by D35) |
| `skills/feature-workflow/scripts/run-toolchain.sh` | Stub; D15, D18, D19 | FULL | FP | 4a `profiles/TEMPLATE.md` Toolchain block; 4b `tasks.md` |
| `skills/feature-workflow/scripts/check-write.sh` | Stub; reference doc "Hooks" (allowed steps per path); D16, D17, D18 | FULL | FP | `.step` format (fixed by `status-transition.sh`) |
| `skills/regenerate-caches/scripts/cache-stamp-check.sh` | Stub; `audit_scope.sh` (changed-since-commit logic) | FULL | FP | 4b `cache-frontmatter.md` |
| `skills/regenerate-caches/scripts/publish-cache.sh` | Stub; D17 | FULL (fix the staging dir name, e.g. `.workflow/.cache-staging/`) | FP | 4b `cache-frontmatter.md` |

## 4e. feature-workflow router and phase modules (D3)

| Path | Primary source(s) | Coverage | Licence | Depends on |
| --- | --- | --- | --- | --- |
| `skills/feature-workflow/SKILL.md` | Module frontmatter (`modules:`, `progressive_loading: true`): `skills/pr-quality/SKILL.md`. Router-skill guidance: mattpocock/skills `skills/productivity/writing-for-agents/SKILL-MECHANICS.md` @ 49dd158. Trivial bypass and sizing: `BMAD:skills/bmad-build/step-01-clarify-and-route.md` and `step-oneshot.md` (paths verified, content not yet read). Status routing: reference doc "Status", "Sizing". | FULL | FP, MP, BMad | header syntax (Batch 2); module names only |
| `skills/feature-workflow/modules/discovery.md` | 0.1 numbering and slug: `NM-speckit/commands/speckit-specify.md` l.38–56 (scan specs, branches → N+1, short-name). 0.1.4: BMad spec template. 0.3.20 light-path three facts: BMad build step-01 (and the reference doc). Exploration-agent dispatch style: `skills/design-pattern-doc/SKILL.md` Phases 4–5. | PARTIAL: the orchestration of `cache-stamp-check` → `retrieval`/`library-evaluation` → `cache-regeneration` → `publish-cache`, the placement gate (0.3.3, ours) and the term gates are ours | SK/NM, BMad, FP | 4b templates; 4d scripts; 4f Phase 0 agents (names) |
| `skills/feature-workflow/modules/questioning-loop.md` | `skills/grilling/SKILL.md` (design tree, frontier rounds, numbered questions with recommended answers, "yes accepts", facts via sub-agent without blocking, done when the frontier is empty). Reference doc "The questioning loop". | FULL (correction 2). Ours: the defer-to-deep-dive option (0.3.12–0.3.13), the host multi-question UI (AskUserQuestion), and the term and scope gates. | MP | `deferred-handoff.md`; `domain-modeling` (by name) |
| `skills/feature-workflow/modules/verification-setup.md` | Prove-it-fails discipline: `skills/proof-of-work/modules/iron-law-enforcement.md`. Build a feedback loop that goes red: `skills/diagnosing-bugs/SKILL.md`. Red-first: `skills/tdd/SKILL.md`. Phase 1 text: reference doc. | PARTIAL: the known-bad-build check (1.4) needs a technique (gap G4) | NM, MP | 4a example profiles; header syntax (Phase 1 exception, D14) |
| `skills/feature-workflow/modules/task-breakdown.md` | `skills/to-tickets/SKILL.md` (tracer-bullet slices, blocking edges, expand–contract for wide refactors, quiz the user). Agreed seams (2.3): `skills/to-spec/SKILL.md` step 2 and `skills/tdd/SKILL.md` (Seams). | FULL. It writes `tasks.md` YAML, not tracker tickets. | MP | 4b `tasks.md` |
| `skills/feature-workflow/modules/implementation-orchestrator.md` | Frontier-driven waves, one worktree per implementer, merge between, background launches, context pointers: `skills/implement-spec/SKILL.md`. Execution tracking prior art: `NM-speckit/agents/implementation-executor.md`. | PARTIAL: the four gates (3.5–3.11), 3.13–3.14 suite-gap handling (D29), integration batching per work type (D28) and Codex advisory calls (D9) are ours | MP, NM | 4d `run-toolchain.sh`; 4f coding agents; `deferred-handoff.md` |
| `skills/feature-workflow/modules/review-triage.md` | Parallel independent lenses, no cross-reranking: `skills/code-review/SKILL.md` (steps 4–5, "Why two axes"). Triage: `BMAD:skills/bmad-code-review/step-03-triage.md` (normalize → verify → verdict high, medium, low, false or maybe-false → group by root cause → route `decision_needed`/`patch`/`defer`). Rework ceiling and third pass: reference doc 4.6–4.7 (BMad). | FULL | MP, BMad | 4f review lenses; `deferred-handoff.md` |
| `skills/feature-workflow/modules/sign-off.md` | Report discipline: `skills/proof-of-work/SKILL.md` (Iron Law). Present step: `BMAD:skills/bmad-build/step-05-present.md` (path verified, not read). Proposals: see `proposals.md`. | PARTIAL: line-by-line 5.3 approval, applying approved Tier A writes with step markers, and the Codex boundary regeneration are ours | NM, BMad | 4b `proposals.md`, `report.md`; 4c `retrospective` |
| `skills/feature-workflow/modules/deferred-handoff.md` | Same sources as `deferred.md` (AGENT-BRIEF, OUT-OF-SCOPE incl. "concept match → surface prior decision", handoff). Archive step is plan-specified (00.9). | FULL | MP, Plan | 4b `deferred.md` |

## 4f. Agents (D1)

Every agent also takes the D31 header and `models:` frontmatter (D35) from the stubs. Prompt-writing style: `skills/writing-for-agents/SKILL.md`. Return-format discipline (word cap, file:line, implemented / stubbed / missing): `skills/design-pattern-doc/SKILL.md` Phase 5.

| Path | Primary source(s) | Coverage | Licence | Depends on |
| --- | --- | --- | --- | --- |
| `agents/retrieval.md` | Exploration-agent brief: `skills/design-pattern-doc/SKILL.md` Phase 5; exploration notes for implementers: `skills/implement-spec/SKILL.md` step 2. Shelf match by concept: `skills/triage/OUT-OF-SCOPE.md` ("When to check"). | PARTIAL: the extract-with-source-path contract and stamp reporting are ours | FP, MP | 4b `codebase-map.md`, `cache-frontmatter.md` |
| `agents/library-evaluation.md` | Only a method exists: `skills/research/SKILL.md` (primary sources, cite every claim). `skills/deps-audit/SKILL.md` audits existing bun deps, not new options. | NONE: gap G5 (survey: now PARTIAL, see External candidates) | MP | 4b `codebase-map.md`; 4a `rules.md` external-systems section |
| `agents/cache-regeneration.md` | Exploration and ground-truth doc: `skills/design-pattern-doc/SKILL.md` + `TEMPLATE.md`. Mermaid generation and validation: `skills/visual-change-report/` (`references/visual-library.md`, `scripts/validate_mermaid.mjs`). | PARTIAL: deterministic output per scope and commit has no source (gap G6) | FP | 4b `cache-frontmatter.md`; 4d `publish-cache.sh` |
| `agents/fact-lookup.md` | "Facts are your job" + sub-agent dispatch: `skills/grilling/SKILL.md`. Primary-source citing: `skills/research/SKILL.md`. Return contract: reference doc. | FULL | MP | none |
| `agents/module-audit.md` | `skills/codebase-design/SKILL.md` (module, interface, depth, seam, adapter; deletion test) + `DEEPENING.md`. Friction questions: `skills/improve-codebase-architecture/SKILL.md` step 1. Fix the stub pointer (correction 1). | FULL | MP | 4b `codebase-map.md` |
| `agents/implementation.md` | TDD method inlined (D10): `skills/tdd/SKILL.md`, `tests.md`, `mocking.md`. Worktree behaviour: `skills/implement-spec/SKILL.md` step 4. "Run typecheck and single tests regularly": `skills/implement/SKILL.md`. | FULL. Ours: profile obedience and the "profile is wrong → stop" report. | MP | 4a `profiles/TEMPLATE.md` (what it receives); header syntax |
| `agents/integration.md` | Merger-subagent role: `skills/implement-spec/SKILL.md` step 5. Expand–contract for core changes: `skills/to-tickets/SKILL.md`. | PARTIAL: shared-core conformance to `rules.md` and the one-work-type batch contract (D28) are ours | MP | 4a `rules.md` Shared core schema |
| `agents/profile-mini-review.md` | Checklist-only sub-reviewer pattern: `skills/pr-quality/modules/seam-conformance.md`, `doc-conformance.md`. Hard vs judgement, skip what tooling enforces: `skills/code-review/SKILL.md` (Standards brief). | PARTIAL: the "only checklist items, never re-derive tool output" contract is ours | FP, MP | 4a `profiles/TEMPLATE.md` (checklist heading); 4d `run-toolchain.sh` output path |
| `agents/review-standards.md` | `skills/code-review/SKILL.md`: standards-source discovery, Fowler smell baseline (12 smells), Standards sub-agent brief | FULL. Ours: extra baselines (rules, profiles, placement ADR, GLOSSARY naming, 3.5 tool output). | MP | 4a `rules.md`, `profiles/TEMPLATE.md`; 4c `adr.md` |
| `agents/review-end-state.md` | `skills/code-review/SKILL.md` Spec brief (missing / scope creep / wrong; quote the spec line). Evidence-checked gap finding: `BMAD:skills/bmad-code-review/review-prompts/verification-gap.md`. | FULL | MP, BMad | 4b `spec.md`, `verification-plan.md` |
| `agents/review-targets.md` | Nothing measures a running build against thresholds | NONE: gap G3 | — | 4b `verification-plan.md` (targets section) |

## 4g. Hooks (D6): pure engineering

All are thin Claude adapters. The sources are `PLAN/hook-verification.md` (verified payloads, `updatedInput`, deny-wins, `agent_id`, worktree `cwd`, SubagentStop block), the working probe scripts in `PLAN/hook-verification/hooks/` (`pre_agent_rewrite.sh` is a near-template for `pre-launch.sh`; `subagent_stop.sh` for the audit; `pre_write_deny.sh` for the guards), `hooks/block-destructive-git.sh` (deny JSON) and `hooks/claude-settings.template.md` (wiring, timeouts). They need no external skill.

| Path | Primary source(s) | Coverage | Licence | Depends on |
| --- | --- | --- | --- | --- |
| `hooks/pre-launch.sh` | `PLAN/hook-verification/hooks/pre_agent_rewrite.sh` (full `tool_input` rewrite), T5, D33 | FULL | FP | 4d `resolve-launch.sh` |
| `resolve-launch.sh` precedence (D35) | Stub + D35 (built inside 4d `resolve-launch.sh`) | FULL | FP | same file as 4d: one owner |
| `skills/project-setup/assets/agent-overrides.yaml` | Existing stub comment is already the full content; remove the STUB line | FULL | FP | none |
| D31 header table in `resolve-launch.sh` + check in `pre-launch.sh` | Reference doc table; D14 (Phase 1), bulk `cache-regeneration` | FULL (header syntax fixed by D37) | FP | 4d `resolve-launch.sh` |
| `hooks/post-implementation-audit.sh` | `PLAN/hook-verification/hooks/subagent_stop.sh` (block + reason; check `stop_hook_active`), T3, D19 | FULL. Task lookup decided by D39: parse the D37 header from the first user message in `agent_transcript_path`. | FP | 4d `run-toolchain.sh` |
| `hooks/spec-single-writer-guard.sh` | `pre_write_deny.sh`, T6, D16 | FULL | FP | 4d `check-write.sh` |
| `hooks/tier-a-write-guard.sh` | same | FULL | FP | 4d `check-write.sh` |
| `hooks/tier-b-write-guard.sh` | same | FULL | FP | 4d `check-write.sh` |
| `hooks/rules-boundary-config-sync.sh` | PostToolUse payload; D20 | FULL | FP | 4c `generate-boundary-config.sh` |
| `hooks/evidence-capture.sh` | PostToolUse(Bash) payload; D15 | PARTIAL: needs the e2e runner's output layout (gap G1) | FP | 4a `e2e-browser.md` (`e2e` command, output paths) |
| `hooks/session-start-resume.sh` | SessionStart payload (`source`); `additionalContext` output; D22 | FULL | FP | 4b `spec.md` frontmatter |

## 4h. Cache regeneration (D4)

| Path | Primary source(s) | Coverage | Licence | Depends on |
| --- | --- | --- | --- | --- |
| `skills/regenerate-caches/SKILL.md` | Orchestration per scope and type: stub + D17. Parallel-slice dispatch: `skills/design-pattern-doc/SKILL.md` Phases 4–5. Stale-only mode: `cache-stamp-check.sh`. | PARTIAL: depends on the determinism answer (gap G6) | FP | 4f `cache-regeneration`; 4d cache scripts; 4b `cache-frontmatter.md` |

## 4i. Install, host shims, dependencies

| Path | Primary source(s) | Coverage | Licence | Depends on |
| --- | --- | --- | --- | --- |
| `install.sh` | Stub goals; merge rules in `hooks/claude-settings.template.md` ("Merge rules for install.sh"); D11, D16, D17, D30, D36. Pure engineering (bash + jq). | FULL | FP | 4d `publish-cache.sh` (staging dir name for `.gitignore`); Codex shim for `--host codex` |
| `.codex/` shim | `.codex/README.md` (TODOs now filled from the survey's Codex facts; see [Codex layout](#codex-cli-project-layout)). Converters: EveryInc `src/converters/claude-to-codex.ts`; spec-kit `src/specify_cli/integrations/codex/`. | PARTIAL (was NONE): layout known; hook rewrite/block semantics and path denies still need a live test (G7 remainder) | MIT (both converters) | all scripts (advisory calls); 4f agent definitions (md → toml) |
| `yq` as a declared dependency (README requirements, `install.sh`, `project-setup` checks) | D15, D38 | FULL (flavour fixed: mikefarah v4, D38) | FP | none |

---


## Counts

"After survey" re-grades the items for which the external survey (below) supplies a source.

| Subsection | FULL | PARTIAL | NONE | Total | After survey |
| --- | --- | --- | --- | --- | --- |
| 4 pre (stub guard) | 1 | 0 | 0 | 1 | done in Batch 0 |
| 4a templates: project-setup | 2 | 5 | 1 | 8 | unchanged (`e2e-browser` still NONE, G1) |
| 4b templates: feature-workflow etc. | 3 | 8 | 0 | 11 | unchanged; `cache-frontmatter.md` gains gsd-core and humanlayer stamp prior art |
| 4c standalone skills | 4 | 2 | 0 | 6 | unchanged; `project-setup` gains conductor and claude-automation-recommender prior art |
| 4d helper scripts | 6 | 0 | 0 | 6 | unchanged |
| 4e router + modules | 5 | 4 | 0 | 9 | unchanged; stronger sources for the orchestrator and sign-off |
| 4f agents | 5 | 4 | 2 | 11 | `library-evaluation` NONE → PARTIAL; `review-targets` stays NONE |
| 4g hooks | 10 | 1 | 0 | 11 | unchanged |
| 4h regenerate-caches | 0 | 1 | 0 | 1 | unchanged |
| 4i install/shims/deps | 2 | 0 | 1 | 3 | `.codex/` shim NONE → PARTIAL; yq FULL (D38) |
| **Total** | **38** | **25** | **4** | **67** | **38 FULL / 27 PARTIAL / 2 NONE** |

Two items remain NONE: the `e2e-browser` example profile (G1) and the `review-targets` agent (G3). Most PARTIALs need no external source. The missing part is our own design, and the plan already specifies it.

## External candidates per item

These are the best external candidates from the survey for every PARTIAL and NONE item. Use them alongside the in-repo sources in the tables above. Where an in-repo source is listed as FULL, it stays the primary source. URLs follow `https://github.com/<repo>/blob/main/<path>`. The licence is in brackets.

| Item | Best external candidate(s) | Use for |
| --- | --- | --- |
| 4a `docs/rules.md` | BMad `skills/bmad-project-context/references/{template,best-practices}.md` [MIT] | Policy prose, "a prohibition names the alternative", the line test (already listed) |
| 4a `docs/capabilities.md` | BMad `skills/bmad-spec/assets/spec-template.md` [MIT] | CAP entry format (already listed) |
| 4a `profiles/TEMPLATE.md` | ECC `manifests/install-profiles.json` [MIT]; wshobson `plugins/conductor/templates/` [Apache-2.0] | Profile and toolchain shape, style-guide sections |
| 4a `test-harness.md` | obra/superpowers `skills/test-driven-development/SKILL.md` [MIT] | Test conventions; the concrete stack is still G2 |
| 4a `e2e-browser.md` | None in the survey | G1 |
| 4a `model-map/TEMPLATE.md` | Codex config reference (`default_subagent_model`, the agent `model` key) | Codex side; aliases are still G8 |
| 4b `codebase-map.md` | humanlayer `.claude/commands/research_codebase.md` [Apache-2.0] (`git_commit` frontmatter, "document as-is") | Stamp and extract discipline |
| 4b `design-log.md` | obra/superpowers `skills/subagent-driven-development/SKILL.md` [MIT] (a ledger that survives compaction; rulings); EveryInc `skills/ce-plan/` `settled-decisions.md` [MIT] | Shape of an append-only decision ledger |
| 4b `data-model.md` | `SK:templates/commands/plan.md` Phase 1 [MIT] | Already listed; no further candidate |
| 4b `verification-plan.md` | open-gsd/gsd-core `agents/gsd-planner.md` [MIT] ("Nyquist rule": every verify step has an automated check) | Mapping journeys to checks |
| 4b `tasks.md` | open-gsd/gsd-core `agents/gsd-planner.md` [MIT] (dependency waves, `wave:` frontmatter); obra/superpowers `skills/writing-plans/SKILL.md` [MIT] (task right-sizing); `SK:templates/tasks-template.md` `[P]` markers [MIT] | Waves and sizing in the YAML schema |
| 4b `proposals.md` | EveryInc `skills/ce-compound/SKILL.md` [MIT] ("durable bar": write only lessons that cannot be recovered otherwise) | The "why removing it changes behaviour" field |
| 4b `report.md` | anthropics/claude-plugins-official `plugins/feature-dev/commands/feature-dev.md` [Apache-2.0] (summary phase) | Light structure only |
| 4b `cache-frontmatter.md` | open-gsd/gsd-core `agents/gsd-codebase-mapper.md` + `bin/lib/drift.cjs` [MIT] (`last_mapped_commit` stamp, drift detection); humanlayer `research_codebase.md` [Apache-2.0] (`git_commit`, `last_updated`) | Stamp fields and drift check; body determinism is still G6 |
| 4c `project-setup/SKILL.md` | wshobson `plugins/conductor/commands/setup.md` [Apache-2.0] (interactive Q&A, `--resume`, state); anthropics/claude-plugins-official `plugins/claude-code-setup/skills/claude-automation-recommender/` [Apache-2.0]; EveryInc `skills/ce-setup/` [MIT] | Interview and resume flow; non-TS toolchains are still G11 |
| 4c `generate-boundary-config.sh` | None in the survey | G9 (dependency-cruiser docs) |
| 4c `domain-modeling` (all) | EveryInc `skills/ce-compound/references/concepts-vocabulary.md` + `CONCEPTS.md` [MIT] (glossary mutations: add, refine, fold, retire, delete); wshobson `plugins/documentation-generation/skills/architecture-decision-records/SKILL.md` [MIT] (status lifecycle, superseding) | Supersede and retire rules that the MP source lacks. Prefer MP over ECC `context-and-decisions`, which resembles Pocock's approach without attribution. |
| 4c `retrospective/SKILL.md` | EveryInc `skills/ce-compound/SKILL.md` [MIT] (the lessons half); wshobson `plugins/incident-response/skills/postmortem-writing/SKILL.md` [MIT] (facilitation) | Secondary to the BMad retrospective |
| 4e `discovery.md` | anthropics/claude-plugins-official `plugins/feature-dev/commands/feature-dev.md` [Apache-2.0] (discovery, parallel explorers, wait for answers) | Phase skeleton |
| 4e `feature-workflow/SKILL.md` | BMad `skills/bmad-build/` step files [MIT] (router with oneshot, standard and full sizing; resumes from status `draft → ready-for-dev → in-progress → in-review → done` via EARLY EXIT jumps) | The closest structural match: the status in frontmatter selects the step file |
| 4e `verification-setup.md` | open-gsd/gsd-core `agents/gsd-planner.md` [MIT] (Nyquist rule) | Every journey gets an automated check; the known-bad build is still G4 |
| 4e `implementation-orchestrator.md` | obra/superpowers `skills/subagent-driven-development/SKILL.md` [MIT] (implementer per task, review loop capped at 5 rounds, pre-flight table of shared files, ledger); open-gsd/gsd-core `agents/gsd-planner.md` [MIT] (waves); obra/superpowers `skills/using-git-worktrees/SKILL.md` [MIT] | Waves, worktrees, the cap on the fix loop |
| 4e `sign-off.md` | BMad `skills/bmad-build/step-05-present.md` [MIT]; EveryInc `skills/ce-work/` residual-work gate [MIT] | Present step, residual-work check |
| 4f `retrieval.md` | humanlayer `.claude/agents/codebase-locator.md`, `thoughts-analyzer.md` [Apache-2.0] (tight tool scoping; return only what matters) | The extract-only contract |
| 4f `library-evaluation.md` | EveryInc `skills/ce-pov/SKILL.md` + `skills/ce-plan/references/agents/framework-docs-researcher.md`, `best-practices-researcher.md` [MIT] (a graded verdict on adoption, grounded in project constraints; verified against docs); ECC `.codex/agents/docs-researcher.toml` [MIT] | Closes G5. The item is now PARTIAL: the rubric fields (licence, cost, fit) are still ours. |
| 4f `cache-regeneration.md` | open-gsd/gsd-core `agents/gsd-codebase-mapper.md` + `workflows/map-codebase.md` [MIT] (parallel mappers write straight to disk and return only a confirmation; stamp per doc; secret scan) | Agent shape; determinism is still G6 |
| 4f `fact-lookup.md` | humanlayer `.claude/agents/codebase-analyzer.md` [Apache-2.0] (file:line references, no critique) | Return format |
| 4f `module-audit.md` | humanlayer `codebase-pattern-finder.md` [Apache-2.0]; EveryInc `skills/ce-plan/references/agents/repo-research-analyst.md` [MIT] | Finding reuse and existing patterns |
| 4f `implementation.md` | obra/superpowers `skills/subagent-driven-development/implementer-prompt.md` [MIT] (ask questions first, TDD, self-review, "You do not dispatch subagents"); EveryInc `skills/ce-work/references/agents/implementation-worker.md` + `implementation-result-schema.json` [MIT] (status completed, blocked or scope_expansion; audit the git delta) | `blocked` maps to "profile is wrong → stop" |
| 4f `integration.md` | wshobson `plugins/agent-teams/skills/parallel-feature-development/SKILL.md` [MIT] (file ownership, interface contracts); open-gsd/gsd-core `agents/gsd-integration-checker.md` [MIT] (checks wiring across batches); the superpowers pre-flight table of shared files [MIT] | Ownership of shared core and the post-batch check |
| 4f `profile-mini-review.md` | VoltAgent `categories/04-quality-security/surgeon-reviewer.md` [MIT] (71 lines; reports only issues that survive "what goes wrong, for whom"; forbids anything a linter catches) | The "only what no tool can express" contract |
| 4f `review-standards.md` | EveryInc `skills/ce-code-review/references/personas/project-standards-reviewer.md` [MIT] (every finding cites a rule; invents none); anthropics/claude-plugins-official `plugins/code-review/commands/code-review.md` [Apache-2.0] (confidence cutoff, false-positive list) | Rule citation; false-positive list |
| 4f `review-end-state.md` | obra/superpowers `skills/subagent-driven-development/task-reviewer-prompt.md` [MIT] ("nothing more, nothing less") | Wording for spec compliance |
| 4f `review-targets.md` | EveryInc `.../personas/performance-reviewer.md` [MIT] (static review only) | Not a measurement agent; G3 stays open |
| 4g `evidence-capture.sh` | None in the survey | G1 |
| 4h `regenerate-caches/SKILL.md` | gsd-core `workflows/map-codebase.md` [MIT] | Orchestrating parallel mappers |
| 4i `install.sh` | spec-kit `src/specify_cli/integrations/{base,manifest,installer}.py` [MIT] (install manifests for safe upgrade and uninstall); ECC `install.sh` + `manifests/` [MIT] | The manifest idea for the version stamp; Codex wiring |
| 4i `.codex/` shim | spec-kit `src/specify_cli/integrations/codex/__init__.py` [MIT]; EveryInc `src/converters/claude-to-codex.ts` [MIT]; obra/superpowers `skills/using-superpowers/references/codex-tools.md` [MIT] | Converting agent definitions from md to toml; hook config |
| Deferred items (4b `deferred.md`, `deferred-handoff.md`) | EveryInc `skills/ce-work/references/tracker-defer.md` [MIT] (returns `{filed, failed, no_sink}` so nothing is lost); gsd-core `agents/gsd-executor.md` "SCOPE BOUNDARY" + `deferred-items.md` [MIT]; gsd-core `.out-of-scope/` [MIT] | Optional: a return contract under which nothing is dropped silently |

## External survey (summary)

The survey ran on 2026-10-15. It used the GitHub REST API (stars, licence, push date), shallow read-only clones, and the official Codex docs. [V] means verified (API, a file read, or official docs). [I] means inferred.

### Ranked repositories

| # | Repo | Licence [V] | Specialty | Notes |
| --- | --- | --- | --- | --- |
| 1 | [EveryInc/compound-engineering-plugin](https://github.com/EveryInc/compound-engineering-plugin) | MIT | Plan → work → review → compound loop; deferral, vocabulary (CONCEPTS.md), reviewer personas, a Claude → Codex converter | Large and opinionated: lift patterns, not files |
| 2 | [obra/superpowers](https://github.com/obra/superpowers) | MIT | Subagent-driven development: implementer per task, task review, worktrees, TDD, plans | The de facto standard. One skills tree with thin per-host manifests, which matches our `.agents/` + shim design |
| 3 | [github/spec-kit](https://github.com/github/spec-kit) | MIT | Spec → plan → tasks → implement; the best multi-host installer (about 40 hosts, Codex included) | Maintained by GitHub |
| 4 | [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD) | MIT for code; **trademarks excluded** | Retrospective, project-context, build router, code-review triage | Skills are rendered through Jinja: use the prose only |
| 5 | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | Apache-2.0 (per plugin) | `feature-dev`, `code-review`, `claude-code-setup` | High trust; short prompts |
| 6 | [open-gsd/gsd-core](https://github.com/open-gsd/gsd-core) (successor of the archived gsd-build/get-shit-done) | MIT | Codebase mapper with `last_mapped_commit`, wave planner, executor with `deferred-items.md`, integration checker, `.out-of-scope/` | Files were read in the archived copy; the gsd-core paths are confirmed by HTTP 200 |
| 7 | [wshobson/agents](https://github.com/wshobson/agents) | MIT; the `conductor` plugin is Apache-2.0 | `agent-teams`, ADR, postmortem, `conductor` setup | Mixed quality; the skills are better than the agents; some plugins have third-party authors |
| 8 | [affaan-m/ECC](https://github.com/affaan-m/ECC) | MIT | Manifest-driven multi-host installer, `.codex/` config | Its Codex `max_depth` key is undocumented: check it against the docs |
| 9 | [anthropics/skills](https://github.com/anthropics/skills) | No repo licence. Per skill: mostly Apache-2.0; docx, pdf, pptx and xlsx are proprietary | Agent Skills spec, `skill-creator` | Authoritative for the SKILL.md format |
| 10 | [humanlayer/humanlayer](https://github.com/humanlayer/humanlayer) | Apache-2.0 | Research agent trio, `research_codebase` with `git_commit` frontmatter, handoff | The code is deprecated, but the prompts are still good |
| 11 | [Yeachan-Heo/oh-my-claudecode](https://github.com/Yeachan-Heo/oh-my-claudecode) | MIT | `deepinit` (hierarchical AGENTS.md), setup | Secondary |
| 12 | [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) | MIT | About 130 subagent files | Mostly generic personas; `surgeon-reviewer` is good |
| 13 | [davila7/claude-code-templates](https://github.com/davila7/claude-code-templates) | MIT repo, mixed per component | Aggregator | Do not copy from here |
| 14 | [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | **CC BY-NC-ND 4.0** | Link list | Discovery only |
| 15 | [mattpocock/skills](https://github.com/mattpocock/skills) | MIT | Was vendored; the copies were deleted (D78) and are cited upstream at the commits in `upstream-lineage.json` | — |
| – | [vercel-labs/skills](https://github.com/vercel-labs/skills) | MIT | `npx skills add` cross-agent installer | A possible distribution channel |
| – | [openai/skills](https://github.com/openai/skills) | No repo licence; per skill | Codex skill examples (`agents/openai.yaml`) | Check each `LICENSE.txt` |

### Licence cautions

The do-not-copy list is item 3 of the [Build conventions](#build-conventions-every-builder-sub-agent-must-follow-these). Also:

- **Apache-2.0 sources** (claude-plugins-official, humanlayer, wshobson `conductor`): when you adapt text, keep the NOTICE and attribution and state that you changed it.
- **MIT sources**: keep the copyright notice, but only when you copy substantial text.
- **wshobson third-party plugins** (`ship-mate`, `operating-kit`): MIT, but credit their own authors.
- **ECC `context-and-decisions`**: it resembles Pocock's CONTEXT.md approach without attribution, so prefer the MP original.

### Codex CLI project layout

These facts come from the official docs, fetched 2026-10-15. `developers.openai.com/codex/*` now redirects (308) to `learn.chatgpt.com/docs/*`. The fetch summarised the content, so re-check the exact wording before quoting it. The same facts are mirrored into `.codex/README.md`.

- **Skills** ([codex/skills](https://developers.openai.com/codex/skills)) [V].
  - Discovered natively, with no config, in: `$CWD/.agents/skills`; each parent `.agents/skills` up to `$REPO_ROOT`; `$HOME/.agents/skills`; `/etc/codex/skills`; and bundled system skills.
  - Symlinked skill folders are followed. Duplicate names are not merged.
  - `SKILL.md` needs `name` and `description`. Optional: `scripts/`, `references/`, `assets/`, and `agents/openai.yaml` (`policy.allow_implicit_invocation`, default true).
  - Invoked with `/skills`, `$skill-name`, or implicitly.
  - **So `.agents/skills/` needs no Codex shim.**
- **Custom prompts** ([codex/custom-prompts](https://developers.openai.com/codex/custom-prompts)) [V]: deprecated, and user-level only. Ship everything as skills, which D27 already does.
- **Custom agents** ([codex/subagents](https://developers.openai.com/codex/subagents) and the config reference) [V].
  - Project agents live in **`.codex/agents/<name>.toml`**, one agent per file.
  - Required keys: `name`, `description`, `developer_instructions`. Optional: `model`, `model_reasoning_effort`, `model_reasoning_summary`, `model_verbosity`.
  - Alternative registration: `[agents.<name>] config_file = "…"` in `config.toml`.
  - Subagents inherit the parent's sandbox and approval settings. Built-in agents: `default`, `worker`, `explorer`.
  - Spawned through `spawn_agent` (`features.multi_agent`, on by default). No `max_depth` key is documented.
  - **So `install.sh` generates `.codex/agents/*.toml` from `.agents/agents/*.md`, and can write the D35-resolved Codex model into `model`.**
- **Hooks** ([codex/hooks](https://developers.openai.com/codex/hooks)) [V facts, I portability].
  - Config lives in `<repo>/.codex/hooks.json` or inline as `[hooks]` in `.codex/config.toml`, not both in one layer. Layers load additively.
  - **Project hooks load only when the project `.codex/` layer is trusted.** Each hook must also be reviewed with `/hooks`, and trust is pinned to the hook's hash.
  - Events: `PreToolUse`, `PermissionRequest`, `PostToolUse`, `PreCompact`, `PostCompact`, `UserPromptSubmit`, `SubagentStart`, `SubagentStop`, `Stop`, `SessionStart`, `SessionEnd`, `Interrupt`.
  - Matchers are regexes; `apply_patch` matches `Edit` or `Write`.
  - Input is JSON on stdin (`session_id`, `transcript_path`, `cwd`, `hook_event_name`, `model`, …).
  - Deny via `hookSpecificOutput.permissionDecision: "deny"`, or exit 2 with the reason on stderr. Default timeout 600 s.
  - Admins can force `allow_managed_hooks_only`.
  - **So most of our Claude adapters can be wired for Codex too.** That narrows D9's "advisory" scope, but needs a live test before we rely on it.
- **AGENTS.md** ([codex/guides/agents-md](https://developers.openai.com/codex/guides/agents-md)) [V]: read natively from the project root down to cwd, one file per directory (`AGENTS.override.md` first), with a 32 KiB default cap. `CLAUDE.md` is not read.
- **Plugins** [V/I]: bundle skills, MCP servers and hooks, but not agents. The official page gives no manifest path; third parties use `.codex-plugin/plugin.json`.
- **Still unknown:**
  - whether Codex PreToolUse on `spawn_agent` can rewrite the launch (an equivalent of `updatedInput`);
  - whether SubagentStop can block with feedback and exposes a subagent transcript;
  - the exact payload field names;
  - a per-path write deny;
  - the current model aliases (G8).

## Gaps needing external sources

This is the status after the survey. Each open gap is a search brief: prefer primary sources (official docs through context7, upstream repos) and MIT or Apache-2.0 material.

| Gap | Feeds | Status after survey | Best candidate / next step |
| --- | --- | --- | --- |
| G1 Browser e2e conventions | `e2e-browser.md` (NONE), `evidence-capture.sh` | **Open** (the survey did not cover it) | Playwright Test docs via context7: `use.{trace,screenshot,video}`, `outputDir`, JSON and HTML reporters, journey tags (`@JRN-001`, `--grep`), `page.on('console')`, `recordHar`. Prior art: Playwright's test agents (planner, generator, healer; microsoft/playwright, Apache-2.0) |
| G2 Concrete test-harness stack | `test-harness.md` | **Stack decided (D26 amendment)**; docs lookup remains | Vitest (+ `coverage.thresholds`), `tsc --noEmit`, oxlint + anti-slop, oxfmt or Prettier `--check`, `depcruise`; docs via context7 |
| G3 Measurement-only review agent | `review-targets` (NONE) | **Open.** The survey found only static review (EveryInc `performance-reviewer.md`) | Lighthouse CI assertions and budgets, k6 or autocannon thresholds, coverage reporters. Needed: a fixed output table (target, command, measured, pass/fail, raw output path) and a "not measurable: reason" rule |
| G4 Known-bad-build technique | `verification-setup` 1.4 | **Open** | StrykerJS scoped to the changed module, mutmut, or a documented revert-or-inject-fault protocol. The gsd-core "Nyquist rule" only helps make sure every check exists |
| G5 Library evaluation rubric | `library-evaluation` | **Closed (sourced)** | EveryInc `ce-pov`, `framework-docs-researcher`, `best-practices-researcher` [MIT]; ECC `docs-researcher.toml` [MIT]. Licence and maintenance signals (OpenSSF Scorecard, deps.dev) are optional |
| G6 Deterministic caches | `cache-regeneration`, `cache-frontmatter.md` bodies, `regenerate-caches` | **Partly closed.** Agent shape and stamping come from the gsd-core codebase-mapper (`last_mapped_commit`, writes to disk, returns a confirmation only) and humanlayer `research_codebase` | Still open: determinism. Generate `architecture.md` with dependency-cruiser `--output-type mermaid` or `--output-type dot`, which is deterministic. Write canonicalisation rules for the agent-written `modules.md` and `flows.md`. Validate Mermaid with `skills/visual-change-report/scripts/validate_mermaid.mjs` |
| G7 Codex host shim | `.codex/` | **Mostly closed.** Skills are read natively from `.agents/skills`; agents go in `.codex/agents/*.toml`; hooks go in `.codex/hooks.json` (trust required) | Remaining: a live test, like `PLAN/hook-verification/`, of a PreToolUse rewrite on `spawn_agent`, SubagentStop blocking and its transcript, and the payload fields. Also find a path-deny equivalent in the sandbox or approval config |
| G8 Codex model aliases per tier | `model-map/TEMPLATE.md`, `project-setup`, the generated `.codex/agents/*.toml` | **Open** (the survey had no model list) | The current Codex model list from the official models and config docs. Aliases only (D23) |
| G9 dependency-cruiser config format | `generate-boundary-config.sh`, `rules.md` schema | **Open** (a docs lookup; low risk) | dependency-cruiser docs via context7: `forbidden` rules (`from.path`, `to.path`, `pathNot`, `$1` groups), `options.tsConfig`, `--config` |
| G10 yq flavour | all scripts | **Closed by D38** | mikefarah yq v4 |
| G11 Non-TS/JS toolchains | `project-setup` | **Open, deferred** (out of v1 unless a project needs it) | For example, ruff + mypy + import-linter for Python (`[importlinter]` contracts map onto the `rules.md` YAML) |

## Build order (batches)

**Rules.**

- Each batch can be built independently by parallel sub-agents.
- Each sub-agent owns only the files listed for its slot. No file is owned twice, except where a later slot is limited to a named placeholder.
- A batch starts once the batches it depends on are merged.
- Contracts (schemas) come first, because scripts, hooks and agents parse them. Lowest risk goes first.
- Every builder follows the [Build conventions](#build-conventions-every-builder-sub-agent-must-follow-these).

**Pure engineering.** These items need no external skill; their sources are the stubs, `PLAN/hook-verification.md`, the probe hooks and the D-numbers:

- all 4d scripts and all 4g hooks;
- `generate-boundary-config.sh` (plus the G9 docs);
- `install.sh` and `agent-overrides.yaml`;
- the `cache-frontmatter.md` field list;
- `model-map/TEMPLATE.md` (plus G8);
- wiring `yq` in as a dependency.

**Network access.** The builders in slots 1B, 1C, and Batches 4 and 5 fetch upstream sources (raw GitHub URLs) read-only. Grant WebFetch or curl to those slots.

### Batch 0: decisions and guard (done)

- D37 (launch header), D38 (mikefarah yq v4) and D39 (audit task lookup) are recorded in `assetlist.md`. They are applied to the reference doc, `claude-settings.template.md` and every affected stub.
- `disable-model-invocation: true` is added to the 5 stub skills, and the checklist §4 item is ticked.
- Corrections 1–10 are applied (see above).
- `.codex/README.md` TODOs are filled from the survey.
- `PROVENANCE.md` reclassifies `proof-of-work` and `clear-context`.

### Batch 1: contracts and templates (lowest risk; 4 agents in parallel)

- **1A project-setup templates**: `project-setup/assets/GLOSSARY.md`, `docs/rules.md`, `docs/capabilities.md`, `docs/decisions/pitfalls.md`, `profiles/TEMPLATE.md`, `model-map/TEMPLATE.md`, `agent-overrides.yaml`.
  - Fill in the Claude aliases now, and leave a Codex `TODO(G8)` placeholder.
  - Shape the `rules.md` YAML schema so it maps onto dependency-cruiser `forbidden` rules. The G9 docs lookup is small enough to do here.
- **1B feature-workflow templates**: `feature-workflow/assets/{spec,tasks,codebase-map,design-log,data-model,verification-plan,deferred,proposals,report}.md`.
- **1C domain-modeling** (FULL upstream): `domain-modeling/SKILL.md`, `assets/{GLOSSARY-FORMAT,ADR-FORMAT,adr}.md`.
  1. Replace both format files with fresh copies of `MP:skills/engineering/domain-modeling/{GLOSSARY-FORMAT,ADR-FORMAT}.md` (MIT).
  2. Adapt `docs/adr/` → `docs/decisions/adr/`, and add superseded marking. Secondary sources: EveryInc concepts-vocabulary and the wshobson ADR lifecycle.
- **1D retro and cache templates**: `retrospective/assets/retrospective.md`, `regenerate-caches/assets/cache-frontmatter.md`.
  - The stamp fields come from the plan, with gsd-core and humanlayer as prior art.
  - Mark the body shapes `TODO(G6)`.
- **Exit check.**
  - Every schema the scripts parse is written down, each in exactly one template: spec frontmatter, the `tasks:` array, the rules YAML blocks, the profile headings and Toolchain keys, the model-map frontmatter, the cache frontmatter.
  - The D37 header is shown once. 1B may own an example of it in the `tasks.md` commentary if useful.

### Batch 2: shared scripts (pure engineering; 5 agents in parallel)

- **2A** `feature-workflow/scripts/status-transition.sh` + `check-write.sh` (they share the `.step` format). `set-task` is the only writer of task records (D45). Any `GLOSSARY.md` or `GLOSSARY-MAP.md` at any depth is Tier A (D46). The task validator must accept `^CAP-([0-9]{3,}|NEW-[a-z0-9]+(-[a-z0-9]+)*)$` (D44).
- **2B** `feature-workflow/scripts/resolve-launch.sh`: the D31 table, D35 precedence and the D37 header parser. It exposes a `--parse-header` mode that `pre-launch.sh` and `post-implementation-audit.sh` reuse.
- **2C** `feature-workflow/scripts/run-toolchain.sh`.
- **2D** `regenerate-caches/scripts/cache-stamp-check.sh` + `publish-cache.sh` (this slot fixes the staging dir name).
- **2E** `project-setup/scripts/generate-boundary-config.sh` (needs the G9 docs).
- Each agent writes fixture-driven checks in the session scratchpad. The repo's `tests/` belongs to §7.

### Batch 3: hooks (pure engineering; 3 agents in parallel)

- **3A** `hooks/pre-launch.sh`.
- **3B** `hooks/spec-single-writer-guard.sh`, `tier-a-write-guard.sh`, `tier-b-write-guard.sh`.
- **3C** `hooks/post-implementation-audit.sh` (D39), `rules-boundary-config-sync.sh`, `session-start-resume.sh`.
- Deferred to Batch 6: `hooks/evidence-capture.sh` (G1).

### Batch 4: agents (prompt writing; 4 agents in parallel)

- **4A Phase 0**: `agents/retrieval.md`, `fact-lookup.md`, `module-audit.md`.
- **4B coding**: `agents/implementation.md`, `integration.md`, `profile-mini-review.md`.
- **4C review**: `agents/review-standards.md`, `review-end-state.md`.
- **4D research**: `agents/library-evaluation.md`. Moved up from Batch 6 because the survey closed G5.
- Deferred to Batch 6: `review-targets.md` (G3) and `cache-regeneration.md` (G6).

### Batch 5: skills and modules (4 agents in parallel)

- **5A router + Phase 0**: `feature-workflow/SKILL.md`, `modules/discovery.md`, `modules/questioning-loop.md`, `modules/deferred-handoff.md`. 5A fixes the module table and the entry and exit names first; the other slots refer to modules by name only.
- **5B Phases 1–3**: `modules/verification-setup.md`, `modules/task-breakdown.md`, `modules/implementation-orchestrator.md`. If G4 is still open, write step 1.4 against a `TODO(G4)` placeholder.
- **5C Phases 4–5**: `modules/review-triage.md`, `modules/sign-off.md`. At 5.3, sign-off assigns each approved new capability the next unused `CAP-###` (highest in `docs/capabilities.md` + 1) and adds its row. It then rewrites every provisional `CAP-NEW-<slug>` reference in that spec's files: `spec.md`, `tasks.md`, `verification-plan.md`, `proposals.md`, `report.md`, `design-log.md` (D44).
- **5D standalone**: `project-setup/SKILL.md` and `retrospective/SKILL.md`.
  - `project-setup` fetches anti-slop from `dmmulroy/anti-slop` at a pinned commit at setup time (D42). Nothing is bundled under `project-setup/assets/`. The vendored copy in the target keeps the upstream LICENSE files (including `vendor/eslint-stylistic/LICENSE`) and an `UPSTREAM.md` recording the commit. Pick and record the pin when building.
  - It overwrites every placeholder in `model-map/TEMPLATE.md` when seeding (D23).
  - Leave G8 and G11 placeholders.

### Batch 6: gap-dependent items (revised after the survey)

Each slot starts when its gap closes.

- **6A** (G1 open; G2 stack decided): `project-setup/assets/profiles/examples/test-harness.md` and `e2e-browser.md`, then `hooks/evidence-capture.sh`. The stack (D26) is Vitest, `tsc`, oxlint + anti-slop, oxfmt (or Prettier), dependency-cruiser and Playwright. Fetch the exact commands and config keys from those tools' docs through context7.
- **6B** (G6; partly closed): `agents/cache-regeneration.md`, `regenerate-caches/SKILL.md`, and the body-shape section of `cache-frontmatter.md` (only the `TODO(G6)` section).
  - It can start now, with the gsd-core codebase-mapper as the agent source.
  - The determinism rules come last.
- **6C** (G3; open): `agents/review-targets.md`.
- **6D** (G7 remainder and G8; open):
  1. A Codex hook verification run, copying the `PLAN/hook-verification/` approach. Per D40, every event that behaves like Claude's is wired in `.codex/hooks.json`, and the rest stay advisory script calls. The run must cover PreToolUse rewrite on `spawn_agent`, SubagentStop block plus transcript (for D39), and the payload fields.
  2. Then the `.codex/` shim files: a `hooks.json` template and the rules for generating agent toml files. The generation itself lives in `install.sh` (7A).
  3. The Codex aliases in `model-map/TEMPLATE.md` and `project-setup/SKILL.md` (only the `TODO(G8)` placeholders).
- No longer in Batch 6: `library-evaluation`, which moved to 4D.

### Batch 7: install (1 agent)

**7A** owns `install.sh`, plus the yq and jq requirement lines in `README.md` (only the requirements section; the §5 docs work owns the rest). It runs last. It:

- copies the finished payload;
- writes the version stamp or manifest;
- wires the Claude shim and the settings merge;
- generates `.codex/agents/*.toml` and `.codex/hooks.json` from 6D's rules;
- adds `.gitignore` entries for `.workflow/specs/*/.step` and for the staging dir from 2D.

Run the remaining gap briefs (G1, G2, G3, G4, the G7 live test, G8, G9) in the background alongside Batches 1–3, so Batch 6 stays off the critical path.

## Batch 2–4 outcomes (for Batch 5 builders)

Batches 2–4 settled these contracts. Each module must call the scripts and read the agent returns exactly as described here. The scripts and agent files are the source of truth; this section is the summary.

### Exit codes

| Script | 0 | 1 | 2 | 3 |
| --- | --- | --- | --- | --- |
| `resolve-launch.sh`, `status-transition.sh`, `check-write.sh` | ok | environment error (missing tool or file) | deny / invalid (reason on stderr) | — |
| `run-toolchain.sh` | clean | toolchain failure | usage error | — |
| `generate-boundary-config.sh` | generated / up to date | stale | `rules.md` blocks do not parse | tooling error |
| `cache-stamp-check.sh`, `publish-cache.sh` | ok / fresh | stale | invalid input (missing or malformed staged cache) | — |

The post-implementation audit blocks only on `run-toolchain.sh` failure. Config, environment, header and transcript errors produce a warning instead (D55).

### Agent returns

- **Agents never write `codebase-map.md`.** They return text, and the main session (`discovery`) writes `codebase-map.md` from what they return.
- **Phase 0 agents.** `retrieval`, `module-audit`, `fact-lookup` and `library-evaluation` each define a fixed return format in their agent file under `.agents/agents/`. Modules quote it from there rather than restating it.
- **Review agents** (`review-standards`, `review-end-state`).
  - Each returns one fenced ```` ```yaml review-findings ```` block.
  - Finding ids are `RS-<n>` (standards) or `RE-<n>` (end state).
  - Each finding carries a claimed severity: `high`, `medium` or `low`.
  - Only findings with confidence ≥ 80 are kept.
  - `review-triage` re-verifies every finding's severity itself and normalises ids to `F<n>`. The rework ceiling (D48) counts verified `high` findings only, never the claimed severity.
- **Implementation agent.** It commits on its own worktree branch, and the orchestrator merges the branch between waves. It returns `status`: `done` | `profile-wrong` | `scope-expansion` | `blocked`. D56 adds `discovered-work`, a report-only return, which the orchestrator handles through the 00.21–00.29 protocol. `integration`, `module-audit` and the review lenses get the same kind as a finding.
- **Evidence ids.**
  - A task's evidence lives under `artifacts/<task-id>/`.
  - Integration batches use `integration-<work_type>`.
  - Phase 1 launches (no task id, D14) use `phase-1-<work_type>`.

### Open for 5B (decide while building, then report)

- **Diff handoff to `profile-mini-review`.** Either pass the worktree path plus the base commit, or a diff file saved under `artifacts/<task-id>/`.
- **Phase 1 mini-review.** Whether Phase 1 output (the 1.2 and 1.3 test-harness and e2e work) also gets a `profile-mini-review`.

## Batch 1 outcomes

These follow-ups from Batch 1 are recorded in the D-numbers named. Later batches must honour them.

- **Tier A step values (D16).** The glossary and ADR writes happen at the agree-definition nodes `0.2.3`, `0.3.15` and `0.4.3`, and at the ADR node `0.3.7`. `check-write.sh` (2A) must accept these values.
- **`tasks.md` schema (D15, from 1B).**
  - Task ids are `T<n>`.
  - Per task: `id`, `title`, `status`, `work_type`, `module`, `seam`, `depends_on[]`, `touches_core`, `capability`.
  - `status` is one of `pending`, `in-progress`, `done`, `blocked`.
  - The `tasks.md` frontmatter holds only the `tasks:` array. `baseline_revision` lives in `spec.md`, and `cache_stamps` in `codebase-map.md`.
- **Cache frontmatter (D17).** It adds `cache_type` and `generator` to `generated_at_commit`, `generated_at` and `scope`.
- **Toolchain block (D15).** `run-toolchain.sh` runs only the six command keys: `lint`, `typecheck`, `format`, `boundary`, `test` (added by D61) and `e2e` (only with `--e2e`). It ignores any other key in the block.
- **Model-map placeholders (D23).** `project-setup` must overwrite every placeholder when seeding.
- **yq v4 gotcha.** Arrays cannot be compared with `==`. Compare key sets with `keys | sort | join(",")`, or compare scalars.
- **Harness gotcha.** The Write tool refuses a file named `report.md` (as for `feature-workflow/assets/report.md`). Write it with a Bash heredoc instead.
- **Open items for the user** (listed in checklist §1; all but one have since been decided as D43–D46):
  - the placement ADR when the ADR test fails;
  - CAP-id allocation between parallel specs;
  - legal status transitions, including leaving `blocked`;
  - who writes `work_type` at 3.1;
  - whether the Tier A guard covers nested `GLOSSARY.md` files.

## Decisions recorded from the user

- **D40.** Codex hooks are used where a live run verifies them; everything else stays advisory. This amends D9.
- **D41.** Built workflow skills are model-invocable.
- **D42.** Anti-slop is fetched at setup time at a pinned commit, not bundled.
- **Example stack (D26 amendment).** Vitest, `tsc`, oxlint + anti-slop, oxfmt (or Prettier), dependency-cruiser, Playwright.
- **D43.** At 0.3.7, a placement that fails the ADR test goes in `design-log.md`. The `domain-modeling` SKILL.md already says this.
- **D44.** New capabilities use a provisional `CAP-NEW-<slug>` until 5.3 assigns the real `CAP-###`. The `spec.md`, `tasks.md` and `capabilities.md` templates are updated, and the `tasks.md` validator was re-checked with yq v4.44.3.
- **D45.** `status-transition.sh set-task` is the only writer of task records.
- **D46.** The Tier A guard covers any `GLOSSARY.md` or `GLOSSARY-MAP.md` at any depth.
- **Still open:** the legal status transitions, until the user reviews 2A's table.

The open questions now live in checklist §1 ("Batch 1 open questions").
