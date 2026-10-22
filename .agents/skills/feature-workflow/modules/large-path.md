# Large path

Plan one **initiative**: a subject too large or too uncertain for one spec. You explore its questions in rounds across sessions, keep what is known, unknown and decided in its folder, and emit each settled **slice** as an ordinary spec that then runs the light or full path on its own. The large path plans; it never builds. You are done when the initiative is `done` on the main branch, or when the session ends with every change committed on the initiative branch.

The initiative folder is `.workflow/initiatives/NNN-slug/`: `initiative.md` (status, origin, branch, `merge_pr`, the slice records, the goal and the table of emitted specs), `questions.md` (the initiative questions), `design-log.md` and `codebase-map.md`. Templates: [../assets/initiative.md](../assets/initiative.md) and [../assets/questions.md](../assets/questions.md).

## Conventions

- **One writer.** `IT` below is shorthand for `.agents/skills/feature-workflow/scripts/initiative-transition.sh`, and `ST` for `.agents/skills/feature-workflow/scripts/status-transition.sh`: type the full path every time from the project root, because sandboxed projects allow those exact command lines. Initiative status, the marker `.workflow/initiatives/NNN-slug/.step`, and the state of every slice and question change only through `IT`:

  ```text
  IT status       .workflow/initiatives/NNN-slug <exploring|planned|done> [--step <6.x>]
  IT step         .workflow/initiatives/NNN-slug <6.x>
  IT set-slice    .workflow/initiatives/NNN-slug S<n> [--status <planned|emitted|done>] [--spec <NNN-slug>]
  IT set-question .workflow/initiatives/NNN-slug IQ<n> [--state <open|researching|settled>] [--settled <text>] [--launched <task_type>|clear]
  IT set-pr       .workflow/initiatives/NNN-slug <url>|null
  ```

  Exit 0 done; 1 environment or usage error; 2 illegal transition, reason on stderr. On 1 or 2 stop and report; never retry another way to get past it. A new question or slice record is added by hand (questions.md at any step, initiative.md at a writer step below) with its first state; from then on its state changes only through `IT`.
- **Set the step, then write.** Run `IT step .workflow/initiatives/NNN-slug <6.x>` as you enter each step. The guards allow a Write or Edit of `initiative.md` only at a writer step, and a glossary write only at the term-gate step:

  | Step | Title | Writes `initiative.md` | Term gate |
  | --- | --- | --- | --- |
  | 6.1 | Enter the initiative | yes (at conversion) | no |
  | 6.2 | Write back research | no | no |
  | 6.3 | Compute the frontier | no | no |
  | 6.4 | Launch research and fact lookups | no | no |
  | 6.5 | Ask the round | no | no |
  | 6.6 | Term gate | no | yes |
  | 6.7 | Plan the slices | yes | no |
  | 6.8 | Log and commit the round | no | no |
  | 6.9 | Emit a settled slice | yes | no |
  | 6.10 | Mark the initiative planned | no | no |
  | 6.11 | Merge into main | no | no |
  | 6.12 | Reopen exploration | no | no |
  | 6.13 | Close when every spec is done | no | no |

  `questions.md`, `design-log.md` and `codebase-map.md` are unguarded. `.step` is never written by Write or Edit.
- **Progress line.** Lead each step update to the stakeholder with the line `.agents/skills/feature-workflow/scripts/step-progress.sh <6.x>` prints (`Large path · step n of m — <title> (6.x)`).
- **Main ref.** `main` is `.agents/skills/feature-workflow/scripts/rules-setting.sh main_branch`. When an `origin` remote exists, fetch first; the **main ref** is then `origin/<main>` if that ref exists, else `<main>`. Every new initiative branch starts from the main ref, and every "done on main" check reads the main ref with `git show`, never the working tree, because a spec is `done` on its own branch before it is merged:

  ```bash
  main=$(.agents/skills/feature-workflow/scripts/rules-setting.sh main_branch)
  git remote get-url origin >/dev/null 2>&1 && git fetch -q origin
  main_ref=$main; git rev-parse -q --verify "refs/remotes/origin/$main" >/dev/null && main_ref=origin/$main
  spec_done_on_main() { [ "$(git show "$main_ref:.workflow/specs/$1/spec.md" 2>/dev/null | yq --front-matter=extract '.status')" = done ]; }
  ```

