---
name: deps-update
description: Update and maintain a bun project's dependencies with regression validation scaled to each package's blast radius. Use when updating/bumping/upgrading packages, running bun outdated/update, checking for outdated deps, addressing a dependency CVE, or asking "is this package update safe / how do I test this bump".
disable-model-invocation: true
---

# Dependency updates (bun)

For **bun** projects (a `bun.lock` at the root; not npm, pnpm or yarn). Every package touches a different
blast radius, so the regression proof must scale to what a bad bump would silently break. That scale is the
whole point: a `@types/*` bump needs a build; a rendering-library bump needs eyes on the UI.

Validation commands come from the project, not from this skill: the Toolchain block of the work profile that
owns the touched code (`.workflow/profiles/<work-type>.md`: `lint`, `typecheck`, `format`, `test`, `e2e`, `serve`,
`serve_ready`). This skill decides *how deep to go*; the profile says *how to run it*. No profile → ask the
user for the build, lint and test commands before bumping anything.

## Workflow

1. **Discover** — `bun outdated --filter='*'`. Bare `bun outdated` reports the **root manifest only** and
   silently hides stale workspace copies; `--filter='*'` traverses every workspace and adds a Workspace column.
   Note current → latest **and every owning workspace**. Workspaces are the root `package.json` plus the
   manifests its `workspaces` globs match; ignore any other `package.json` (fixtures, examples).
2. **Detect drift** — `bun .agents/skills/deps-update/scripts/drift.ts` lists every dep declared in ≥2
   workspaces, flagging those pinned at different ranges (`← DRIFT`). Same dep, different version across
   manifests = a bug waiting to happen and a **catalog candidate** (see Catalogs below). Converge drift as part
   of the update, don't leave it.
3. **Classify** — assign each package a **tier** from the scale below (blast radius → how much regression
   proof). Tier is orthogonal to feasibility: it sets *validation depth*, not *whether the bump is easy*.
4. **Assess feasibility** — for each candidate, especially **minor/major** bumps, read the changelog before
   touching anything. Get the source: `bun info <pkg> repository` → its GitHub `/releases` or `CHANGELOG.md`;
   `bun info <pkg> versions` lists what's between current and target. Skim for **breaking changes, required
   codemods, peer-dep bumps, dropped runtime support**. Rate the migration **effort** (this pairs with tier):
   - **trivial** — patch/minor, changelog shows only fixes/additions → bump and validate at tier.
   - **moderate** — deprecations, config or peer-dep changes, a codemod offered → apply the migration steps,
     then validate at tier; if Tier 2+, do the driven check even for a minor.
   - **breaking** — major with removed APIs / behavior changes → **isolate it entirely**, do the changelog's
     migration process, expect source edits, validate at tier + driven check regardless of tier. One per MR.
   Record effort + the changelog link per package; a high-tier + breaking combo is the one to schedule, not
   sneak into a batch.
5. **Batch by effort × tier, target the owning workspace** — batch only **trivial** bumps together (one
   validation pass). Isolate every **moderate/breaking** bump and every **Tier-2/3** bump **one package per
   commit** so a regression is attributable.
   - **`bun update` is NOT recursive** — bare `bun update <pkg>` from root only rewrites the *root* manifest.
     A workspace dep needs `bun update <pkg> --filter=<workspace>`, or `-r` to bump it everywhere it appears.
     Getting this wrong silently leaves workspace copies stale.
   - **If the dep is in a catalog** (see below), don't touch workspaces at all — bump the single entry in the
     root `catalog`/`catalogs` block and run `bun install`. That's the whole point of catalogs.
6. **Validate** at the tier's bar (below). Every tier starts with the **done-gate**: the profile's `format`,
   `lint` and `typecheck` commands plus the project's build, run from a clean tree so pre-existing failures
   are not blamed on the bump.
7. **Report** — per package: old→new version, **owning workspace**, tier, effort, changelog link, what you
   ran, result. If no automated suite covers the code the package touches, say the driven check is the
   *only* proof.

## The scale

