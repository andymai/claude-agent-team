#!/usr/bin/env bash
# Automatically sync agents and commands to .claude/ directory
# This script is designed to run after git pull to keep symlinks up-to-date

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Find global Claude config directory
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

echo "🔄 Syncing agents and commands to $CLAUDE_HOME..."

# Create directories if they don't exist
mkdir -p "$CLAUDE_HOME/agents" "$CLAUDE_HOME/commands"

# Track changes
NEW_AGENTS=0
NEW_COMMANDS=0
REMOVED_LINKS=0

# Sync agents (excluding .unused files)
for agent in agents/*.md; do
  if [[ ! "$agent" =~ \.unused$ ]] && [[ -f "$agent" ]]; then
    target="$CLAUDE_HOME/agents/$(basename "$agent")"
    if [[ ! -L "$target" ]]; then
      ln -sf "$REPO_ROOT/$agent" "$target"
      echo -e "${GREEN}✓${NC} Linked agent: $(basename "$agent")"
      NEW_AGENTS=$((NEW_AGENTS + 1))
    fi
  fi
done

# Sync commands
for cmd in commands/*.md; do
  if [[ -f "$cmd" ]]; then
    target="$CLAUDE_HOME/commands/$(basename "$cmd")"
    if [[ ! -L "$target" ]]; then
      ln -sf "$REPO_ROOT/$cmd" "$target"
      echo -e "${GREEN}✓${NC} Linked command: $(basename "$cmd")"
      NEW_COMMANDS=$((NEW_COMMANDS + 1))
    fi
  fi
done

# Remove broken symlinks (for deleted agents/commands)
shopt -s nullglob
for link in "$CLAUDE_HOME/agents"/*.md "$CLAUDE_HOME/commands"/*.md; do
  if [[ -L "$link" ]] && [[ ! -e "$link" ]]; then
    rm "$link"
    echo -e "${YELLOW}✗${NC} Removed broken link: $(basename "$link")"
    REMOVED_LINKS=$((REMOVED_LINKS + 1))
  fi
done
shopt -u nullglob

# Summary
if [[ $NEW_AGENTS -gt 0 ]] || [[ $NEW_COMMANDS -gt 0 ]] || [[ $REMOVED_LINKS -gt 0 ]]; then
  echo ""
  echo "Summary:"
  [[ $NEW_AGENTS -gt 0 ]] && echo -e "  ${GREEN}+${NC} $NEW_AGENTS new agent(s)"
  [[ $NEW_COMMANDS -gt 0 ]] && echo -e "  ${GREEN}+${NC} $NEW_COMMANDS new command(s)"
  [[ $REMOVED_LINKS -gt 0 ]] && echo -e "  ${YELLOW}-${NC} $REMOVED_LINKS removed link(s)"
else
  echo -e "${GREEN}✓${NC} All agents and commands already synced"
fi
