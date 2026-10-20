# Discovery

## Brownfield, add-work-type and refresh: one agent per scope

### Pick the scopes

A **scope** is one workspace member (a `workspaces` entry, a `pnpm-workspace.yaml` package, a directory with its own build manifest) or, in a single-package repo, the repo root `.`. In add-work-type mode, the scope is the paths the new work type covers. Name the scopes to the human and ask whether this run covers all of them or which; ask only when there is more than one.

Done when the scope list is agreed.

### Launch

Launch every scope's agent in one message so they run in parallel. The prompt carries no launch header (the `standards-discovery` header is optional and holds nothing but `task_type`) and no profile. The prompt is one line, then the input block:

````
Discover the standards for this scope.

```yaml
scope: [<repo-relative paths>]
work_types: [<candidate work types>]
instruction_files: [<paths from step 1, or empty>]
since_commit: <40-hex sha>   # refresh only; omit otherwise
focus: <one area>            # optional, e.g. errors or layering
```
````

- **Claude Code**: Agent tool, `subagent_type: standards-discovery`. The pre-launch hook sets the model.
- **Codex**: resolve first, then spawn with `agent_type` `standards_discovery`, `.prompt` as the message, `.model` as the model, `task_name` `standards_<scope>` (lowercase, every character outside `[a-z0-9]` replaced by `_`) and `fork_turns: "none"`:

  ```bash
  printf '%s\n' "<the prompt above>" |
    .agents/skills/feature-workflow/scripts/resolve-launch.sh --host codex --task-type standards-discovery --no-header
  ```

  Exit 2 naming **00.14** means no model is set for `standards-discovery`: add `.workflow/model-map/standards-discovery.md` (or an `.workflow/agent-overrides.yaml` entry) and re-run.

Done when every scope has an agent running.

### Save each return

Write each return verbatim to `.workflow/.standards-staging/discovery-<scope>.md`, so a compacted session can rebuild from disk. A return of `LAUNCH ERROR: …` means the input was wrong: fix it and relaunch that scope.

Then fold the return into the baseline:

| Return section | Goes to |
| --- | --- |
| `## Modules` | Boundaries rows: `.workflow/rules.md` § Ownership, as `owns` and `may_depend_on` candidates. Shared-core candidates from `layering` rows go to § Shared core. |
| `## Conventions` | One baseline row each, with the agent's `enforce_by` as the proposed enforcement and its evidence cell. `confidence: low` and `mixed:` rows become interview questions, never rows on their own. |
| `## Versions` | `.workflow/rules.md` § Required versions rows, with the declaring `file:line` as evidence. |
| `## Contradictions` | Interview questions: show both citations and ask which one is the standard. Never pick a side yourself. |
| `## Unknowns` | Interview questions. |
| `## Discovered work` | The closing report, for the human to rule on. Never fix it in this run. |

Done when every scope's return is saved and each of its rows is a baseline row or an interview question.

## Greenfield: recommend a starter

1. From step 2's answers, name the paradigm (layered, hexagonal, pipes-and-filters, and so on) and the work types' frameworks still to decide.
2. Recommend one well-known starter that settles as many concerns as possible, plus one alternative, each with what it decides and what it leaves open. Verify the current choice on the web (WebSearch or WebFetch, or `npm view <package> version` for npm packages): the starter's current command and every version you will pin. Cite the URL or the command for each. The human picks in the first interview batch (coverage C2); the starter's choices are candidates, not settled rows.
3. Commands for a stack that does not exist yet are written as `TODO: <decided tool> <purpose>` in the Toolchain rows, never as a guessed invocation stated as fact; the first refresh after code exists verifies them.

Done when every pinned version in the baseline has a URL or command as its evidence.

## Library candidates (greenfield, and any C1 concern discovery left Unknown)

Once the human has picked each work type's framework, research every C1 concern in [../assets/coverage.md](../assets/coverage.md) for that framework before asking about it:

1. Find 2-3 current, well-maintained candidates per concern (for example, Go stdlib backend, migrations: goose, golang-migrate, atlas). Verify each on the web: latest release and its date, maintenance (commits or releases in the last year), licence, and fit with the framework and the choices already made. A candidate with no release in two years, an archived repository or a deprecation notice is dropped or flagged.
2. Recommend one per concern with a one-line reason; "the standard library" or "none" is a valid candidate when it fits.
3. Save the table to `.workflow/.standards-staging/libraries-<work-type>.md` (concern · candidates · version · URL · recommendation), so the interview cites it and a compacted session can rebuild.

Done when every applicable C1 concern of every work type has its candidates saved with a URL each.