- **Commit point.** Initiative files are committed only on `initiative/NNN-slug`, and only the initiative folder: at conversion, after each round, at each emission and at each status change. An emitted spec folder is never added. `task_review` (`.agents/skills/feature-workflow/scripts/rules-setting.sh task_review`) decides the push, as it does for task branches:

  ```bash
  git add .workflow/initiatives/NNN-slug && git commit -m "initiative NNN-slug: <event>"
  git push -u origin initiative/NNN-slug   # task_review pr or pr-blocking, and an origin remote exists; never under local
  ```

- **Launches** carry `spec_dir: .workflow/initiatives/NNN-slug` in the launch header, and run only while the checkout is on the initiative branch (the launch check needs the folder on disk). On Codex the `task_name` is `i<NNN>_<task type with - as _>`, for example `i004_research`, `i004_fact_lookup`.
- **Sub-agents never write.** The main session writes every file from their returns.

## 0.3.23 Convert a spec into an initiative

Entered from the questioning loop, when the stakeholder agrees that the draft spec is several features (a conversion question in a round, or "One feature?" answered No at 0.3.19). The spec must be `draft` and never committed: `spec_branch` is `""`. A spec that already has a branch carries committed work; settle the extra features at the scope gate (0.3.16) instead.

1. **Mark the spec.** `ST step .workflow/specs/NNN-slug 0.3.23`, with the spec's own folder. Below, `<spec NNN-slug>` is that spec's folder name and `NNN-slug` the new initiative's.
2. **Number and branch.** Fetch and compute the main ref (Conventions). The initiative number is one above the highest `NNN` among `.workflow/initiatives/[0-9][0-9][0-9]-*/`, the `initiative/*` branches (`git for-each-ref refs/heads/initiative refs/remotes/origin/initiative`) and the main ref's `.workflow/initiatives/` (`git ls-tree --name-only "$main_ref" .workflow/initiatives/`), zero-padded (`001` when there are none). The slug is the spec's slug unless the stakeholder names a better one. Check that no tracked file is modified (`git status --porcelain --untracked-files=no` prints nothing; the untracked spec folder travels with the switch), then:

   ```bash
   # --no-track: without it the branch would track the main branch, and a later plain pull or push would go to main.
   git switch --no-track -c initiative/NNN-slug "$main_ref"
   ```

3. **6.1 Create the folder** (`mkdir -p .workflow/initiatives/NNN-slug`), then:

   ```bash
   IT step .workflow/initiatives/NNN-slug 6.1
   # Copy the initiative and questions templates into the folder. In the initiative file set origin: <spec NNN-slug>,
   #   created: <date -u +%F>, branch: initiative/NNN-slug, merge_pr: null, slices: []; the title, and the spec's Why as the goal.
   IT status .workflow/initiatives/NNN-slug exploring --step 6.1
   ```