| Tier | Package kind (examples) | What a bad bump breaks | Validation floor (after done-gate) |
|---|---|---|---|
| **0 · Tooling/types** | linters, formatters, typescript, `@types/*`, build/task runners, test runners, codegen | build / typecheck only — never ships in runtime | done-gate; compare `typecheck` against the clean tree and count **new** errors only. That's it. |
| **1 · Pure logic** | HTTP routers, schema/validation libs, ORMs, date/geo/math libs, anything in code several workspaces import | wrong values, broken routes — but **unit-testable** | done-gate + the profile's `test` command for every workspace that imports the package, not only the one that declares it. |
| **2 · UI / render** | UI frameworks, component libraries, CSS frameworks, data-fetching/state libs, canvas/WebGL/map renderers | visual regressions unit tests can't see | done-gate + `test` + **driven check**: start the app with the profile's `serve` command (wait for `serve_ready`), run the `e2e` command, and **eyeball the affected UI** (canvas and WebGL output especially, which no DOM assertion sees). Screenshot it. |
| **3 · AI / agent behavior** | LLM SDKs, agent frameworks, embedding/model libs | nondeterministic — a single green run proves nothing | done-gate + `test` + an **eval pass-RATE** over N repetitions with a Wilson interval; **state N**. |

Pick the **highest** tier a package qualifies for. A lib used both in shared logic and rendered in the UI is
Tier 2. When unsure between two tiers, take the higher one — the cost is one more suite, the cost of guessing
low is a silent regression in a gap with no automated coverage.

## Caveats

- **bun can refuse too-fresh versions** (`install.minimumReleaseAge` in `bunfig.toml`). If `bun add`/`update`
  rejects a brand-new release, that's the policy working — don't force past it without reason.
- **Keep the diff scoped** — if the `format` command rewrites files outside the packages you touched, restore
  them (`git checkout -- <file>`). The diff is the dependency change and its migration, nothing else.
- **Cite the suite you ran**, never "CI passed": CI may not run every suite, or may let failures through.

## Catalogs — the structural fix for drift

The duplicate-dep problem above (a dep declared in N manifests at N drifting ranges) is what bun **catalogs**
solve: define a version once in the root, reference it everywhere with the `catalog:` protocol. Supported
since bun 1.2.0.

Root `package.json` (top-level `catalog` / named `catalogs` both work; when `workspaces` is an array keep
these as sibling top-level keys):

```json
{
  "catalog": { "zod": "^4.4.3", "react": "^19.2.6", "react-dom": "^19.2.6" },
  "catalogs": { "build": { "vite": "^8.1.4", "typescript": "^6.0.3" } }
}
```

Each workspace then references it instead of pinning a range:

```json
{ "dependencies": { "zod": "catalog:" }, "devDependencies": { "vite": "catalog:build" } }
```

Rules and gotchas:
- **Update flow changes**: bump the version in the root catalog + `bun install` — not `bun update --filter`.
- Migrate only deps in **≥2 workspaces**; leave single-workspace deps and `workspace:*` refs alone.
- `bun outdated`/`bun update` behavior against the `catalog:` protocol is **not documented** — verify against
  a cataloged dep before trusting either, and fall back to editing the catalog entry by hand.
- On `bun publish`, `catalog:` refs are replaced with resolved versions.

Adopting catalogs is a **repo migration, not a skill action** — do it as its own scoped branch, then this
skill's per-workspace update steps collapse to "edit the catalog, `bun install`" for every cataloged dep.

## Quick reference

```bash
bun outdated --filter='*'                 # discover ALL workspaces (bare `bun outdated` = root only!)
bun outdated --filter=<workspace>         # one workspace
bun .agents/skills/deps-update/scripts/drift.ts   # deps in >=2 workspaces + drift flags (--all for non-drift too)
bun info <pkg> repository                 # changelog source → GitHub /releases or CHANGELOG.md
bun info <pkg> versions                   # what versions exist between current and target
bun update <pkg> --filter=<workspace>     # bump a WORKSPACE dep (bare `bun update` only touches root!)
bun update -r <pkg>                        # bump <pkg> in every workspace it appears
```
