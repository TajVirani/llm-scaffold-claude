#!/usr/bin/env bash
# File: Claude settings fixtures for the install and stop-audit suites: hooks/claude-settings.template.json as it was while the
#   SubagentStop stop audit matched only implementation agents, so an upgrade from it can be tested; the template the upgrade
#   goes to, with the stop audit widened to integration agents; editors that turn an installed settings file into an upgrade
#   target with user groups (changed matchers, mixed groups); and readers for the hook groups. Sourced after lib/common.sh;
#   defines functions only. bash 3.2 compatible. A group "runs COMMAND" when one of its hooks has a command containing COMMAND.
# Provides:
#   old_claude_settings_template DEST          writes that template to DEST
#   use_old_claude_settings SCAFFOLD           puts it in place of SCAFFOLD/.agents/hooks/claude-settings.template.json
#   widen_stop_audit_matcher TEMPLATE          sets the matcher of TEMPLATE's stop-audit SubagentStop group to
#                                              implementation|integration, whatever the repo's template ships today
#   stop_audit_matchers SETTINGS               prints the matcher of each SubagentStop group in SETTINGS that runs
#                                              post-implementation-audit.sh, one per line
#   matcher_matches MATCHER AGENT_TYPE         true when MATCHER matches the whole of AGENT_TYPE, read as a regular expression
#                                              the way Claude Code reads a matcher
#   set_group_matcher SETTINGS EVENT COMMAND MATCHER
#                                              sets the matcher of each EVENT group in SETTINGS that runs COMMAND
#   drop_group_matcher SETTINGS EVENT COMMAND  removes the matcher of each such group, so it matches everything
#   add_user_hook SETTINGS EVENT COMMAND USER_COMMAND
#                                              appends a hook running USER_COMMAND to each such group, making it mixed
#   add_stop_audit_group SETTINGS MATCHER USER_COMMAND
#                                              appends a SubagentStop group under MATCHER running the stop audit hook already
#                                              in SETTINGS, then USER_COMMAND
#   group_matchers SETTINGS EVENT COMMAND      prints the matcher of each such group, one per line ("<none>" when it has none)
#   group_json SETTINGS EVENT COMMAND          prints each such group as compact JSON, one per line

# shellcheck disable=SC2016  # jq programs, not shell

# runs_command_def : the jq function runs($c), true for a group with a hook whose command contains $c.
runs_command_def() {
  printf '%s\n' 'def runs($c): any(.hooks[]?; (.command // "") | contains($c));'
}

# edit_settings SETTINGS JQ_PROGRAM [JQ_ARGS...] : rewrites SETTINGS in place through JQ_PROGRAM, which may call runs($c).
edit_settings() {
  local file=$1 program=$2
  shift 2
  jq "$@" "$(runs_command_def) $program" "$file" >"$file.edited" && mv "$file.edited" "$file"
}

widen_stop_audit_matcher() {
  set_group_matcher "$1" SubagentStop post-implementation-audit.sh 'implementation|integration'
}

set_group_matcher() {
  edit_settings "$1" '.hooks[$e] |= map(if runs($c) then .matcher = $m else . end)' --arg e "$2" --arg c "$3" --arg m "$4"
}

drop_group_matcher() {
  edit_settings "$1" '.hooks[$e] |= map(if runs($c) then del(.matcher) else . end)' --arg e "$2" --arg c "$3"
}

add_user_hook() {
  edit_settings "$1" '.hooks[$e] |= map(if runs($c) then .hooks += [{type: "command", command: $u}] else . end)' \
    --arg e "$2" --arg c "$3" --arg u "$4"
}

add_stop_audit_group() {
  edit_settings "$1" '
    [.hooks.SubagentStop[] | .hooks[] | select((.command // "") | contains("post-implementation-audit.sh"))][0] as $audit
    | .hooks.SubagentStop += [{matcher: $m, hooks: [$audit, {type: "command", command: $u}]}]' --arg m "$2" --arg u "$3"
}

group_matchers() {
  jq -r "$(runs_command_def)"' .hooks[$e][]? | select(runs($c)) | if has("matcher") then .matcher else "<none>" end' \
    --arg e "$2" --arg c "$3" "$1"
}

group_json() {
  jq -c "$(runs_command_def)"' .hooks[$e][]? | select(runs($c))' --arg e "$2" --arg c "$3" "$1"
}

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
