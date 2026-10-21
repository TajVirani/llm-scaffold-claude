# .agents

The distribution unit of the scaffold, and the source of truth for every agent host. `.claude/` is a thin shim of symlinks into this folder.

- `skills/`: workflow and utility skills, each self-contained in its own folder.
- `agents/`: host-neutral sub-agent definitions; Codex tomls are generated from them.
- `hooks/`: guard and lifecycle hook scripts.
- `lib/`: shared shell helpers, including `workflow-paths.sh`, the one home for paths under `.workflow/`.
- `output-styles/`: output styles.
- `install-manifest.txt`: the list of what `install.sh` ships to a target project.

`install.sh` ships only what the manifest lists; vendored skills never ship. For the hooks and scripts, read the folders: each script carries a `# File:` header. [../PROVENANCE.md](../PROVENANCE.md) is the full inventory and says what is first-party and where each asset came from. Run the tests with `tests/run-all.sh` from the repo root.
