#!/usr/bin/env bash
# Installs agents/<role>/agent.md as Claude Code subagents in ~/.claude/agents.
# Usage: scripts/install-claude-code.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="$HOME/.claude/agents"

mkdir -p "$TARGET"
for dir in "$REPO_ROOT"/agents/*/; do
  role=$(basename "$dir")
  # Hugo delegates all code changes, so it doesn't get file-editing tools.
  extra=""
  if [[ "$role" == "hugo" ]]; then
    extra="disallowedTools: Write, Edit, NotebookEdit"
  fi
  # Insert `name:` (and any extra fields) right after the opening frontmatter fence.
  awk -v name="$role" -v extra="$extra" '
    NR==1 { print; print "name: " name; if (extra != "") print extra; next }
    { print }
  ' "$dir/agent.md" > "$TARGET/$role.md"
  echo "wrote $TARGET/$role.md"
done

echo
echo "Installed to $TARGET"
echo "Start Hugo with: claude --agent hugo"
echo "Consider giving review.md its own 'model:', different from implement.md's,"
echo "so review is an independent check."
