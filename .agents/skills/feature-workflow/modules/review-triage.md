# Review and triage (Phase 4)

Four lenses review the whole change independently (one combined review on the light path); you then verify, grade and route every finding yourself in the main session. Every finding is proven first and escalated by the rule in [discovered-work](discovered-work.md#assess-each-report-first). You are done with Phase 4 when one exit in step 6 has run: rework, loop back, or hand-off to sign-off.

`.workflow/specs/NNN-slug` is this feature's folder. Run scripts from the project root with their exact `.agents/skills/feature-workflow/scripts/` prefix ([conventions](../references/conventions.md)). Every status, task-record and step change goes through `status-transition.sh`, with the exact `--step` shown. Exit 0 is done; exit 2 is a refused transition with the reason on stderr: stop and report it rather than working around it. On Codex, run `check-write.sh` before the spec.md write at 4.6 as the conventions' [Host notes](../references/conventions.md#host-notes) say.

## 1. Fix the pass number

Phase 4 runs once per **pass**. Read `.workflow/specs/NNN-slug/design-log.md` before launching anything:

- **Pass number** `n`: the count of `Triage, review pass` entries written since the last `Outcome: loop back (...)` line of any kind, plus one: a triage pass's own (4.5, 4.6, 00.24) or the one a Discovered work entry ends with (`00.24 discovered work`, `00.29 budget re-scope`). A loop back to 0.3.8 starts a new review cycle at pass 1.
- **Rework used**: the count of `Outcome: rework` lines in the whole file. The ceiling is 5, and it never resets.
- **Next finding id**: the highest `F<n>` in the file plus one. Finding ids are unique across the feature.

**After a rework with no verified high patch.** When the spec is back at `in-review` and the newest triage entry's outcome is `rework <k> of 5` with no patch row verified `high`, the rework's own gates were its check: start no new pass. Run step 7 if that pass has no `Gaps:` line yet, then load `modules/sign-off.md`.

**Resuming.** If any task record in `tasks.md` is `in-progress`, a rework is under way whatever `.step` says (Phase 3's gates move it off 4.7): load `modules/implementation-waves.md` for those tasks instead, at its Rework entry, as the router does. Otherwise, if the newest triage entry has an `Outcome:` line and `.step` names 4.5 to 4.8, that pass is already decided: finish its exit instead of starting a new pass; for a pass with no `Gaps:` line, run step 7. If `.step` names a node from 00.21 to 00.28, a discovered-work entry was being handled: finish it through `modules/discovered-work.md`, then continue at 6.0 with the next one.

## 2. Launch the four lenses (4.1-4.3, 4.9), or the combined review (4.10)

**Light path: one combined review (4.10).** When `light_path` is `true` in `.workflow/specs/NNN-slug/spec.md` (the small path included), launch one `review-combined` in place of the lenses, with the same minimal prompt below and `task_type: review-combined`. It covers the end state, the standards and the review lessons, and writes one pass file in the lens shape, `review-combined.yaml`, checked in step 3 like any lens's. There is no `verification-plan.md` and so no targets: write `no targets (light path)` in the triage entry where the targets lens would be named. The rest of this step is the full path.

Launch `review-standards`, `review-end-state`, `review-targets` and `review-lessons` together in one message, in the foreground, and wait for every one before reading any result. Give each the same minimal prompt: the header, then one line of task. Pass nothing else: no diff, no other lens's output, no summary of the feature. Each lens reads its own inputs.

````text
```yaml launch-header
task_type: review-standards
spec_dir: .workflow/specs/NNN-slug
```

Review pass <n> of .workflow/specs/NNN-slug. Write the review-findings block to your pass file and return the summary block.
````

Repeat with `task_type: review-end-state`, `task_type: review-targets` and `task_type: review-lessons`. Launch each on your host as [launching](../references/launching.md) says; on Codex the task body is the one line above.

**`review-targets` runs the build itself.** It starts the build with the profile's `serve`, waits for `serve_ready`, measures and stops it, so start nothing for it. Its pass file is checked as in step 3, including its `measurements:` table.

Done when every launched lens has returned.

## 3. Check the pass files

Each lens writes its full `review-findings` block to `.workflow/specs/NNN-slug/artifacts/review/pass-<n>/<lens>.yaml` itself and returns only a summary block: `lens`, `pass`, `file`, counts by severity, the discovered-work count and one line per finding id. You never retype a block. For each lens:

1. **Confirm the file exists** at the `file` its summary names, and that the path is this pass's folder and this lens's name. A missing file, or no summary at all: relaunch that lens once.
2. **Check its shape:**

   ```bash
   .agents/skills/feature-workflow/scripts/check-review-findings.sh .workflow/specs/NNN-slug/artifacts/review/pass-<n>/review-standards.yaml
   ```

   - **Exit 0:** it prints a header line (lens, pass, counts by severity, discovered work, and the `checked`, `not_checked` and `not_verifiable` counts), then a tab-separated table, one row per finding: `id category severity confidence location claim`. For `review-targets` it also prints `target measured verdict` rows, one per `## Targets` row. This table is your finding list for step 4.
   - **Exit 1:** one line per shape error, each naming the field. Relaunch that lens once, with those lines added after its task line. If it fails again, it is a **failed lens**.
   - **Exit 2:** a usage error, a missing file or YAML that does not parse. Stop and report it.
   - **`review-targets` only, after exit 0:** the script does not read the spec, so check that `measurements:` has one row per `## Targets` row of `verification-plan.md`, in table order: `yq '.measurements | length' <file>` must equal `awk '/^## /{s=($0=="## Targets")} s && /^\|/' .workflow/specs/NNN-slug/verification-plan.md | tail -n +3 | wc -l`. A mismatch is a shape error: relaunch the lens once with the two counts, as for exit 1.
3. **Read the status:** `yq '.status, .blocked_reason' <file>`. `status: blocked`: fix the cause it names (usually an empty or unresolvable `baseline_revision`) and relaunch. If you cannot fix it, it is a failed lens.

The four pass files are `review-standards.yaml`, `review-end-state.yaml`, `review-targets.yaml` and `review-lessons.yaml`, with finding ids prefixed `RS`, `RE`, `RT` and `RL`; on the light path the one pass file is `review-combined.yaml`, with ids prefixed `RC`. A `review-lessons` file that fails the check twice, or stays `blocked`, is a failed lens like any other: the pass goes on with the other lenses' findings.

`review-targets` findings use `category: target` (one per failed target: `claim` names the measured value and the threshold, `evidence.basis` the raw output path). Its `measurements:` table is not triaged; 5.4 copies it into "Targets vs measured", and every `not_measurable` row is a gap, never a pass.

A failed lens is named in the triage entry and the 5.4 report. A pass with a failed lens is never reported as clean.

Done when every launched lens has a file that passed the check or is recorded as failed.

## 4. Triage each finding (4.4)

Work on one combined list: the rows of the step 3 tables. Read a finding's full entry only when you triage it, by id: `yq '.findings[] | select(.id == "RS-2")' <file>` gives its `claim`, `consequence`, `evidence` and `suggested_fix`, or, for discovered work, its `kind`, `summary`, `evidence`, `blocker_assessment` and `reason`. Read `not_checked` and `not_verifiable` too (`yq '.not_checked, .not_verifiable' <file>`): they are gaps, never passes, and step 7 records them. Give each finding the next `F<n>` and keep its lens id beside it (`F7 (RS-2)`). Treat the lens's `severity` as a claim only: the lens lacks the context to grade, and your verdict replaces it.

A `review-lessons` finding has `category: lesson`. When it repeats a review lesson its `lesson:` field carries that lesson's id (`RL-001`). Its claimed `high` (a review lesson repeated) or `medium` (a pitfall or retrospective lesson repeated) is a claim like any other severity: verify, grade and route it as below.

1. **Carry what was settled.** On pass 2 or later, compare each finding with the earlier triage rows. Same location, same claim, and the code there still reads as the row describes: keep that row's verdict and route, write `carried from F<m>` as the evidence, and skip verification. A carried finding is never patched or routed to the stakeholder a second time.
2. **Check the proof.** The lens proves its own findings: `evidence.reproduction` (a command and its output, or a failing test) or a quoted rule, spec or lesson line in `evidence.basis` that the cited line breaks. A finding with neither is **unproven**. You may supply the proof yourself with one command (a probe in a scratch worktree, as the lenses run them); otherwise it is unproven and step 4 dismisses it.
3. **Verify the claim.** At the cited file and line, does the bad outcome the lens describes actually occur? Re-run the reproduction when it is cheap, and read beyond the changed lines (callers, guards upstream, the spec line or rule it quotes) until you can answer yes or no. Judge whether the problem is real, not whether the suggested fix is plausible. Code that fails loudly on a situation the program cannot be shown to reach is correct behaviour.
4. **Render exactly one verdict.**
   - `high` (intolerable), `medium` (tolerable), `low` (cosmetic or negligible): the bad outcome is real and proven. Grade by harm to end users or developers; for developer-only harm, name where it will cause trouble. When the harm is real but you cannot tell how bad, pick the higher grade.
   - `false`: you checked, and the bad outcome does not happen there. Write what disproves this specific claim.
   - `unproven`: no reproduction and no quotable line, and none you could supply with one command. Write what would settle it, in one line.
5. **Dismiss noise, with the reason recorded.** Route `none` for: every `false` (on its refutation); every `unproven` (it stays that one line, with no question and no file); a `low` that users or developers are unlikely to meet in everyday use and whose fix adds guards, branches or parameters.
6. **Spot discovered work.** A finding with `category: discovered-work`, or any proven finding whose fix lies outside what this change caused (a bug found along the way, pre-existing behaviour on lines this change did not cause, a needed refactor, scope spreading into another module, a new requirement, a decision nobody in the session can answer), is **discovered work**. It routes to the protocol in step 5, never to patch: the current spec does not grow on its own to fix it.
7. **Group by root cause.** Two findings share an entry only when the same defect produced both; the same location or the same fix is not enough. The group takes the highest verdict among its members (`high` > `medium` > `low` > `unproven`) and keeps every member's id.

**Verified high** means a verdict of `high` you rendered here. Only verified high findings count toward the rework ceiling at 4.7; a lens's claimed `high` and an `unproven` finding never do.

Done when every finding has a verdict and evidence; none is dropped, merged silently or left unread.

## 5. Route each surviving entry (4.5) and log the pass

Route each entry into exactly one bucket. An entry with a verified `high`, `medium` or `low` member routes by that verdict, never to `none` just because another member is `unproven`.

- **patch**: proven and caused by this change, on lines or files the spec changes or inside its capabilities; the smallest fix is unambiguous, adds no public surface and guards no state you did not demonstrate. It goes back to the worker in the rework (step 6.3); the stakeholder is not asked. Name the task that owns the location.
- **decision needed**: a blocker by the **Blocker?** test of [discovered-work](discovered-work.md#assess-each-report-first) whose correct fix depends on intent the spec does not settle: two plausible readings, a fix that changes what a capability, constraint or non-goal says, or a fix that adds public surface. Record each plausible option in one line, the one you recommend, and why. These become questions at 0.3.8.
- **discovered work**: the entries from 4.4 item 6, and every proven entry this change caused that is no blocker and whose fix is not simple (the convoluted class in [discovered-work](discovered-work.md#assess-each-report-first)). Record the evidence (the proof, the lens id and its claim) and your assessment with a recommendation; `modules/discovered-work.md` routes them in step 6.0: a blocker stops the spec, everything else waits for the stakeholder's batched question.
- **proposal**: an entry whose only fix edits Tier A (`.workflow/rules.md`, an ADR, a glossary, a profile) or agent instructions. Tier A changes only at 5.3, so add a row to `.workflow/specs/NNN-slug/proposals.md` (template `assets/proposals.md`; Origin `F<n>`, Status `proposed`) and route it `proposal P<n>`; the 5.3 approval round is its question.
- **none**: every `false`, every `unproven` entry and the noise from 4.4 item 5, each with its reason.

Append the pass to `.workflow/specs/NNN-slug/design-log.md` using the "Triage, review pass <n>" shape from `assets/design-log.md`: one row per finding, including dismissed and carried ones, with the lens id in the Source lens column. Below the table add the failed lenses (or "Failed lenses: none"); step 6 appends the outcome line once it has decided, with one of these values:

```markdown
Failed lenses: none
Outcome: <rework k of 5 | loop back (4.5 decision needed) | loop back (4.6 third pass) | loop back (00.24 discovered work) | blocked (4.7) | open items, to sign-off | clean, to sign-off>
```

Done when every surviving entry has one route and the pass is logged.

## 6. Exit

Take the first exit that applies, in this order. Step 7 (4.8) records the gaps before the exit, because they survive every route.

### 6.0 Discovered work first (4.4 → 00.21)

If any entry is **discovered work**, load `modules/discovered-work.md` once with every such entry, each with origin node `4.4`, found by (the lens and `F<n>` with its lens id), the problem, the evidence, the kind and your assessment. The module assesses each entry first. Name the outcome in the entry's Route cell: `discovered work (to ask, <class>)` for an entry waiting for the stakeholder, `discovered work (<ruling>)` for a blocker.

- **Current work.** The module hands back an entry that is in fact a simple fix to this change: route it **patch** instead and continue.
- **Unproven, or for the stakeholder.** The module records it (one line, or a `to ask` entry for the batched question at the next ask or 5.5) and returns without blocking. Drop the entry from this pass's open work and continue with the next exit below.
- **Blocker.** The module blocks the spec (`blocked_condition: "discovered work: <slug>"`), presents every blocker in one round (with the batched question for every waiting item) and records each answer. Then:
  - **It returns at 00.28** (the spec is back at `in-review`): drop the entry from this pass's open work and continue with the next exit below.
  - **It ends at 00.24** (the spec is `draft`, back to 0.3.8): run step 7, set the outcome line to `loop back (00.24 discovered work)` and stop; the questioning loop owns the next step. Patch entries in this pass are moot, as in 6.1.
  - **It leaves the spec `blocked`** for a human: stop here. When the human resolves it, 00.28 returns the spec to `in-review` and you resume at 6.1 from the logged pass.

### 6.1 Decision needed: back to 0.3.8 (4.5)

If any entry is **decision needed**: run step 7, then

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug draft --step 4.5
```

Set the outcome line to `loop back (4.5 decision needed)` and load `modules/questioning-loop.md` at 0.3.8 with the decision-needed entries as the frontier, each with its options and recommendation. That round is an ask the session already makes, so it also carries the batched question for every waiting discovered-work item (`modules/discovered-work.md`, 00.25). Patch entries in the same pass are moot: the code is re-derived after the spec changes.

### 6.2 Third pass still has non-trivial findings (4.6)

If pass `n` is 3 or more and any **patch** entry is verified `high`, the problem is upstream. A further pass runs only after a high-severity patch, so a pass whose patches are all `medium` or `low` goes on to 6.3. Run step 7, then:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 4.6
```

Edit `.workflow/specs/NNN-slug/spec.md` frontmatter to `followup_review_recommended: true` (the only key you change), then

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug draft --step 4.6
```

Set the outcome line to `loop back (4.6 third pass)` and load `modules/questioning-loop.md` at 0.3.8 with the open patch entries as the frontier.

### 6.3 Rework attempts remain (4.7 Yes)

**Wording patch first.** When every **patch** entry is `low`, is wording only (a comment or a name; fixing it changes no behaviour) and its smallest fix is the new text itself, patch it yourself instead of reopening tasks; the rework count is untouched:

1. Run step 7 (4.8) to record the pass's gaps.
2. In the spec checkout, on the spec branch, make each edit exactly as its fix gives it, and nothing else.
3. Run the toolchain of the work type that owns each edited path: `.agents/skills/feature-workflow/scripts/run-toolchain.sh --spec-dir .workflow/specs/NNN-slug --task-id wording-p<n> --work-type <work_type> --cwd <that checkout>`. Exit 1: the edit broke a check, so undo your edits by hand and continue with the rework below for those entries.
4. Commit there with a Conventional Commit subject and the finding ids in the body (`docs: <the wording change>`, body `F<n>, F<m>: wording patch from review pass <n>`).
5. Set the outcome line to `clean, to sign-off`, add the line `Patched directly: F<n>, F<m> (<short sha>)` under it, and load `modules/sign-off.md`.

**Rework.** If any **patch** entry remains and rework used is below 5: run step 7 (4.8) to record the pass's gaps, then reopen each task that owns a patch location. Find the owner from the history since the baseline (`git log --format='%H %s' <baseline_revision>..HEAD -- <path>`, where each worktree merge names its task id), falling back to the task (never a `split-out` one) whose `module` in `.workflow/specs/NNN-slug/tasks.md` owns the path under `.workflow/rules.md`. For each owning task:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh set-task .workflow/specs/NNN-slug T<n> --status in-progress --step 4.7
```

`set-task` allows `done` to `in-progress` only with `--step 4.7`. Set the outcome line to `rework <used + 1> of 5` and load `modules/implementation-waves.md` for those tasks (its Rework entry), handing it each patch as one line: `<file:line> - <what is wrong> - <what the smallest fix must do>`. The wave loop relaunches `implementation`, re-runs the gates, sets `in-review` again at 3.11 (or 3.14), and returns here. When a patch entry is verified `high`, that return starts pass `n + 1`; when none is, Phase 4 ends after the rework (step 1, "After a rework with no verified high patch").

### 6.4 Rework ceiling reached (4.7 No)

If **patch** entries remain and rework used is 5:

- **Verified high entries are open**:

  ```bash
  .agents/skills/feature-workflow/scripts/status-transition.sh status .workflow/specs/NNN-slug blocked --step 4.7 --blocked "Rework ceiling (5) reached with verified high-severity findings open: F<n>, F<m>. A human decides at sign-off whether to accept them as known gaps."
  ```

  Set the outcome line to `blocked (4.7)`.
- **No verified high entry is open**: the spec stays `in-review`; set the outcome line to `open items, to sign-off`.

Either way, every open patch entry goes to `modules/discovered-work.md` as a convoluted item (five reworks did not land it), with its verified severity, and becomes a known gap at 5.1. Tell the stakeholder which findings are open and why.

### 6.5 Nothing left to fix

If only dismissed, proposal and discovered-work entries remain, set the outcome line to `open items, to sign-off` (or `clean, to sign-off` when every entry was dismissed and no lens failed).

## 7. Record the gaps (4.8)

Run step 7 once per pass, before the exit that needs it:

```bash
.agents/skills/feature-workflow/scripts/status-transition.sh step .workflow/specs/NNN-slug 4.8
```

No file is written here: no shelf file, no backlog line. The gaps are the lenses' `not_verifiable` requirements and targets that could not be measured. A gap you can settle with one command (a live call to the host, a terminal check, a probe in a scratch worktree) is settled now: write the command and its result as the evidence of a new triage row, verified like any finding. List the rest under the pass's table in one line, `Gaps: <each gap, its lens and what would settle it>` (or `Gaps: none`); 5.4 reports them as known gaps. A gap is never asked about on its own: a stakeholder who wants one shelved says so at 5.5.

Done when the pass has its `Gaps:` line. After an exit in 6.4 or 6.5, or a rework with no verified high patch (step 1), load `modules/sign-off.md`. A spec set `blocked` at 6.4 continues there only with the stakeholder present: 5.1 lifts the block.
