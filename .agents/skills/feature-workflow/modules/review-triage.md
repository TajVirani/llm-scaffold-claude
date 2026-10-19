<!--
File: Phase 4 module of `feature-workflow` (4.1-4.8): three independent review lenses in parallel, then finding-by-finding triage and routing in the main session.
Triggers/inputs: spec status `in-review` (set at 3.11, or 3.14 on a light path without suites, by modules/implementation-orchestrator.md; again after each 4.7 rework). Reads the lens returns, the diff from `baseline_revision`, tasks.md, design-log.md and artifacts/.
Outputs/handoff: design-log.md triage entries; raw lens returns (and the review-targets `measurements` table) under artifacts/review/; discovered-work entries to modules/discovered-work.md (00.21-00.28); rework to modules/implementation-orchestrator.md (4.7); loop back to modules/questioning-loop.md at 0.3.8 (4.5, 4.6); deferred/ handoffs through modules/deferred-handoff.md (4.8); handoff to modules/sign-off.md (5.1).
Plan refs: PLAN/decision-flow-reference.md Phase 4, "Review: lenses, then triage", "Status"; PLAN/decision-flow.mermaid P4 edges; assetlist D13, D24, D31, D33, D37, D38, D45, D48, D49, D54, D56, D62; PLAN/sourcing.md "Batch 2-4 outcomes" (review-findings contract); PLAN/gap-research.md G3 (review-targets return: `category: target`, `measurements:`).
Sources: first-party, adapted from: mattpocock/skills skills/engineering/code-review/SKILL.md at 3da8c01 (MIT; steps 4-5 and "Why two axes": independent parallel lenses, no merging or reranking across lenses). bmad-code-org/BMAD-METHOD skills/bmad-code-review/step-03-triage.md and skills/bmad-build/step-04-review.md (MIT, Copyright (c) 2025 BMad Code, LLC): normalise, verify at the cited location, one verdict high/medium/low/false/maybe-false, reject rules, group by root cause, route decision-needed/patch/defer, "carried" verdicts on a re-review, loop counter capped at five; prose adapted and changed, no templating; BMad names are trademarks and are used for attribution only. bmad-code-org/BMAD-METHOD skills/bmad-code-review/step-04-present.md (MIT): decision-needed entries carry options and a recommendation; failed lenses are reported before any clean result. anthropics/claude-plugins-official plugins/code-review/commands/code-review.md (Apache-2.0): the confidence cutoff of 80 that the lenses apply before returning (referenced, not copied). Third-pass rule and rework ceiling of five: PLAN/decision-flow-reference.md 4.6-4.7 (BMad).
-->

# Review and triage (Phase 4)

Three lenses review the whole change independently; you then verify, grade and route every finding yourself in the main session. You are done with Phase 4 when one exit in step 6 has run: rework, loop back, or hand-off to sign-off.

`specs/NNN-slug` is this feature's folder. Run scripts from the project root with their exact `.agents/skills/feature-workflow/scripts/` prefix (SKILL.md, "Conventions every module follows"). Every status, task-record and step change goes through `status-transition.sh`, with the exact `--step` shown. Exit 0 is done; exit 2 is a refused transition with the reason on stderr: stop and report it rather than working around it. On Codex, run `check-write.sh` before the spec.md write at 4.6 as SKILL.md "Host notes" says.

## 1. Fix the pass number

Phase 4 runs once per **pass**. Read `specs/NNN-slug/design-log.md` before launching anything:

- **Pass number** `n`: the count of `Triage, review pass` entries written since the last `Outcome: loop back (...)` line of any kind, plus one: a triage pass's own (4.5, 4.6, 00.24) or the one a Discovered work entry ends with (`00.24 discovered work`, `00.29 budget re-scope`). A loop back to 0.3.8 starts a new review cycle at pass 1.
- **Rework used**: the count of `Outcome: rework` lines in the whole file. The ceiling is 5, and it never resets.
- **Next finding id**: the highest `F<n>` in the file plus one. Finding ids are unique across the feature.

