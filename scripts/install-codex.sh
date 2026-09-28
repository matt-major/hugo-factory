#!/usr/bin/env bash
# Installs the specialist agents as Codex CLI custom agents (TOML) in
# ~/.codex/agents, and Hugo's instructions to ~/.codex/hugo.md for use as the
# main session's developer instructions.
# Usage: scripts/install-codex.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET="$HOME/.codex/agents"

mkdir -p "$TARGET"
python3 "$SCRIPT_DIR/convert_codex_agents.py" "$REPO_ROOT/agents" "$TARGET"

# Hugo is the main session, not a spawnable agent, so it ships as plain
# instructions: the agent.md body with its frontmatter stripped.
awk 'fence >= 2 { print } /^---$/ { fence++ }' \
  "$REPO_ROOT/agents/hugo/agent.md" > "$HOME/.codex/hugo.md"
echo "wrote $HOME/.codex/hugo.md"

echo
echo "Installed to $TARGET"
echo "Start Hugo with: codex -c \"developer_instructions=\$(cat ~/.codex/hugo.md)\""
echo "Consider setting a 'model' in review.toml different from implement.toml's,"
echo "so review is an independent check."
