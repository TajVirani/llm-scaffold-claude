# Skill and agent mechanics

What changes when the document is a skill or a sub-agent definition. The writing itself follows [../SKILL.md](../SKILL.md).

## Frontmatter

Frontmatter is the first thing in the file and must parse as YAML.

- **Skill** (`.agents/skills/<name>/SKILL.md`): `name` equals the folder name; `description` is non-empty. Template: [../assets/SKILL.template.md](../assets/SKILL.template.md).
- **Sub-agent definition** (`.agents/agents/<name>.md`): `name` equals the file name; `description` says what the agent returns, when to launch it, and which neighbouring agent to use instead; `tools` lists only what the task needs. Leave out `model:`; a definition that must pin a model uses `models:` with only `claude` and `codex` keys. The body is the agent's whole prompt: it sees nothing of the parent conversation, so state its input, its steps and its return shape. Template: [../assets/agent.template.md](../assets/agent.template.md).
- Codex reads only `name`, `description` and the body of a definition (its agent name maps `-` to `_`). Re-run `.agents/hooks/generate-codex-agents.sh` after editing one.
- Record what a skill or definition was adapted from (`<repo>/<path> @ <commit> (<licence>)`) in the repo's provenance or lineage file, not in the file the agent loads: a header comment costs context on every load and changes nothing the agent does. Keep the licence notice beside the file when you keep substantial upstream text. Leave decision ids and design-doc paths out of the body too, unless the agent must open that document.

## Invocation

Two choices, trading the two loads:

- **Model-invoked** (the default): the `description` stays loaded, so the agent fires the skill on its own and other skills can reach it; the human can still type its name. Permanent context load buys discoverability. A model-invoked skill that is all reference is one home for reference several skills share. Write the description for the model: what it is, then one trigger per branch.
- **User-invoked**: only the human can fire it, and no other skill can. Zero context load; the human pays the cognitive load of remembering it. Claude Code: `disable-model-invocation: true` in the frontmatter. Codex: `policy: allow_implicit_invocation: false` in `agents/openai.yaml`. The description becomes a one-line human summary.

Pick model-invocation only when the agent or another skill must reach the skill. Reference that two user-invoked skills both need lives in neither: put it in a plain file both can point at.

## Splitting by invocation

Split off a model-invoked skill when a distinct leading word you actually use should trigger it on its own, or another skill must reach it. The new always-loaded description has to be worth its context load.

## Router skills

When user-invoked skills multiply past what anyone remembers, add one user-invoked **router skill** that names the others and when to reach for each. It can only hint: nothing but the human fires a user-invoked skill.
