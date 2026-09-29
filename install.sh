#!/usr/bin/env bash
# Installs the agents for each tool, either into the current project or
# globally into the tool's user-level agent directory.
# Usage: path/to/install.sh [-g|--global] [-p|--project] [-y|--yes] [--link] [claude] [codex] [copilot]
#   -g, --global   Install into your user directory, for every project.
#   -p, --project  Install into the current project: its git root, or the current directory (the default).
#   -y, --yes      Don't prompt; use the defaults for anything not given.
#   --link         Symlink the files instead of copying, so `git pull` updates them.
#   With no tool names, installs for every tool found on PATH.
set -euo pipefail

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# The project is the enclosing git repository, or the current directory outside one.
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"

usage() {
  echo "usage: $0 [-g|--global] [-p|--project] [-y|--yes] [--link] [claude] [codex] [copilot]" >&2
  exit 1
}

scope=""
yes=false
mode=copy
tools=()
for arg in "$@"; do
  case "$arg" in
    -g|--global) scope=global ;;
    -p|--project) scope=project ;;
    -y|--yes) yes=true ;;
    --link) mode=link ;;
    claude|codex|copilot) tools+=("$arg") ;;
    *) usage ;;
  esac
done

if [[ ${#tools[@]} -eq 0 ]]; then
  for tool in claude codex copilot; do
    command -v "$tool" >/dev/null && tools+=("$tool")
  done
  if [[ ${#tools[@]} -eq 0 ]]; then
    echo "No supported tool found on PATH. Name one: claude, codex, or copilot." >&2
    exit 1
  fi
fi

if [[ -z $scope ]]; then
  scope=project
  if [[ $yes == false && -t 0 ]]; then
    echo "Install the agents for: ${tools[*]}"
    echo "  1) Project: into $PROJECT_ROOT, to commit and share with your team"
    echo "  2) Global:  into your home directory, for every project"
    read -r -p "Choose [1]: " choice
    case "${choice:-1}" in
      1) scope=project ;;
      2) scope=global ;;
      *) echo "Invalid choice: $choice" >&2; exit 1 ;;
    esac
  fi
fi

if [[ $scope == project ]]; then
  if [[ $PROJECT_ROOT == "$REPO_ROOT" ]]; then
    echo "Run this from the project you want to install into, or pass --global." >&2
    exit 1
  fi
  base="$PROJECT_ROOT"
  codex_dir="$base/.codex"
  copilot_dir="$base/.github/agents"
else
  base="$HOME"
  codex_dir="$CODEX_HOME"
  copilot_dir="$base/.copilot/agents"
fi

# install_files <dest-dir> <file>...
install_files() {
  local dest="$1"; shift
  mkdir -p "$dest"
  for file in "$@"; do
    # Remove first, so a copy never writes through a symlink from an earlier --link.
    rm -f "$dest/$(basename "$file")"
    if [[ $mode == link ]]; then
      ln -sf "$file" "$dest/"
    else
      cp "$file" "$dest/"
    fi
    echo "  $dest/$(basename "$file")"
  done
}

for tool in "${tools[@]}"; do
  echo "$tool:"
  case "$tool" in
    claude)  install_files "$base/.claude/agents" "$REPO_ROOT"/claude/agents/*.md ;;
    codex)   install_files "$codex_dir/agents" "$REPO_ROOT"/codex/agents/*.toml
             # Codex reads profiles only from its home, so Hugo's is always global.
             install_files "$CODEX_HOME" "$REPO_ROOT/codex/hugo.config.toml" ;;
    copilot) install_files "$copilot_dir" "$REPO_ROOT"/copilot/agents/*.agent.md ;;
  esac
done

if [[ $scope == project && " ${tools[*]} " == *" codex "* ]]; then
  echo
  echo "Note: Codex loads project agents only in a trusted project. Trust this"
  echo "project when Codex asks, or add it under [projects] in $CODEX_HOME/config.toml."
  echo "Hugo's Codex profile is always installed globally, because Codex reads"
  echo "profiles only from $CODEX_HOME."
fi

if [[ $scope == project && $mode == link ]]; then
  echo
  echo "Note: the symlinks point into $REPO_ROOT, so they won't work for teammates"
  echo "if you commit them. Install without --link to commit the agents."
fi
