---
name: writing-for-agents
description: Write documents agents run. Use when creating or editing a skill, a sub-agent definition, AGENTS.md or CLAUDE.md, or a doc an agent reaches through a pointer.
---

<!--
Sources: adapted from mattpocock/skills skills/productivity/writing-for-agents/{SKILL,SKILL-MECHANICS}.md @ 49dd158d1076134a641b33efb035946536778336 (MIT, Copyright (c) 2026 Matt Pocock; notice in ./LICENSE). Changes: condensed; added "Where things live" (the .agents/ layout, AGENTS.md with CLAUDE.md as a one-line import, Claude Code and Codex), frontmatter rules, templates in assets/ and the "Finish" check; skill mechanics moved to references/skill-mechanics.md with agent definitions and Codex invocation added.
-->

# Writing for agents

Reference for any document an agent runs: a skill, a sub-agent definition, `AGENTS.md`, a doc behind a pointer. The packaging differs; the writing does not. The goal is a predictable _process_: the agent takes the same path every run, even when the output differs.

Writing a skill or an agent definition: also read [references/skill-mechanics.md](references/skill-mechanics.md) (frontmatter, invocation, splitting, routers) and start from the template in `assets/`.

## Where things live

- `.agents/` holds everything an agent runs: `skills/<name>/SKILL.md`, `agents/<name>.md` (sub-agent definitions), `hooks/`, `output-styles/`. Write here, for every host.
- `.claude/` is a Claude Code shim (settings plus symlinks into `.agents/`). Write nothing there that another agent would need.
- Codex reads `.agents/skills/` natively. Its agent files (`.codex/agents/*.toml`) are generated from `.agents/agents/*.md` by `.agents/hooks/generate-codex-agents.sh`; edit the `.md` and re-run it.
- `AGENTS.md` is the project instructions, read by both hosts. `CLAUDE.md` is the single line `@AGENTS.md`; edit `AGENTS.md`. Codex caps `AGENTS.md` at 32 KiB, one more reason to keep it a set of pointers.
- Inside a skill: steps in `SKILL.md`, or in `modules/` when only one route needs them; disclosed reference in `references/`; templates in `assets/`; executables in `scripts/`.

## Context pointers

A **context pointer** is a line in the agent's context that names out-of-context material and the condition for reaching it. A skill description is one; an `AGENTS.md` line naming a doc is the same object. The pointer's _wording_, not its target, decides whether the agent reaches the material. A must-have target behind a weak pointer is a variance bug: sharpen the wording first, inline the material only if that fails.

A pointer says what the material is and lists the **branches** that should trigger it (a branch is a distinct case the document handles). Always-loaded pointers cost every turn, so prune them hardest:

- Front-load the leading word.
- One trigger per branch. Synonyms for one branch are one branch written twice.
- Cut identity the body already carries.

## The two loads

- **Context load**: always-loaded material (an `AGENTS.md` line, a skill description) spends tokens and attention every turn, whether or not it fires.
- **Cognitive load**: the human is the index of which documents exist and when to reach for them. Spend it where human judgement matters.

Material behind a pointer costs only the pointer's line; material with no pointer rides entirely on the human's memory.

## Information hierarchy

A document holds **steps** (ordered actions) and **reference** (rules, definitions, facts consulted on demand). Place each piece on a ladder by how immediately the agent needs it:

1. **In-file step**: what the agent does, in order.
2. **In-file reference**: consulted on demand. A flat peer-set of rules is fine.
3. **Disclosed reference**: a separate file behind a pointer, loaded only when it fires.

**Progressive disclosure** moves material down the ladder to keep the top legible. The test is branching: inline what every branch needs; disclose what only some branches reach. Reference left inline between steps buries them and makes attending to them a coin-flip.

**Co-location**: keep a concept's definition, rules and caveats under one heading. The document should read like documentation written for the agent.

**Sprawl** is a document too long even when every line is live. Cure it with the ladder: disclose, or split by branch or sequence.

## Steps and completion criteria

Every step ends on a **completion criterion**: the condition that tells the agent the step is done.

- **Clarity**: a vague bound ("understanding reached") invites **premature completion**, attention slipping to the steps still ahead. Sharpen the bound first. Only if it stays fuzzy and you observe the rush, hide the later steps behind a real context boundary (a hand-off or a sub-agent); an inline call hides nothing.
- **Demand**: "every modified model accounted for" drives more legwork than "produce a change list". Demand binds reference too: "every rule applied" sets an exhaustiveness bar on a flat rule list.

The strongest criteria are checkable and exhaustive.

## When to split

Splitting spends one of the two loads, so split only when the cut earns it:

- **By sequence**: when later steps tempt the agent to rush the current one. Merging sequences does the reverse.
- **By invocation**: see [references/skill-mechanics.md](references/skill-mechanics.md).

## Leading words

A **leading word** is a compact concept the model already knows (_tight_ loop, _red_ test, _tracer bullet_, _fog of war_). Repeated as a token, it anchors a region of behaviour in a few tokens: in the body it steers execution, and in a pointer it steers invocation when the same word lives in your prompts, docs and code. Prefer an existing word; a coined one recruits no priors and must be defined.

Hunt for restatements to collapse: "fast, deterministic, low-overhead" becomes _tight_; "a loop you believe in" becomes _red_, a binary observable state.

**Prompt the positive.** A prohibition puts the banned behaviour in context and makes it more available. State the target ("write one-line comments"). Keep a prohibition only as a hard guardrail you cannot phrase positively, and pair it with the positive target.

## Pruning

- **Single source of truth**: each meaning lives in one place. Duplication costs maintenance and tokens and inflates a meaning's rank.
- **The environment is a source of truth**: scripts, config, directory layout, `--help`. A document that restates it is a cache that goes stale. Write down what the agent cannot find by looking: the unwritten convention, the reason behind a choice, the gotcha.
- **Relevance**: every line must still bear on what the document does. Without pruning, stale layers settle as **sediment**.
- **No-ops**: a sentence the model already obeys by default says nothing. The test is model-relative: settle disagreements by running the document. Delete the whole sentence. A leading word too weak to beat the default (_thorough_) needs a stronger word (_relentless_).

## Finish

Before you stop, check the document against this list; the work is done when every item holds:

- Frontmatter passes the rules in [references/skill-mechanics.md](references/skill-mechanics.md) (skills and agent definitions).
- The file lives under `.agents/` (or is `AGENTS.md`), and every path it names exists.
- Each step ends on a completion criterion; each pointer names its branches.
- No sentence restates the environment, repeats another document, or is a no-op.
