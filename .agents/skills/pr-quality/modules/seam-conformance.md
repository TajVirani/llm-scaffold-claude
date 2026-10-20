# Seam Conformance

## Objective

Check the diff against **deep-module / seam** discipline (Ousterhout, *A Philosophy of Software
Design*). The vocabulary (module, interface, seam, depth, deletion test) is
[`references/codebase-design.md`](../references/codebase-design.md)
(a copy of the mattpocock/skills `codebase-design` glossary).

The module index is the project's own:
- `.workflow/rules.md` § Ownership — each module and the paths it `owns`.
- `.workflow/cache/modules.md` — each module's **Public interface** (the exported names of its entry
  declaration). That entry declaration is the module's **seam**: the only sanctioned way in.

Read both first. If `.workflow/rules.md` has no modules, report "not applicable — no module index
(.workflow/rules.md Ownership is empty)" and stop. If `.workflow/cache/modules.md` is missing, take each
module's entry file (its `index.*` or the module file itself) as its seam and say so in the report.

The other three modules find *shallowness smells* (size, duplication, orphans). This module
finds *seam violations*: code that reaches around a module's interface, widens it without
cause, or adds shallow new modules. Imports between modules that Ownership forbids
(`may_depend_on`) are the boundary tool's job; leave them to it.

## Checks

### 1. Reaching past a seam

Flag new imports in the diff, from outside a module's `owns` paths, that target a file *inside*
the module other than its seam (e.g. `from ".../billing/invoice-store"` instead of
`from ".../billing"`). Also flag new code that constructs or mutates a module's internals where
its public interface offers an accessor for the same thing.

Report: the file:line, which seam was bypassed, and the sanctioned entry point to use instead.

### 2. Widening a seam without cause

Flag new **public** exports added to a module's seam (a new export in its entry file, a new
public method on an accessor, a new route on a mounted service).

For each, apply the **deletion test**: would callers lose real leverage without it, or is it a
pass-through that exposes an internal? A new export that only forwards to one internal is
interface widening — recommend keeping it private or folding it into an existing entry point.

Report: the new export, and whether it earns its place at the seam or should stay internal.

### 3. Shallow new modules

Flag new modules whose **interface is nearly as complex as their implementation** — the
classic shallow module. Signals: a new file/function that mostly forwards arguments to one
other module; a new "manager/helper/util" wrapper with one caller; a new export whose body is
a thin pass-through.

Apply the deletion test: if deleting the module makes complexity *vanish* (rather than
reappear across N callers), it wasn't hiding anything.

Report: the module, why it reads as shallow, and what it should merge into.

### 4. Duplicating behaviour already behind a seam

Flag new code that re-implements something an existing module's public interface already
provides. This is duplicate-detection framed at the *module* level — the fix is to route
through the existing seam, not to copy the behaviour.

Report: the new code, the existing module that already does this, and its seam.

### 5. New subsystem without an Ownership entry

If the diff introduces a substantial new subsystem (a new directory of cooperating modules, a
new service, a new mounted endpoint) whose paths no module in `.workflow/rules.md` § Ownership
`owns`, flag it.

Report: the new subsystem and a proposed Ownership entry (module name, `owns` globs,
`may_depend_on`). Unowned code is invisible to the boundary check and to module-based review.

## What to report

For each finding:
```
- **[SEAM]** `path/to/file.ts:LINE` — [what the violation is]
  Module: [module name from .workflow/rules.md, or "unowned"]
  Seam: [the sanctioned entry point]
  Suggestion: [route through the seam / keep private / merge / add Ownership entry]
```

## What NOT to flag

- Imports *within* a module's own `owns` paths (internals may freely use each other).
- Test files reaching into internals for white-box testing — but prefer testing through the
  seam (the interface is the test surface).
- Generated files, vendored code, config, schema files.
- A module that is a single deep file — don't invent a barrel for a one-file module.
