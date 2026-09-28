#!/usr/bin/env bash
# Installs agents/<role>/agent.md as GitHub Copilot CLI custom agents in
# ~/.copilot/agents.
# Usage: scripts/install-copilot.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="$HOME/.copilot/agents"

mkdir -p "$TARGET"
for dir in "$REPO_ROOT"/agents/*/; do
  role=$(basename "$dir")
  # Hugo delegates all code changes, so its tool list leaves out `edit`.
  extra=""
  if [[ "$role" == "hugo" ]]; then
    extra='tools: ["read", "search", "execute", "agent", "web", "todo"]'
  fi
  # Insert `name:` (and any extra fields) right after the opening frontmatter fence.
  awk -v name="$role" -v extra="$extra" '
    NR==1 { print; print "name: " name; if (extra != "") print extra; next }
    { print }
  ' "$dir/agent.md" > "$TARGET/$role.agent.md"
  echo "wrote $TARGET/$role.agent.md"
done

echo
echo "Installed to $TARGET"
echo "Start Hugo with: copilot --agent hugo"
echo "Consider giving review.agent.md its own 'model:', different from"
echo "implement.agent.md's, so review is an independent check."
