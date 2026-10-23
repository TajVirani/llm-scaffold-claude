#!/usr/bin/env bash
# File: Fixture builders for the graph-extractor suites (the bash project, the JS/TS project, work profiles, a depcruise stub).
#   Sourced after lib/common.sh; defines variables and functions only. bash 3.2 compatible.
# Provides:
#   bash_project_repo DIR          committed git repo of bash scripts covering each `source` form and call form the bash
#                                  extractor must handle (see the BASH_* variables), plus bash-shebang files without .sh,
#                                  a python script and a README the extractor must not claim, and a test file
#   BASH_SCOPES                    the --scope arguments covering every directory of the bash project
#   BASH_MODULES                   the --module arguments, one module per top-level directory
#   BASH_DYNAMIC_SOURCE_LINE, BASH_DYNAMIC_SOURCE_TEXT     where bin/build.sh sources a path built at run time
#   BASH_MISSING_CALL_LINE, BASH_MISSING_CALL_TEXT         where bin/build.sh calls a runtime-root path that does not exist
#   BASH_DOT_SLASH_CALL_LINE, BASH_DOT_SLASH_CALL_TEXT     where tools/deploy.sh runs a cwd-relative ./ script
#   BASH_BASH_CWD_CALL_LINE, BASH_BASH_CWD_CALL_TEXT       where tools/deploy.sh runs a cwd-relative script through bash
#   js_project_repo DIR            committed git repo with the TS tree and .workflow/rules.md of the build-architecture suite
#   write_cruise_json FILE         the dependency-cruiser JSON for js_project_repo (the build-architecture suite's cruise.json)
#   write_dts_dir DIR              the tsc declarations for js_project_repo (the build-architecture suite's dts fixture)
#   write_profile DIR NAME [EXTRACTOR [TEST_PATTERNS]]   writes DIR/.workflow/profiles/NAME.md; an empty EXTRACTOR leaves the
#                                  graph_extractor key out; TEST_PATTERNS is a YAML flow list such as '["tests/"]'
#   depcruise_stub FILE JSON [ARGS_LOG]   writes an executable stand-in for depcruise that prints JSON's content and,
#                                  when ARGS_LOG is given, records its arguments there, one per line
#   refusing_depcruise_stub FILE   writes a depcruise stand-in that fails, for runs that must not call dependency-cruiser
# shellcheck disable=SC2016,SC2034  # the fixture scripts hold literal $ expansions; the variables are read by the suites

BASH_SCOPES=(--scope bin --scope lib --scope ops --scope tests --scope tools)
BASH_MODULES=(--module bin --module lib --module ops --module tests --module tools)
BASH_DYNAMIC_SOURCE_LINE=10
BASH_DYNAMIC_SOURCE_TEXT='$PLUGIN_DIR/$PLUGIN.sh'
BASH_MISSING_CALL_LINE=16
BASH_MISSING_CALL_TEXT='$ROOT/ops/gone.sh'
BASH_DOT_SLASH_CALL_LINE=9
BASH_DOT_SLASH_CALL_TEXT='./scripts/stage.sh'
BASH_BASH_CWD_CALL_LINE=10
BASH_BASH_CWD_CALL_TEXT='scripts/build-docs.sh'

