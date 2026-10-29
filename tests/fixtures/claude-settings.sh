#!/usr/bin/env bash
# File: Claude settings fixtures for the install and stop-audit suites: hooks/claude-settings.template.json as it was while the
#   SubagentStop stop audit matched only implementation agents, so an upgrade from it can be tested, and readers for the
#   SubagentStop groups that run the stop audit. Sourced after lib/common.sh; defines functions only. bash 3.2 compatible.
# Provides:
#   old_claude_settings_template DEST          writes that template to DEST
#   use_old_claude_settings SCAFFOLD           puts it in place of SCAFFOLD/.agents/hooks/claude-settings.template.json
#   stop_audit_matchers SETTINGS               prints the matcher of each SubagentStop group in SETTINGS that runs
#                                              post-implementation-audit.sh, one per line
#   matcher_matches MATCHER AGENT_TYPE         true when MATCHER matches the whole of AGENT_TYPE, read as a regular expression
#                                              the way Claude Code reads a matcher

stop_audit_matchers() {
  jq -r '.hooks.SubagentStop[]? | select(any(.hooks[]?; .command | test("post-implementation-audit.sh"))) | .matcher // ""' "$1"
}

matcher_matches() {
  jq -en --arg m "$1" --arg a "$2" '$a | test("^(" + $m + ")$")' >/dev/null
}

use_old_claude_settings() {
  old_claude_settings_template "$1/.agents/hooks/claude-settings.template.json"
}

old_claude_settings_template() {
  cat > "$1" <<'EOF'
{
  "outputStyle": "Concise Technical",
  "statusLine": {
    "type": "command",
    "command": "node \"${CLAUDE_PROJECT_DIR:-.}\"/.agents/hooks/context-bridge.cjs"
  },
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/session-start-resume.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/block-destructive-git.sh",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Agent",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/pre-launch.sh",
            "timeout": 30
          }
        ]
      },
      {
        "matcher": "Write|Edit|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/spec-single-writer-guard.sh",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/tier-a-write-guard.sh",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/tier-b-write-guard.sh",
            "timeout": 10
          }
        ]
      },
      {
        "matcher": "Bash|Write|Edit|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/worktree-write-guard.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write|Edit|NotebookEdit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/rules-boundary-config-sync.sh",
            "timeout": 60
          }
        ]
      },
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/evidence-capture.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "PostToolUseFailure": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/evidence-capture.sh",
            "timeout": 60
          }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "implementation",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.agents/hooks/post-implementation-audit.sh",
            "timeout": 600
          }
        ]
      }
    ]
  },
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git log:*)",
      "Bash(git diff:*)",
      "Bash(git show:*)",
      "Bash(git rev-parse:*)",
      "Bash(git merge-base:*)",
      "Bash(git branch --show-current)",
      "Bash(git worktree list:*)",
      "Bash(git worktree add:*)",
      "Bash(yq --version)",
      "Bash(yq --front-matter=extract:*)",
      "Bash(yq -o=tsv:*)",
      "Bash(.agents/skills/feature-workflow/scripts/status-transition.sh:*)",
      "Bash(.agents/skills/feature-workflow/scripts/initiative-transition.sh:*)",
      "Bash(.agents/skills/feature-workflow/scripts/step-progress.sh:*)",
      "Bash(.agents/skills/feature-workflow/scripts/check-write.sh:*)",
      "Bash(.agents/skills/feature-workflow/scripts/check-worktree-scope.sh:*)",
      "Bash(.agents/skills/feature-workflow/scripts/budget-check.sh:*)",
      "Bash(.agents/skills/feature-workflow/scripts/task-waves.sh:*)",
      "Bash(.agents/skills/feature-workflow/scripts/resolve-launch.sh:*)",
      "Bash(.agents/skills/feature-workflow/scripts/rules-setting.sh:*)",
      "Bash(.agents/skills/feature-workflow/scripts/run-toolchain.sh:*)",
      "Bash(.agents/skills/regenerate-caches/scripts/cache-stamp-check.sh:*)",
      "Bash(.agents/skills/regenerate-caches/scripts/check-staged-cache.sh:*)",
      "Bash(.agents/skills/regenerate-caches/scripts/publish-cache.sh:*)"
    ],
    "deny": [
      "Edit(.workflow/cache/**)",
      "Edit(.workflow/specs/*/.step)",
      "Edit(.workflow/initiatives/*/.step)"
    ]
  }
}
EOF
}