4. **Move the record in.** `mv` the spec's `design-log.md` and `codebase-map.md` into the initiative folder. In the moved log, replace the line `Spec: [spec.md](spec.md)` with `Initiative: [initiative.md](initiative.md)` (the one edit of an earlier line, because the spec it linked is deleted). Decisions keep their `D<n>` ids; later rounds continue the numbering.
5. **Re-point every reference to the spec.** Shelf items: [deferred-handoff](deferred-handoff.md#re-point-at-conversion) **Re-point at conversion**. A work item that seeded the spec (`.workflow/specs/work-backlog/*.md` whose `promoted_to` names the spec folder): set `promoted_to: .workflow/initiatives/NNN-slug` and change nothing else. Then append to the moved log the `Origin: converted from spec <NNN-slug>` entry, shaped as in [../assets/design-log.md](../assets/design-log.md): the spec folder at step 0.3.23, the new initiative and its branch, the spec's number as consumed, the reason it is several features (with the round that showed it), and the items re-pointed here.
6. **Delete the spec folder** (`rm -rf .workflow/specs/<spec NNN-slug>`). Its number is never reused: discovery 0.1.1 counts each initiative's `origin`.
7. **Commit point** (`converted from spec <spec NNN-slug>`).

Done when the checkout is on `initiative/NNN-slug`, the commit holds only `.workflow/initiatives/NNN-slug/**`, the initiative is `exploring` at 6.1, and no shelf item or work item names the deleted spec folder. Continue at 6.2.

## 6.1 Enter the initiative

Entered from the router: a request names an initiative, or the stakeholder picks one from the resume offer. Fetch and compute the main ref (Conventions), then read the status where the initiative lives: on the local branch `initiative/NNN-slug` when it exists; else on the main ref; else on `origin/initiative/NNN-slug` (an initiative in exploration this checkout has not switched to yet). For a ref: `git show "<ref>:.workflow/initiatives/NNN-slug/initiative.md" | yq --front-matter=extract '.status'`.

- **`exploring`.** Already on `initiative/NNN-slug`: stay. Otherwise check that no tracked file is modified (as at 0.3.23 step 2; if some are, ask the stakeholder to commit or stash them first), then `git switch initiative/NNN-slug` (when the branch exists only on `origin`, `git switch` creates the local branch tracking it). Continue at 6.2.
- **`planned`, local branch still present.** The 6.11 merge has not landed (a `pr-blocking` approval is pending): switch to the branch as above and resume 6.11.
- **`planned`, merged.** Go to 6.13 without switching; offer 6.12 when the stakeholder wants to reopen.
- **`done`.** Read it as context only. New work on the subject is a new request.

## The round

### 6.2 Write back research

`IT step .workflow/initiatives/NNN-slug 6.2`. For each question in `researching`: when its agent's return is in this session (the agent finished, or the session was resumed with its history), settle it with the finding and its source; otherwise put it back to `open` so 6.4 launches it again.

```bash
IT set-question .workflow/initiatives/NNN-slug IQ<n> --state settled --settled "<finding> (<path:line or URL>)"
IT set-question .workflow/initiatives/NNN-slug IQ<n> --state open --launched clear
```

Done when no question is `researching` without a live agent behind it.

### 6.3 Compute the frontier

`IT step .workflow/initiatives/NNN-slug 6.3`. The **frontier** is every `open` question whose `depends_on` are all met: an `IQ<n>` is met when it is `settled`, a spec `NNN-slug` when it is `done` on the main ref. With the main ref computed (Conventions):

```bash
yq --front-matter=extract '([.questions[] | select(.state == "settled") | .id]) as $s
  | .questions[] | select(.state == "open") | .id + " " + (((.depends_on // []) - $s) | join(" "))' \
  .workflow/initiatives/NNN-slug/questions.md |
while read -r id unmet; do
  ready=yes
  for dep in $unmet; do case $dep in IQ*) ready=no ;; *) spec_done_on_main "$dep" || ready=no ;; esac; done
  [ "$ready" = yes ] && echo "$id"
done
```

Order it as the questioning loop orders its frontier ([0.3.8](questioning-loop.md#the-round)): questions that change scope or unblock the most lead. Done when the list is ordered; an empty frontier means nothing open is answerable now: go to 6.8.

### 6.4 Launch research and fact lookups

`IT step .workflow/initiatives/NNN-slug 6.4`. For each `research` question on the frontier, mark it launched, then launch one `research` agent per question, all in one message:

```bash
IT set-question .workflow/initiatives/NNN-slug IQ<n> --state researching --launched research
```

````markdown
```yaml launch-header
task_type: research
spec_dir: .workflow/initiatives/NNN-slug
```

Question: IQ<n>: <the question, verbatim from questions.md>
Goal: <the initiative's goal, from initiative.md>
Settled: <IQ<n>: its settled line, one per question it depends on, or "none">
````

The body carries exactly the inputs `.agents/agents/research.md` lists, and its return format is fixed there. A research question may stay `researching` when the session ends: 6.2 of a later session writes it back.

For `decision` questions that need a fact from the repo, launch one `fact-lookup` with them numbered, exactly as [0.3.10](questioning-loop.md#the-round) shows, with the initiative folder as `spec_dir`. An **Answer + Source** settles the question (`--state settled --settled "<answer> (<source>)"`) and it is never asked.

Done when every `research` question on the frontier is `researching` and every fact lookup has returned.

### 6.5 Ask the round

`IT step .workflow/initiatives/NNN-slug 6.5`. Ask every `decision` question still on the frontier in one round, in the questioning loop's format ([0.3.11](questioning-loop.md#the-round)): options, your recommendation first and marked "(Recommended)" with its reason and source, "Defer to deep dive", worded so "yes" accepts the recommendation. Settle each answer verbatim:

```bash
IT set-question .workflow/initiatives/NNN-slug IQ<n> --state settled --settled "<the stakeholder's answer, verbatim>"
```

Take deferred questions one at a time after the round, as the loop's deep dives do. An answer that raises a new question: append it to `questions.md` with the next unused `IQ<n>`, its `kind`, `state: open`, its `depends_on` (questions, or an emitted spec it waits for), `launched: null`, `settled: null`. An answer that puts work outside the initiative's goal: [deferred-handoff](deferred-handoff.md#write) **Write**, with the initiative folder as `origin_spec`.

Done when every decision on the frontier is settled or deferred, and every deep dive is answered.

### 6.6 Term gate

For each answer that introduces a new or conflicting term: `IT step .workflow/initiatives/NNN-slug 6.6`, then invoke the `domain-modeling` skill for the term gate. It agrees the term with the stakeholder and writes `.workflow/GLOSSARY.md` under this step. Done when every raised term is agreed.

### 6.7 Plan the slices

When the round settled how the subject divides: `IT step .workflow/initiatives/NNN-slug 6.7`, then Edit `initiative.md`. A new slice is a record `{id: S<n>, title: "<two to eight words>", status: planned, questions: [IQ<n>, ...], depends_on: [S<n>, ...], spec: null}` with the next unused `S<n>`; for a `planned` slice you may change its title, `questions` and `depends_on`. An emitted slice is never edited. `depends_on` between slices records the planned order only; nothing blocks on it. Revise the goal here when the round changed it. Done when every slice the stakeholder agreed is a record and each names the questions that must settle before it is emitted.

### 6.8 Log and commit the round

`IT step .workflow/initiatives/NNN-slug 6.8`. Append the `Initiative round <n>` entry to `design-log.md`, shaped as in [../assets/design-log.md](../assets/design-log.md): the round's frontier, one block per question asked or launched (a research question's result is its settled line with the source, or "left researching"), the slices planned or changed at 6.7, and the questions still researching. Decision ids continue the log's `D<n>` sequence. Facts that settled a question at 6.4 go in that question's block.

Then the commit point (`round <n>`). Route on what the record now says:

- A `planned` slice whose questions are all `settled`: offer to emit it (6.9).
- Otherwise, a question `open`: run the next round from 6.2 (or end the session; the next one resumes here).
- Only `researching` questions remain: the session may end; a later session writes them back at 6.2.
- No question `open` or `researching` and every slice `emitted` or `done`: 6.10.

## 6.9 Emit a settled slice

Ask the stakeholder to confirm the slice: its title, the questions it carries and their settled lines. On Yes:

1. **Commit first.** Any initiative change still uncommitted lands now (commit point), so the initiative commit is in place before the new spec's folder exists.
2. **Seed the spec.** Run discovery 0.1.1–0.1.6 seeded from the slice ([Seeded from a slice](discovery.md#seeded-from-a-slice)). It creates `.workflow/specs/<new NNN-slug>/` at `draft` with `initiative: NNN-slug` in its frontmatter, the Why drafted from the slice and an Origin entry carrying the binding decisions, and hands the folder name back. The folder stays uncommitted in the working tree until its own spec branch exists.
3. **Record it.**

   ```bash
   IT step .workflow/initiatives/NNN-slug 6.9
   IT set-slice .workflow/initiatives/NNN-slug S<n> --status emitted --spec <new NNN-slug>
   ```

   Add the spec's row to the table of emitted specs in `initiative.md` (`| S<n> <title> | [<new NNN-slug>](../../specs/<new NNN-slug>/spec.md) |`), and append to `design-log.md`: `## YYYY-MM-DD Emission: S<n> as <new NNN-slug>` with the questions it carried.
4. **Commit point** (`emitted S<n> as <new NNN-slug>`), adding only `.workflow/initiatives/NNN-slug`.
5. **Stay or step in.** Stay in the initiative and continue at the routing in 6.8, unless an `open` question lists the new spec in `depends_on`: then tell the stakeholder, and the new spec runs through the router like any draft spec; the initiative resumes at 6.1 once that spec is `done` on main.

Done when the slice is `emitted` with its spec, the emission commit lists only initiative files, and the spec folder is untracked in the working tree.

## Planned and merged

### 6.10 Mark the initiative planned

When every slice is `emitted` or `done` and no question is `open` or `researching`:

```bash
IT status .workflow/initiatives/NNN-slug planned --step 6.10
```

Commit point (`planned`). Continue at 6.11.

### 6.11 Merge into main

The same sequence merges `planned` here and `done` at 6.13; `<state>` is the one being merged. For `planned`, first run `IT step .workflow/initiatives/NNN-slug 6.11`; for `done` skip it, since a `done` initiative refuses every `IT` call. Read `task_review`:

- **`pr` or `pr-blocking`.** Open the PR/MR through the generic mode of `open-task-pr.sh`; it pushes the branch, picks gh or glab from the `origin` host, reuses an open PR/MR, and prints the URL or `skipped: <reason>`. For `planned`, `--record` writes the URL to `merge_pr`; commit and push that (commit point, `merge PR recorded`) so the PR carries it. For `done`, leave out `--record`.

  ```bash
  .agents/skills/feature-workflow/scripts/open-task-pr.sh --head initiative/NNN-slug --base "$main" --title "Initiative NNN-slug: <state>" --record .workflow/initiatives/NNN-slug
  ```

  `pr-blocking`: wait for approval as task PRs do at [3.16](implementation-orchestrator.md#316-merge-the-wave), and tell the stakeholder which PR/MR waits. `skipped: <reason>`: append the reason to `design-log.md`, commit it, and merge as `local` does.
- **`local`.** No push and no PR/MR.

Then merge, with `--no-ff` so main keeps one merge commit per state:

```bash
git switch "$main"
git merge --ff-only "origin/$main"            # only when the origin/<main> ref exists
git merge --no-ff -m "Merge initiative NNN-slug (<state>)" initiative/NNN-slug
git push origin "$main"                       # pr and pr-blocking: the PR/MR shows as merged; never under local
git branch -d initiative/NNN-slug
```

A refused push (a protected main branch) is reported to the stakeholder; the PR/MR stays open for them to merge on the host. Done when main carries the initiative at `<state>`, the local branch is deleted, and the stakeholder knows where the PR/MR or the merge commit is.

### 6.12 Reopen exploration

When the stakeholder reopens a `planned` initiative (a new question, a slice to add): check that no tracked file is modified, fetch and compute the main ref, re-create the branch from it, and set the status:

```bash
git switch --no-track -c initiative/NNN-slug "$main_ref"
IT status .workflow/initiatives/NNN-slug exploring --step 6.12
```

Append `## YYYY-MM-DD Reopened: <the stakeholder's reason, verbatim>` to `design-log.md`, add the new questions to `questions.md`, commit point (`reopened`), then run a round from 6.2.

### 6.13 Close when every spec is done

On resume of a `planned` initiative that has merged, and from sign-off once a spec carrying `initiative:` has merged into main. Fetch and compute the main ref, then read the initiative's status there:

```bash
git show "$main_ref:.workflow/initiatives/NNN-slug/initiative.md" 2>/dev/null | yq --front-matter=extract '.status'
```

- **Empty or `exploring`** (empty: the initiative has not reached main yet). This is the usual case when an initiative's first emitted spec signs off while its questions are still open. Tell the stakeholder the initiative is still exploring, name its emitted specs not yet `done` on main (the `spec` of each slice in `initiative.md` on `initiative/NNN-slug`, local or on `origin`), and write nothing: there is nothing to close, and the branch it would re-create still exists.
- **`done`.** Already closed; write nothing.
- **`planned`, branch tip `exploring`.** Before listing specs, read the status at the branch tip, from `refs/heads/initiative/NNN-slug` when it exists, else from `refs/remotes/origin/initiative/NNN-slug`:

  ```bash
  tip=refs/heads/initiative/NNN-slug
  git rev-parse -q --verify "$tip" >/dev/null || tip=refs/remotes/origin/initiative/NNN-slug
  git show "$tip:.workflow/initiatives/NNN-slug/initiative.md" 2>/dev/null | yq --front-matter=extract '.status'
  ```

  `exploring` there means the initiative was reopened at 6.12 and is still exploring, whatever main says. Tell the stakeholder so, name its emitted specs not yet `done` on main (read from `initiative.md` at that tip, as for `exploring`), and write nothing. Whether the branch exists decides nothing: under `pr` the merged PR leaves the `planned` tip on `origin`.
- **`planned`, no branch or any other tip status.** List the emitted specs not yet `done` on main:

  ```bash
  for spec in $(git show "$main_ref:.workflow/initiatives/NNN-slug/initiative.md" | yq --front-matter=extract '.slices[].spec'); do
    spec_done_on_main "$spec" || echo "$spec"
  done
  ```

  - **Some listed.** Tell the stakeholder which specs are still open and write nothing; offer 6.12 if they want to reopen.
  - **None listed.** Re-create the branch from the main ref (after the clean check, as at 6.12), then flip:

    ```bash
    git switch --no-track -c initiative/NNN-slug "$main_ref"
    IT step .workflow/initiatives/NNN-slug 6.13
    IT set-slice .workflow/initiatives/NNN-slug S<n> --status done   # once per slice
    IT status .workflow/initiatives/NNN-slug done --step 6.13
    ```

    Commit point (`done`), then merge it as 6.11 does with `<state>` = `done`. `done` is final: every later `IT` call exits 2.

Done when main carries the initiative at `done` with every slice `done` and the local branch is deleted, or the stakeholder has been told that the initiative is still exploring or which specs are still open.

## Done

- Every status, step, slice and question change went through `IT`; every `initiative.md` edit happened at a writer step and every glossary write at 6.6.
- Every initiative commit holds only `.workflow/initiatives/NNN-slug/**` and sits on `initiative/NNN-slug`; no emitted spec folder was committed there.
- Every round is a dated Initiative round entry in `design-log.md`; every emitted spec carries `initiative:` and is linked from `initiative.md`.
- `planned` and `done` reached main by the route `task_review` names, and the local initiative branch was deleted after each merge.