bash_project_repo() {
  local r=$1
  git_init_repo "$r"
  mkdir -p "$r/bin" "$r/lib" "$r/ops" "$r/tests" "$r/tools"
  # The line numbers named by the BASH_*_LINE variables are pinned: keep those lines where they are.
  cat >"$r/bin/build.sh" <<'EOF'
#!/usr/bin/env bash
# Builds the release from the tools and ops scripts.
set -euo pipefail

. "$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)/../lib/paths.sh"
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/../lib/strings.sh"
ROOT="$(repo_root)"
PLUGIN="${PLUGIN:-default}"
source "$PLUGIN_DIR/$PLUGIN.sh"

main() {
  upper_case "build"
  "$here/../tools/deploy.sh" --dry-run
  bash "$ROOT/ops/report.sh"
  bash "$ROOT/ops/gone.sh"
}

main "$@"
EOF
  cat >"$r/bin/release" <<'EOF'
#!/bin/bash
# Tags a release.
echo release
EOF
  cat >"$r/tools/deploy.sh" <<'EOF'
#!/usr/bin/env bash
# Deploys the build.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$here/../lib"
. "$LIB_DIR/strings.sh"
trim "  deploy  "
"$here/publish" --tag
./scripts/stage.sh
bash scripts/build-docs.sh
EOF
  cat >"$r/tools/publish" <<'EOF'
#!/usr/bin/env bash
# Publishes the tagged build.
echo publish
EOF
  cat >"$r/ops/report.sh" <<'EOF'
#!/usr/bin/env bash
# Prints the build report.
echo report
EOF
  cat >"$r/ops/notes.py" <<'EOF'
#!/usr/bin/env python3
print("notes")
EOF
  printf '# Ops\n\nRun `report.sh`.\n' >"$r/ops/README.md"
  cat >"$r/lib/paths.sh" <<'EOF'
# Path helpers, sourced by the build scripts.
. "$(dirname "${BASH_SOURCE[0]}")/strings.sh"

repo_root() {
  git rev-parse --show-toplevel
}
EOF
  cat >"$r/lib/strings.sh" <<'EOF'
# String helpers, sourced by the build scripts.
trim() {
  local s="$1"
  _strip_left() { s="${s#"${s%%[![:space:]]*}"}"; }
  _strip_left
  printf '%s\n' "${s%"${s##*[![:space:]]}"}"
}

function join_by {
  local IFS="$1"
  shift
  echo "$*"
}

upper_case () {
  printf '%s\n' "$1" | tr '[:lower:]' '[:upper:]'
}

trim() { printf '%s\n' "$1"; }
EOF
  cat >"$r/tests/build-test.sh" <<'EOF'
#!/usr/bin/env bash
# Checks the string helpers.
source "$(dirname "$0")/../lib/strings.sh"
[ "$(trim " a ")" = a ] || exit 1
EOF
  chmod +x "$r/bin/build.sh" "$r/bin/release" "$r/tools/deploy.sh" "$r/tools/publish" "$r/ops/report.sh" "$r/ops/notes.py" "$r/tests/build-test.sh"
  write_profile "$r" shell-scripts bash '["tests/"]'
  git_commit_all "$r" init
}

js_project_repo() {
  local r=$1 f
  git_init_repo "$r"
  mkdir -p "$r/src/a" "$r/src/b/sub" "$r/lib" "$r/.workflow"
  for f in src/main.ts src/a/index.ts src/a/x.ts src/a/x.test.ts src/b/y.ts src/b/sub/z.ts lib/other.ts; do echo "// $f" >"$r/$f"; done
  cat >"$r/.workflow/rules.md" <<'EOF'
# Rules

## Ownership

```yaml
modules:
  alpha:
    owns: ["src/a/**"]
    may_depend_on: [beta]
  beta:
    owns: ["src/b/**"]
    may_depend_on: []
```

## Shared core

```yaml
shared_core:
  paths: ["src/b/sub/**"]
```
EOF
  printf '.workflow/.cache-staging/\n' >"$r/.gitignore"
  git_commit_all "$r" init
}

write_cruise_json() {
  cat >"$1" <<'EOF'
{"modules":[
 {"source":"src/main.ts","dependencies":[{"resolved":"src/a/index.ts"},{"resolved":"fs","coreModule":true}]},
 {"source":"src/a/index.ts","dependencies":[{"resolved":"src/a/x.ts"}]},
 {"source":"src/a/x.ts","dependencies":[{"resolved":"src/b/y.ts"},{"resolved":"src/a/x.ts"},{"resolved":"node_modules/foo/index.js"}]},
 {"source":"src/a/x.test.ts","dependencies":[{"resolved":"src/a/x.ts"}]},
 {"source":"src/b/y.ts","dependencies":[{"resolved":"src/b/sub/z.ts"},{"resolved":"lib/other.ts"}]},
 {"source":"src/b/sub/z.ts","dependencies":[]},
 {"source":"lib/other.ts","dependencies":[]},
 {"source":"node_modules/foo/index.js","dependencies":[]},
 {"source":"fs","coreModule":true,"dependencies":[]}
],"summary":{"violations":[]}}
EOF
}

write_dts_dir() {
  local d=$1
  mkdir -p "$d/src/a"
  cat >"$d/src/a/index.d.ts" <<'EOF'
import { y } from "../b/y.js";
export * from "./x.js";
export { y as why, type Z } from "../b/y.js";
export declare class Alpha {
    run(): void;
}
export interface Opts {
    n: number;
}
export declare const enum Mode {
    A = 0
}
EOF
  cat >"$d/src/a/x.d.ts" <<'EOF'
export declare function f(): void;
export type T = 1;
export declare let counter: number;
EOF
  printf 'declare const _default: 1;\nexport default _default;\n' >"$d/src/main.d.ts"
}

write_profile() {
  local dir=$1 name=$2 extractor=${3:-} patterns=${4:-}
  mkdir -p "$dir/.workflow/profiles"
  {
    printf '# Profile: %s\n\n## File locations\n\n- Scripts live by owner.\n\n## Toolchain\n\n```yaml\n' "$name"
    printf 'lint: ""\ntest: "true"\n'
    [ -z "$extractor" ] || printf 'graph_extractor: %s\n' "$extractor"
    [ -z "$patterns" ] || printf 'test_patterns: %s\n' "$patterns"
    printf '```\n'
  } >"$dir/.workflow/profiles/$name.md"
}

depcruise_stub() {
  local stub=$1 json=$2 log=${3:-}
  if [ -n "$log" ]; then
    printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$@" >"%s"\ncat "%s"\n' "$log" "$json" >"$stub"
  else
    printf '#!/usr/bin/env bash\ncat "%s"\n' "$json" >"$stub"
  fi
  chmod +x "$stub"
}

refusing_depcruise_stub() {
  printf '#!/usr/bin/env bash\necho "depcruise must not run for this project" >&2\nexit 3\n' >"$1"
  chmod +x "$1"
}
