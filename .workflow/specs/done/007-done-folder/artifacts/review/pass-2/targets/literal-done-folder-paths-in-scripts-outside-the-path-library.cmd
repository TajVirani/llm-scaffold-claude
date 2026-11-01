git grep -n -E 'specs/done' -- '.agents/hooks/*.sh' '.agents/skills/*/scripts/*.sh' install.sh 'scripts/*.sh' | grep -v -E '^[^:]+:[0-9]+:[[:space:]]*#' | wc -l | tr -d ' '
