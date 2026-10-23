# T03: The review-lessons lens definition

Index: [../tasks.md](../tasks.md) · Blocked by: None (can start immediately) · Parallel with: None

**What to build:** The fourth Phase 4 lens, `.agents/agents/review-lessons.md`: a read-only, cheap-tier sub-agent that checks the whole change since `baseline_revision` against the project's recorded review lessons, pitfalls and retrospectives, writes its `review-findings` block to its pass file exactly as the other three lenses do, and returns the summary block. With it, the housekeeping the cross-cutting policy requires in the same change: the install manifest line and count, the PROVENANCE row and Sources line, the assetlist entries and the README line naming four lenses.

**Seam:** `tests/lint/frontmatter.sh` over the definition (exact keys, no `model:`) and the Codex toml `generate-codex-agents.sh` emits from it (`tests/scripts/generate-codex-agents.sh`); the asset-set assertions of `tests/lint/review-lessons.sh` (owned by T6). The lens's judgement is proved by the JRN-001 and JRN-002 live runs at the 3.10 gate, not by the harness.

**Acceptance criteria:**

- [ ] `.agents/agents/review-lessons.md` has frontmatter exactly `name: review-lessons`, `description` leading "Phase 4 review lens (workflow step 4.9)." and then, like the sibling lenses, what it checks, what it writes and returns, and what it is not for; `tools: Read, Grep, Glob, Bash`; no `model:` or `models:` key.
- [ ] Its body is modelled on `.agents/agents/review-standards.md`: the launch-header example (`task_type: review-lessons`, `spec_dir`); a Receives table listing only its inputs: the diff base from `spec.md` `baseline_revision`, `.workflow/review-lessons.md` (one fenced `lessons:` list; a missing file reads as an empty list and is never a reason to block; a file whose block fails to parse with yq gives `status: blocked` naming the error), `.workflow/decisions/pitfalls.md` and `.workflow/decisions/retrospectives/*.md`.
- [ ] Method: pin the diff as the other lenses do (`git diff <baseline>...HEAD -- . ':(exclude)<spec_dir>'`); for each lesson without `retired`, look for its `symptom` only in hunks of files matching its `paths` (Ownership-block glob syntax); look for pitfalls and retrospective lessons across the whole diff; try to disprove each suspicion; score with the same confidence anchors and the 80 cutoff. Severities: a repeated review lesson is `high`, `category: lesson`, with `lesson: <its id>`; a repeated pitfall or retrospective lesson with no review-lesson entry is `medium`, `category: lesson`, no `lesson:` field, and its `suggested_fix` proposes recording it as a review lesson at the next 5.7. Discovered work keeps the shared shape.
- [ ] Return: the full block written to `<spec_dir>/artifacts/review/pass-<n>/review-lessons.yaml` with one heredoc (ids `RL-<n>`, `evidence.basis` quoting the lesson, pitfall or retrospective line), `checked` naming every file read (the lessons file when present, pitfalls, each retrospective), `not_checked` naming a missing pitfalls file or an empty retrospectives folder; then the summary block and nothing else. It changes nothing else and runs read-only commands only.
- [ ] `.agents/install-manifest.txt` lists `agents/review-lessons.md` in order under a `# --- Agents (14)` header; `PROVENANCE.md` counts 14 agents in its agents row and its "the N `agents/*.md`" line, names `review-lessons` there, and gains a `- \`agents/review-lessons.md\`: Sources: first-party, modelled on \`agents/review-standards.md\` ...` line; `assetlist.md` gains the agent's table row and a `### review-lessons` section like the other lens sections; `README.md` names `review-lessons` with the other three lenses.
- [ ] Prose follows `.agents/skills/writing-for-agents/SKILL.md` and the readable-code baseline: no decision id in the definition; the fixture lesson is never quoted as an example lesson.
- [ ] `tests/lint/frontmatter.sh`, `tests/scripts/generate-codex-agents.sh`, `tests/scripts/install-payload.sh` and `tests/lint/upstream-lineage.sh` still pass; the agent, manifest, PROVENANCE, README and toml assertions of `tests/lint/review-lessons.sh` go green.

**Predicted files:** `.agents/agents/review-lessons.md`, `.agents/install-manifest.txt`, `PROVENANCE.md`, `assetlist.md`, `README.md`.

**Phase 1 tests:** None. The asset-set suite `tests/lint/review-lessons.sh` is owned by T6, which runs after this task.

**Size:** M (5 files, about 180 changed lines).

**Mode:** afk.

**Notes:** Carries migration M6 except the Codex toml, which is generated in target projects by `install.sh` and never committed here. The manifest (installer), PROVENANCE and assetlist (no owner) and README (root-docs) were granted to this task at the 2.1 quiz because the cross-cutting policy wants them in the same change as the asset. No `upstream-lineage.json` entry: first-party, modelled on first-party lenses. This repo's own `.workflow/model-map/review-lessons.md` (cheap tier, claude `haiku`, codex `gpt-6-luna`) is written by the orchestrator through the 00.14 flow at the first real launch, as spec 001 did for `research`.
