#!/usr/bin/env bash
# Install post-merge Git hook to automatically sync after git pull

set -e

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_FILE="$REPO_ROOT/.git/hooks/post-merge"

# Create the hook
cat > "$HOOK_FILE" << 'EOF'
#!/usr/bin/env bash
# Post-merge hook: sync agents and commands to .claude/ after git pull

REPO_ROOT="$(git rev-parse --show-toplevel)"
"$REPO_ROOT/scripts/sync-to-claude.sh"
EOF

chmod +x "$HOOK_FILE"

echo "✓ Installed post-merge Git hook"
echo ""
echo "The hook will now run automatically after 'git pull' to sync:"
echo "  • agents/*.md → ~/.claude/agents/"
echo "  • commands/*.md → ~/.claude/commands/"
echo ""
echo "You can also run the sync manually anytime:"
echo "  ./scripts/sync-to-claude.sh"
echo ""
echo "Tip: Set CLAUDE_HOME to use a different directory (default: ~/.claude)"
