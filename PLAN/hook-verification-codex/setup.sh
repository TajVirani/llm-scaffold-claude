#!/bin/bash
# Builds the scratch repo. Usage: setup.sh <work-dir>   (prints nothing on success)
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
H="$1"
mkdir -p "$H/hooks" "$H/runs" "$H/real-skills" "$H/proj"
for f in "$SRC"/hooks/*.sh; do sed "s#__HOOKTEST_DIR__#$H#g" "$f" > "$H/hooks/$(basename "$f")"; done
chmod +x "$H"/hooks/*.sh
cp -R "$SRC/probe/skills/probe-skill" "$H/real-skills/"
cd "$H/proj"
git init -q && echo hi > README.md && mkdir -p docs/cache && echo seed > docs/cache/seed.md
mkdir -p .agents/skills .codex/agents
ln -s "$H/real-skills/probe-skill" .agents/skills/probe-skill            # symlinked skill dir
mkdir -p .agents/skills/direct-skill && printf -- '---\nname: direct-skill\ndescription: Control skill (not symlinked).\n---\nReply DIRECT-OK.\n' > .agents/skills/direct-skill/SKILL.md
cp "$SRC"/probe/agents/*.toml .codex/agents/
sed "s#__HOOKTEST_DIR__#$H#g" "$SRC/hooks.template.json" > .codex/hooks.json
cp "$SRC/config.template.toml" .codex/config.toml
git add -A && git -c user.name=t -c user.email=t@t commit -qm init