**Resuming.** If any task record in `tasks.md` is `in-progress`, a rework is under way whatever `.step` says (the orchestrator's gates move it off 4.7): load `modules/implementation-orchestrator.md` for those tasks instead, as the router does. Otherwise, if the newest triage entry has an `Outcome:` line and `.step` names 4.5 to 4.8, that pass is already decided: finish its exit instead of starting a new pass; for a pending 4.8, run step 7. If `.step` names a node from 00.21 to 00.28, a discovered-work entry was being handled: finish it through `modules/discovered-work.md`, then continue at 6.0 with the next one.

## 2. Launch the three lenses (4.1-4.3)

Launch `review-standards`, `review-end-state` and `review-targets` together in one message, in the foreground, and wait for all three before reading any result. Give each the same minimal prompt: the header, then one line of task. Pass nothing else: no diff, no other lens's output, no summary of the feature. Each lens reads its own inputs.

````text
```yaml launch-header
task_type: review-standards
spec_dir: specs/NNN-slug
```

Review pass <n> of specs/NNN-slug. Return the review-findings block.
````

Repeat with `task_type: review-end-state` and `task_type: review-targets`; `subagent_type` matches `task_type`. On Claude the `pre-launch` hook resolves the model through `resolve-launch.sh` and denies a malformed header (D33, D37). On Codex, build each prompt yourself and launch as the [SKILL.md "Host notes"](../SKILL.md#host-notes) Launch row says: `agent_type` `review_standards`, `review_end_state`, `review_targets`, `task_name` `s<NNN>_<lens>` (`s007_review_standards`, `s007_review_end_state`, `s007_review_targets`), `fork_turns: "none"`:

```bash
echo "Review pass <n> of specs/NNN-slug. Return the review-findings block." |
  .agents/skills/feature-workflow/scripts/resolve-launch.sh --host codex --task-type review-standards --spec-dir specs/NNN-slug
```

**`review-targets` runs the build itself** (G3). It starts the build with the profile's `serve`, waits for `serve_ready`, measures and stops it (D62), so start nothing for it. Its block is parsed as in step 3, including its `measurements:` table; a return with no parseable `review-findings` block is a failed lens like any other.

Done when all three launches have returned.

## 3. Save and parse the returns

Save each lens's fenced `review-findings` block, without the fence lines, to `specs/NNN-slug/artifacts/review/pass-<n>/<lens>.yaml`. Then check its shape with mikefarah yq v4 (D38); `PFX` is `RS` for `review-standards`, `RE` for `review-end-state` and `RT` for `review-targets`:

```bash
LENS=review-standards PFX=RS yq -e '
  (.lens == strenv(LENS)) and (.status == "done" or .status == "blocked") and
  ((.findings | tag) == "!!seq") and
  ([.findings[] | select(((.id // "") | test("^" + strenv(PFX) + "-[0-9]+$")) and
      ((.category == "discovered-work" and
          ((.kind // "") | test("^(bug|requirement|refactor|scope-expansion|decision)$")) and
          (.summary // "") != "" and (.evidence // "") != "" and
          ((.blocker_assessment // "") | test("^(blocks-this-task|can-wait)$")) and
          (.reason // "") != "") or
       (.category != "discovered-work" and
          ((.severity // "") | test("^(high|medium|low)$")) and ((.confidence // 0) >= 80))))] | length) == (.findings | length)
' specs/NNN-slug/artifacts/review/pass-<n>/review-standards.yaml
```

A `category: discovered-work` finding has its own shape (`kind`, `summary`, `evidence`, `blocker_assessment`, `reason`) and no severity, confidence, location or claim; the 80 cutoff applies only to the other categories.

For `review-targets`, also check the `measurements:` table (G3): one entry per `## Targets` row of `verification-plan.md`, in table order, each with a `result` of `pass`, `fail` or `not_measurable`, and a `reason` whenever it is `not_measurable`:

```bash
yq -e '((.measurements | tag) == "!!seq") and
  ([.measurements[] | select((.result | test("^(pass|fail|not_measurable)$")) and
      (.result != "not_measurable" or (.reason // "") != ""))] | length) == (.measurements | length)
' specs/NNN-slug/artifacts/review/pass-<n>/review-targets.yaml
```

Its findings use `category: target` (one per failed target: `claim` names the measured value and the threshold, `evidence.basis` the raw output path). The table is not triaged; 5.4 copies it into "Targets vs measured", and every `not_measurable` row is a gap, never a pass.

List the findings with `yq -o=tsv '.findings[] | select(.category != "discovered-work") | [.id, .category, .severity, .confidence, .location, .claim]' <file>`, and read `claim`, `consequence`, `evidence` and `suggested_fix` per finding. List the discovered-work findings separately with `yq -o=tsv '.findings[] | select(.category == "discovered-work") | [.id, .kind, .blocker_assessment, .evidence, .summary]' <file>`, and read each one's `reason`. Read `not_checked` and `not_verifiable` too: they are gaps, never passes.

- A block that fails the check, or no block at all: relaunch that lens once. If it fails again, it is a **failed lens**.
- `status: blocked`: fix the cause it names (usually an empty or unresolvable `baseline_revision`) and relaunch. If you cannot fix it, it is a failed lens.
- A failed lens is named in the triage entry and the 5.4 report. A pass with a failed lens is never reported as clean.

Done when every lens has a parsed block or is recorded as failed.

## 4. Triage each finding (4.4)

Work on one combined list. Give each finding the next `F<n>` and keep its lens id beside it (`F7 (RS-2)`). Treat the lens's `severity` as a claim only: the lens lacks the context to grade, and your verdict replaces it.

1. **Carry what was settled.** On pass 2 or later, compare each finding with the earlier triage rows. Same location, same claim, and the code there still reads as the row describes: keep that row's verdict and route, write `carried from F<m>` as the evidence, and skip verification. A carried finding is never patched or deferred a second time.
2. **Verify the claim.** At the cited file and line, does the bad outcome the lens describes actually occur? Read beyond the changed lines (callers, guards upstream, the spec line or rule it quotes) until you can answer yes or no. Judge whether the problem is real, not whether the suggested fix is plausible. Code that fails loudly on a situation the program cannot be shown to reach is correct behaviour.
3. **Render exactly one verdict.**
   - `high` (intolerable), `medium` (tolerable), `low` (cosmetic or negligible): the bad outcome is real. Grade by harm to end users or developers; for developer-only harm, name where it will cause trouble. When the harm is real but you cannot tell how bad, pick the higher grade.
   - `false`: you checked, and the bad outcome does not happen there. Write what disproves this specific claim.
   - `maybe-false`: the diff and surrounding code leave it open. Write what would settle it.
4. **Dismiss noise, with the reason recorded.** Route `none` for: every `false` (on its refutation); a `low` that users or developers are unlikely to meet in everyday use and whose fix adds guards, branches or parameters; an all-`maybe-false` finding that would only be `low` if true.
5. **Spot discovered work.** A finding with `category: discovered-work`, or any finding you verified as real whose fix lies outside the spec's agreed scope (a new requirement, a bug found along the way, a needed refactor, scope spreading into another module, a decision nobody in the session can answer), is **discovered work** (D56). It routes to the protocol in step 5, never to patch: the current spec does not grow to fix it. Pre-existing behaviour that this change did not cause and that needs nothing now stays `defer`.
6. **Group by root cause.** Two findings share an entry only when the same defect produced both; the same location or the same fix is not enough. The group takes the highest verdict among its members (`high` > `medium` > `low` > `maybe-false`) and keeps every member's id.

**Verified high** means a verdict of `high` you rendered here. Only verified high findings count toward D48 at 4.7; a lens's claimed `high` and an unverified `maybe-false` never do.

Done when every finding has a verdict and evidence; none is dropped, merged silently or left unread.

## 5. Route each surviving entry (4.5) and log the pass

Route each entry into exactly one bucket. An entry with a verified `high`, `medium` or `low` member routes by that verdict, never to defer just because another member is `maybe-false`.

- **decision needed**: the correct fix depends on intent the spec does not settle: two plausible readings, a fix that changes what a capability, constraint or non-goal says, or a fix that adds public surface. Record each plausible option in one line, the one you recommend, and why. These become questions at 0.3.8.
- **patch**: caused by this change; the smallest fix is unambiguous, adds no public surface and guards no state you did not demonstrate. Name the task that owns the location (step 6.3).
- **discovered work**: the entries from 4.4 item 5. Record the evidence (file:line, the lens id and its claim) and your assessment, **blocker** for the current work or **can be solved later**, with a recommendation; `modules/discovered-work.md` presents them in step 6.0.
- **defer**: real, but not this change's problem: pre-existing behaviour on lines this change did not cause, or an all-`maybe-false` entry that would be `medium` or `high` if true (record that severity, marked unverified, and what would settle it). An entry this change caused with a verified `high`, `medium` or `low` member is never defer: it is patch or decision needed.
- **defer as a proposal**: an entry whose only fix edits Tier A (`docs/rules.md`, an ADR, a glossary, a profile) or agent instructions. Tier A changes only at 5.3, so add a row to `specs/NNN-slug/proposals.md` (template `assets/proposals.md`; Origin `F<n>`, Status `proposed`) and route it `defer (proposal P<n>)`.

Append the pass to `specs/NNN-slug/design-log.md` using the "Triage, review pass <n>" shape from `assets/design-log.md`: one row per finding, including dismissed and carried ones, with the lens id in the Source lens column. Below the table add the failed lenses (or "Failed lenses: none"); step 6 appends the outcome line once it has decided, with one of these values:

```markdown
Failed lenses: none
Outcome: <rework k of 5 | loop back (4.5 decision needed) | loop back (4.6 third pass) | loop back (00.24 discovered work) | blocked (4.7) | deferred, to sign-off | clean, to sign-off>
```

Done when every surviving entry has one route and the pass is logged.

## 6. Exit

Take the first exit that applies, in this order. Any deferred entries are written at 4.8 before the exit, because they survive every route.

### 6.0 Discovered work first (4.4 → 00.21)

If any entry is **discovered work**, load `modules/discovered-work.md` once with every such entry, each with origin node `4.4`, found by (the lens and `F<n>` with its lens id), the problem, the evidence, the kind and your assessment. It blocks the spec (`blocked_condition: "discovered work: <slug>"`), presents all of them in one round and records each answer (an ignore line in `design-log.md`, or a backlog item under `specs/work-backlog/`). Name the outcome in the entry's Route cell.

- **It returns at 00.28** (the spec is back at `in-review`): drop the entry from this pass's open work and continue with the next exit below.
- **It ends at 00.24** (the spec is `draft`, back to 0.3.8): run 4.8 for the deferred entries, set the outcome line to `loop back (00.24 discovered work)` and stop; the questioning loop owns the next step. Patch entries in this pass are moot, as in 6.1.
- **It leaves the spec `blocked`** for a human: stop here. When the human resolves it, 00.28 returns the spec to `in-review` and you resume at 6.1 from the logged pass.

### 6.1 Decision needed: back to 0.3.8 (4.5)

If any entry is **decision needed**: run 4.8 for the deferred entries, then

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug draft --step 4.5
```

Set the outcome line to `loop back (4.5 decision needed)` and load `modules/questioning-loop.md` at 0.3.8 with the decision-needed entries as the frontier, each with its options and recommendation. Patch entries in the same pass are moot: the code is re-derived after the spec changes (D49).

### 6.2 Third pass still has non-trivial findings (4.6)

If pass `n` is 3 or more and any **patch** entry is verified `high` or `medium`, the problem is upstream. Run 4.8 for the deferred entries, then:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 4.6
```

Edit `specs/NNN-slug/spec.md` frontmatter to `followup_review_recommended: true` (the only key you change; D54), then

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug draft --step 4.6
```

Set the outcome line to `loop back (4.6 third pass)` and load `modules/questioning-loop.md` at 0.3.8 with the open patch entries as the frontier.

### 6.3 Rework attempts remain (4.7 Yes)

If any **patch** entry remains and rework used is below 5: run 4.8 for the deferred entries, then reopen each task that owns a patch location. Find the owner from the history since the baseline (`git log --format='%H %s' <baseline_revision>..HEAD -- <path>`, where each worktree merge names its task id), falling back to the task (never a `split-out` one, D68) whose `module` in `specs/NNN-slug/tasks.md` owns the path under `docs/rules.md`. For each owning task:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh set-task specs/NNN-slug T<n> --status in-progress --step 4.7
```

`set-task` allows `done` to `in-progress` only with `--step 4.7` (D45). Set the outcome line to `rework <used + 1> of 5` and load `modules/implementation-orchestrator.md` for those tasks, handing it each patch as one line: `<file:line> - <what is wrong> - <what the smallest fix must do>`. The orchestrator relaunches `implementation`, re-runs the gates, sets `in-review` again at 3.11 (or 3.14), and returns here for pass `n + 1`.

### 6.4 Rework ceiling reached (4.7 No)

If **patch** entries remain and rework used is 5:

- **Verified high entries are open** (D48):

  ```bash
  .agents/skills/feature-workflow/scripts/status-transition.sh status specs/NNN-slug blocked --step 4.7 --blocked "Rework ceiling (5) reached with verified high-severity findings open: F<n>, F<m>. A human decides at sign-off whether to accept them as known gaps."
  ```

  Set the outcome line to `blocked (4.7)`.
- **No verified high entry is open**: the spec stays `in-review`; set the outcome line to `deferred, to sign-off`.

Either way, every open patch entry becomes a deferred entry for 4.8, with its verified severity. Tell the stakeholder which findings are open and why.

### 6.5 Nothing left to fix

If only deferred and dismissed entries remain, set the outcome line to `deferred, to sign-off` (or `clean, to sign-off` when nothing was deferred and no lens failed).

## 7. Deferred handoffs (4.8)

Run 4.8 whenever deferred entries exist, before the exit that needs it:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step specs/NNN-slug 4.8
```

Then load `modules/deferred-handoff.md` and write one handoff per deferred entry (proposal-routed entries already live in `proposals.md`). Pass it, for each entry: the concept the finding is about, origin step 4.8, `severity` from your verdict (a `maybe-false` entry carries the severity it would have if true and says "unverified" under Evidence), the location tied to the current `HEAD` commit, the verdict evidence, and the design-log triage entry. Add the remaining gaps from the lenses the same way: requirements under `not_verifiable` and targets that could not be measured; a gap has no verdict, so its handoff omits `severity`. `deferred-handoff` adds each file to `deferred` in `specs/NNN-slug/spec.md` (admitted at step 4.8) and fills the Route cells of the triage rows. Check its Return lists every entry you handed over; a `failed` item stays open in the triage entry until it is written.

Done when every deferred entry has a `deferred/` file listed in `spec.md`. After an exit in 6.4 or 6.5, load `modules/sign-off.md`. A spec set `blocked` at 6.4 continues there only with the stakeholder present: 5.1 lifts the block (D47).
