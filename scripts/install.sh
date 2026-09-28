#!/usr/bin/env bash
# Dispatcher for the per-platform install scripts.
# Usage: scripts/install.sh <claude-code|codex|copilot|all>
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  echo "usage: $0 <claude-code|codex|copilot|all>" >&2
  exit 1
}

[[ $# -eq 1 ]] || usage

case "$1" in
  claude-code) "$SCRIPT_DIR/install-claude-code.sh" ;;
  codex)       "$SCRIPT_DIR/install-codex.sh" ;;
  copilot)     "$SCRIPT_DIR/install-copilot.sh" ;;
  all)
    "$SCRIPT_DIR/install-claude-code.sh"
    "$SCRIPT_DIR/install-codex.sh"
    "$SCRIPT_DIR/install-copilot.sh"
    ;;
  *) usage ;;
esac
