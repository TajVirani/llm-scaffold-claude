// GENERATED — do not edit; source .workflow/rules.md
// Regenerate with: .agents/skills/project-setup/scripts/generate-boundary-config.sh
// Run from the project root: depcruise --config .workflow/tools/boundaries/dependency-cruiser.cjs <src>
module.exports = {
  "forbidden": [
    {
      "name": "agents-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "agents-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "agents-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "agents-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "agents-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "agents-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "agents-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "agents-not-to-lib",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module lib",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "agents-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "agents-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "agents-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "agents-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "agents-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "agents-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "agents-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "agents-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "agents-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module agents may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/agents/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-feature-workflow",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module feature-workflow",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "data-structure-audit-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "data-structure-audit-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "data-structure-audit-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "data-structure-audit-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module data-structure-audit may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "deeper-prompt-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-lib",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module lib",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "deeper-prompt-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "deeper-prompt-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "deeper-prompt-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module deeper-prompt may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-feature-workflow",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module feature-workflow",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "deps-audit-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-lib",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module lib",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "deps-audit-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "deps-audit-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module deps-audit may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "domain-modeling-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-lib",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module lib",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "domain-modeling-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "domain-modeling-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "domain-modeling-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module domain-modeling may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "feature-workflow-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "feature-workflow-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "feature-workflow-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "feature-workflow-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "feature-workflow-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "feature-workflow-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "feature-workflow-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "feature-workflow-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "feature-workflow-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "feature-workflow-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "feature-workflow-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "feature-workflow-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "feature-workflow-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "feature-workflow-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module feature-workflow may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "hooks-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "hooks-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "hooks-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "hooks-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "hooks-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "hooks-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "hooks-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "hooks-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "hooks-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "hooks-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "hooks-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "hooks-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "hooks-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "hooks-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "hooks-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "hooks-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module hooks may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/hooks/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "installer-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module agents",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "installer-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "installer-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "installer-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "installer-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "installer-not-to-feature-workflow",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module feature-workflow",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      }
    },
    {
      "name": "installer-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "installer-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "installer-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "installer-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "installer-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "installer-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "installer-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "installer-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "installer-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "installer-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "installer-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module installer may not depend on module tests",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "issue-tracking-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "issue-tracking-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "issue-tracking-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "issue-tracking-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module issue-tracking may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "lib-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "lib-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "lib-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "lib-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "lib-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "lib-not-to-feature-workflow",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module feature-workflow",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      }
    },
    {
      "name": "lib-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "lib-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "lib-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "lib-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "lib-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "lib-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "lib-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "lib-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "lib-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "lib-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "lib-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "lib-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "lib-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module lib may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "output-styles-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "output-styles-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "output-styles-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "output-styles-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "output-styles-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "output-styles-not-to-feature-workflow",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module feature-workflow",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      }
    },
    {
      "name": "output-styles-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "output-styles-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "output-styles-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "output-styles-not-to-lib",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module lib",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "output-styles-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "output-styles-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "output-styles-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "output-styles-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "output-styles-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "output-styles-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "output-styles-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "output-styles-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "output-styles-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module output-styles may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/output-styles/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-feature-workflow",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module feature-workflow",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "pr-review-data-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-lib",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module lib",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "pr-review-data-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "pr-review-data-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "pr-review-data-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module pr-review-data may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "project-setup-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "project-setup-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "project-setup-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "project-setup-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "project-setup-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "project-setup-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "project-setup-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "project-setup-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "project-setup-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "project-setup-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "project-setup-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "project-setup-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "project-setup-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "project-setup-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module project-setup may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-setup/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "project-standards-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "project-standards-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "project-standards-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "project-standards-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "project-standards-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "project-standards-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "project-standards-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "project-standards-not-to-lib",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module lib",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "project-standards-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "project-standards-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "project-standards-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "project-standards-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "project-standards-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "project-standards-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "project-standards-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module project-standards may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/project-standards/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "regenerate-caches-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "regenerate-caches-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "regenerate-caches-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module regenerate-caches may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "retrospective-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "retrospective-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "retrospective-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "retrospective-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "retrospective-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "retrospective-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "retrospective-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "retrospective-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "retrospective-not-to-lib",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module lib",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "retrospective-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "retrospective-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "retrospective-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "retrospective-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "retrospective-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "retrospective-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "retrospective-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "retrospective-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "retrospective-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module retrospective may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/skills/retrospective/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "root-docs-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module agents",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "root-docs-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "root-docs-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "root-docs-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "root-docs-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "root-docs-not-to-feature-workflow",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module feature-workflow",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      }
    },
    {
      "name": "root-docs-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "root-docs-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module installer",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "root-docs-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "root-docs-not-to-lib",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module lib",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "root-docs-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "root-docs-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "root-docs-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "root-docs-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "root-docs-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "root-docs-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "root-docs-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "root-docs-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "root-docs-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module root-docs may not depend on module tests",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-feature-workflow",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module feature-workflow",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "scaffold-scripts-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-lib",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module lib",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "scaffold-scripts-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "scaffold-scripts-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "scaffold-scripts-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module scaffold-scripts may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^scripts/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "shared-core-not-to-agents",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module agents",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "shared-core-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "shared-core-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "shared-core-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "shared-core-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "shared-core-not-to-feature-workflow",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module feature-workflow",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      }
    },
    {
      "name": "shared-core-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "shared-core-not-to-installer",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module installer",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "shared-core-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "shared-core-not-to-lib",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module lib",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "shared-core-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "shared-core-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "shared-core-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "shared-core-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "shared-core-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "shared-core-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "shared-core-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "shared-core-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "shared-core-not-to-standalone-skills",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module standalone-skills",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      }
    },
    {
      "name": "shared-core-not-to-tests",
      "comment": "Generated from .workflow/rules.md: shared core may not depend on module tests",
      "severity": "error",
      "from": {
        "path": "^\\.agents/lib/.*$"
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-agents",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module agents",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/agents/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-data-structure-audit",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module data-structure-audit",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/data-structure-audit/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-deeper-prompt",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module deeper-prompt",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/deeper-prompt/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-deps-audit",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module deps-audit",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/deps-audit/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-domain-modeling",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module domain-modeling",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/domain-modeling/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-feature-workflow",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module feature-workflow",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/feature-workflow/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-hooks",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module hooks",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/hooks/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-installer",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module installer",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": [
          "^\\.agents/install-manifest\\.txt$",
          "^install\\.sh$"
        ]
      }
    },
    {
      "name": "standalone-skills-not-to-issue-tracking",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module issue-tracking",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/issue-tracking/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-lib",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module lib",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/lib/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-output-styles",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module output-styles",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/output-styles/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-pr-review-data",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module pr-review-data",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/pr-review-data/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-project-setup",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module project-setup",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/project-setup/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-project-standards",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module project-standards",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/project-standards/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-regenerate-caches",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module regenerate-caches",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/regenerate-caches/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-retrospective",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module retrospective",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^\\.agents/skills/retrospective/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    },
    {
      "name": "standalone-skills-not-to-scaffold-scripts",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module scaffold-scripts",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^scripts/.*$"
      }
    },
    {
      "name": "standalone-skills-not-to-tests",
      "comment": "Generated from .workflow/rules.md: module standalone-skills may not depend on module tests",
      "severity": "error",
      "from": {
        "path": [
          "^\\.agents/skills/deps-update/.*$",
          "^\\.agents/skills/design-pattern-doc/.*$",
          "^\\.agents/skills/glab/.*$",
          "^\\.agents/skills/handoff/.*$",
          "^\\.agents/skills/pr-quality/.*$",
          "^\\.agents/skills/visual-change-report/.*$",
          "^\\.agents/skills/writing-for-agents/.*$"
        ]
      },
      "to": {
        "path": "^tests/.*$"
      }
    },
    {
      "name": "tests-not-to-root-docs",
      "comment": "Generated from .workflow/rules.md: module tests may not depend on module root-docs",
      "severity": "error",
      "from": {
        "path": "^tests/.*$"
      },
      "to": {
        "path": [
          "^\\.agents/README\\.md$",
          "^AGENTS\\.md$",
          "^README\\.md$"
        ]
      }
    }
  ],
  "options": {
    "tsConfig": {
      "fileName": "tsconfig.json"
    }
  }
};
