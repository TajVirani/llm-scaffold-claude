# Shared files

All workflow data lives under one committed folder, `.workflow/`; create it first (`mkdir -p .workflow`). Create each file only when it is absent; an existing file is kept and reported as "kept". `A` = `.agents/skills/project-setup/assets`.

| Target | Source | What to do when creating it |
| --- | --- | --- |
| `.workflow/GLOSSARY.md` | `A/GLOSSARY.md` | Replace `{Context name}` and the one-line description with the human's answer. Leave the comment block: `domain-modeling` deletes it when the first term is added. |
| `.workflow/capabilities.md` | `A/docs/capabilities.md` | Delete the example `CAP-001` row, so the table has its header only. 5.3 numbers the first real capability `CAP-001` (highest + 1). |
| `.workflow/rules.md` | `A/docs/rules.md` | Copy as is, then ask the PR template question (see "PR template" below). `project-standards` fills the rest at step 6 of the skill (see "Rules" below). |
| `.workflow/decisions/pitfalls.md` | `A/docs/decisions/pitfalls.md` | Copy as is. The comment holds the entry shape the retrospective follows at 5.7. |
| `.workflow/review-lessons.md` | `.agents/skills/feature-workflow/assets/review-lessons.md` | Copy as is. The header holds the entry rules and the commands the retrospective follows at 5.7; a project set up before this file existed gets it from the retrospective at its next 5.7. |
| `.workflow/deferred/.gitkeep` | none | Create an empty file so git keeps `.workflow/deferred/`. `.workflow/deferred/archive/` is created when the first item is archived (00.9). |
| `.workflow/agent-overrides.yaml` | `A/agent-overrides.yaml` | Copy as is: comments only, no entries. |
| `.workflow/profiles/TEMPLATE.md` | `A/profiles/TEMPLATE.md` | Copy as is (00.16). Profiles are filled from it in [profiles.md](profiles.md). |

There is no `.workflow/decisions/status.md`. `.workflow/decisions/adr/` and `.workflow/decisions/retrospectives/` are created when their first file is written. `.workflow/cache/` and `.workflow/specs/` are created by the flow.

Write Tier A files under `.workflow/` with Write or Edit, so the guard sees each write.

## Multi-context glossary

Default to one root `.workflow/GLOSSARY.md`. Only when step 2 found monorepo signals, offer the multi-context layout: a root `.workflow/GLOSSARY-MAP.md` that lists one `GLOSSARY.md` per context, each in that context's own directory. Create those files from the same template on a yes. The format is in `.agents/skills/domain-modeling/assets/GLOSSARY-FORMAT.md`.

## Rules

`.workflow/rules.md` is copied unfilled; `project-standards` fills Ownership, Shared core and the policy sections from discovery and the human's answers. Its fixed headings and `yaml` blocks are a parsed contract: `generate-boundary-config.sh` at step 10 parses them, and a new project with no modules keeps `modules: {}`, which generates an empty but valid boundary config.

## PR template

Only when `.workflow/rules.md` was created now. A kept rules.md is never touched; its `pr_template` changes through a proposal at sign-off (5.2, approved at 5.3).

1. Look for host PR/MR templates at these paths only: `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE/*.md` and `.gitlab/merge_request_templates/*.md`.
2. None found: ask nothing. The commented `pr_template` line stays, so the key reads its default, `workflow`.
3. One or more found: ask once which template the sign-off PR/MR description follows. Offer each found path, repo-relative, plus `workflow` (the workflow's own ten-section template), and lead with your recommendation.
4. Write the answer into the `## Workflow settings` block of `.workflow/rules.md`: replace the commented `# pr_template: workflow` line with `pr_template: <answer>`, keeping its trailing comment. Then check it reads back: `.agents/skills/feature-workflow/scripts/rules-setting.sh pr_template` prints the answer.

This is the one write to `.workflow/rules.md` that bypasses the `project-standards` ledger. The file is a fresh, unfilled copy, the human picks the value directly from the offered choices, and the key is a workflow setting rather than a project standard, so a ledger row would only repeat the same question.

Done when every file in the table exists, either created now or kept, and a created rules.md holds the `pr_template` answer when a host template was found.

## Tracker

Step 11 of the skill. It writes `.workflow/issue-tracking.yaml`, the settings that say whether specs and tasks are filed as tracker issues and which three labels make the issue flow. The `issue-tracking` skill's "Tracker setup" section explains each exit of the script.

1. **Kept.** When `.workflow/issue-tracking.yaml` exists, ask nothing and run nothing: report it as kept. `save` replaces the file, so never run it over an existing one.
2. **Already under way.** When step 2 found any spec under `.workflow/specs/` (in progress or in `done/`), run nothing here and report the step as skipped. Tell the human to run the `issue-tracking` skill's Tracker adoption, which also gives the existing specs tracker numbers. A plain `save` would leave those specs on numbers the tracker never handed out.
3. **Check.** Run:

   ```bash
   .agents/skills/issue-tracking/scripts/tracker-setup.sh check
   ```

   Exit 0 prints the host (`github` or `gitlab`) on its first line. Exit 1 gives the reason on stderr (no tracker host on `origin`, the CLI missing, too old or not logged in, or issues turned off): tell the human, and offer to check again once they fix it, or to go without a tracker.
4. **Ask once.** In one question, ask whether to use the tracker and which three labels make the issue flow. Lead with your recommendation: use the tracker, with `backlog`, `in-progress` and `done`, or the project's own labels when the human already has names for those three states. When `check` failed and the human does not fix it, the question is only whether to go without a tracker.
5. **Save.** With a yes, run:

   ```bash
   .agents/skills/issue-tracking/scripts/tracker-setup.sh save --backlog <label> --in-progress <label> --done <label>
   ```

   When it exits 1 naming labels the tracker lacks, it has written nothing. Ask whether to create those labels; only with the human's yes, run the same `save` again with `--create-labels`. With a no, ask for existing label names and save again, or go without a tracker.

   Without a tracker, run `.agents/skills/issue-tracking/scripts/tracker-setup.sh save --none`, which writes `issue_tracker: none`. The workflow then numbers specs from the local checkout, as it does with no settings file.

Done when `.workflow/issue-tracking.yaml` was kept, or `save` printed `saved <file>`, or the step was skipped for a project already under way and the human was pointed at Tracker adoption.
