<!--
Module of project-setup: fetch dmmulroy/anti-slop at the pinned commit, vendor it into the project, and register its rules (D10, D42).
Sources: adapted from dmmulroy/anti-slop skills/install-anti-slop/SKILL.md, fresh-install steps 1-5, at commit c44ef22ca116d0ba62a3ff663a0bd13a3f3fa40b (MIT, Copyright (c) 2026 Dillon Mulroy). Changes: fetch by pinned commit with git instead of copying a bundled tree; carry the repository-root LICENSE, which the skill assets do not include; no update path (an existing copy is kept). The rule names are copied from upstream step 3. Plan: assetlist D10, D42.
-->

# Anti-slop

Anti-slop is a set of Oxlint rules that the project vendors and then owns (MIT). This step fetches it at a pinned commit, rather than shipping a copy in the scaffold (D42), and it never calls the upstream `install-anti-slop` skill (D10).

## Pin

| Field | Value |
| --- | --- |
| Repository | `https://github.com/dmmulroy/anti-slop` |
| Commit | `c44ef22ca116d0ba62a3ff663a0bd13a3f3fa40b` (2026-09-10, merge of PR #36; plugin version 0.1.2) |
| Source path | `skills/install-anti-slop/assets/anti-slop/` (the distributable tree, without tests) plus the root `LICENSE` |
| Destination | `tools/oxlint/anti-slop/` |

To move the pin, change the commit in this table and in the Sources comment, then re-read upstream's install steps at the new commit for changed rule names.

## 1. Fetch and vendor

If `tools/oxlint/anti-slop/` already exists, keep it: it is project-owned, possibly customised. Skip to step 3 and check the rules are registered. Updating a vendored copy is a manual merge outside this skill.

Otherwise, run from the project root:

```bash
SHA=c44ef22ca116d0ba62a3ff663a0bd13a3f3fa40b
src=$(mktemp -d)
git -C "$src" init -q
git -C "$src" fetch -q --depth 1 https://github.com/dmmulroy/anti-slop "$SHA"
test "$(git -C "$src" rev-parse FETCH_HEAD)" = "$SHA"
stage=$(mktemp -d)
git -C "$src" archive FETCH_HEAD LICENSE skills/install-anti-slop/assets/anti-slop | tar -x -C "$stage"
mkdir -p tools/oxlint
cp -R "$stage/skills/install-anti-slop/assets/anti-slop" tools/oxlint/anti-slop
cp "$stage/LICENSE" tools/oxlint/anti-slop/LICENSE
rm -rf "$src" "$stage"
```

The `test` line checks that the fetched commit is the pinned one. If any command fails, stop and report it. Keep `tools/oxlint/anti-slop/vendor/eslint-stylistic/LICENSE` and its `UPSTREAM.md`: they arrive with the tree and must stay with it.

Then write `tools/oxlint/anti-slop/UPSTREAM.md`:

```markdown
# Vendored anti-slop

- Source: https://github.com/dmmulroy/anti-slop
- Commit: c44ef22ca116d0ba62a3ff663a0bd13a3f3fa40b
- Copied: skills/install-anti-slop/assets/anti-slop/ (whole tree) and the repository-root LICENSE (MIT, Copyright (c) 2026 Dillon Mulroy)
- Installed at: tools/oxlint/anti-slop/ on <YYYY-MM-DD> by project-setup
- Nested third-party code: vendor/eslint-stylistic/ (MIT; see its LICENSE and UPSTREAM.md)
- Deviations from upstream: none
```

Replace `<YYYY-MM-DD>` with today's date. When the project later changes a rule, it records the change under "Deviations".

Done when `tools/oxlint/anti-slop/index.ts`, `LICENSE`, `UPSTREAM.md` and `vendor/eslint-stylistic/LICENSE` exist.

## 2. Install the dependency pair

- If the project already depends on `oxlint`, read its installed version from the lockfile and install `@oxlint/plugins` at exactly that version.
- Otherwise, run `npm view oxlint version` and `npm view @oxlint/plugins version`, and install both at that same current version.
- Install both as exact-pinned dev dependencies with the project's package manager, so later upgrades move them together.

Done when `oxlint` and `@oxlint/plugins` are installed at the same exact version.

## 3. Register the rules

Merge these fields into the existing `.oxlintrc.json` or `oxlint.config.ts`, or create `.oxlintrc.json` when neither exists. Keep every existing entry. For Vite+, merge them under `lint`, and add the same ignore patterns to `fmt.ignorePatterns`.

```json
{
  "ignorePatterns": [".agent/**", ".agents/**", ".claude/**", ".codex/**", ".continue/**", ".cursor/**", ".gemini/**", ".opencode/**", ".pi/**", ".roo/**", ".windsurf/**", "tools/oxlint/anti-slop/**"],
  "jsPlugins": [{ "name": "anti-slop", "specifier": "./tools/oxlint/anti-slop/index.ts" }],
  "rules": {
    "oxc/no-accumulating-spread": "error",
    "anti-slop/no-array-filter-map": "error",
    "anti-slop/no-reduce-accumulator-copy": "error",
    "anti-slop/no-chained-type-assertions": "error",
    "anti-slop/no-conditional-empty-object-spread": "error",
    "anti-slop/no-known-value-widening": "error",
    "anti-slop/no-module-mocking": "error",
    "anti-slop/no-object-parameters": "error",
    "anti-slop/no-reflect-apply": "error",
    "anti-slop/no-reflect-get": "error",
    "anti-slop/no-runtime-typeof": "error",
    "anti-slop/no-shape-in-symbol-names": "error",
    "anti-slop/no-unknown-parameters": "error",
    "anti-slop/no-unknown-returns": "error",
    "anti-slop/no-unknown-type-aliases": "error",
    "anti-slop/no-unsafe-dictionary-type": "error",
    "anti-slop/no-widen-then-assert": "error",
    "anti-slop/require-readable-spacing": "error",
    "anti-slop/require-safety-comment-for-type-assertion": "error"
  }
}
```

Add any other agent-tooling directory the project has to `ignorePatterns`. Ignore named directories only, never every dot-directory: some projects keep owned source in one.

**Effect rules.** Register them only when a package manifest declares `effect` as a direct dependency, or the human asks. Add the plugin `{ "name": "anti-slop-effect", "specifier": "./tools/oxlint/anti-slop/effect/index.ts" }` and set these rules to `"error"`: `anti-slop-effect/no-manual-effect-error-tag`, `no-manual-tag-comparison`, `no-manual-tagged-construction`, `no-service-constructor-imports`, `prefer-effect-match` (each with the `anti-slop-effect/` prefix).

Done when the plugin and every generic rule are registered, and the Effect rules too when they apply.

## 4. Check

Run the profile's `lint` and `typecheck` commands. Report findings in project code with their counts. Fix them only when the human asks, and then fix the code itself: keep every rule and its severity as registered.

Done when both commands have run and their results are in the setup report, along with the pinned commit.
