#!/usr/bin/env bash

# setup.sh - Verify notify-on-done plugin installation

set -euo pipefail

echo "=========================================="
echo " notify-on-done Plugin - Setup"
echo "=========================================="
echo ""

# Check if main script exists
if [ ! -f "scripts/notify.sh" ]; then
    echo "❌ Error: scripts/notify.sh not found"
    echo ""
    echo "This file should be included in the repository."
    exit 1
fi

# Check if hook config exists
if [ ! -f "hooks/hooks.json" ]; then
    echo "❌ Error: hooks/hooks.json not found"
    echo ""
    echo "This file should be included in the repository."
    exit 1
fi

# Check if plugin manifest exists
if [ ! -f ".claude-plugin/plugin.json" ]; then
    echo "❌ Error: .claude-plugin/plugin.json not found"
    echo ""
    echo "This file should be included in the repository."
    exit 1
fi

# Make script executable
chmod +x scripts/notify.sh

echo "✓ Plugin scripts verified"
echo ""
echo "=========================================="
echo " Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Local test:"
echo "   bash scripts/notify.sh task_complete \"test message\""
echo ""
echo "2. Load as plugin in Claude Code (local dev):"
echo "   claude --plugin-dir $(pwd)"
echo ""
echo "3. Or install from GitHub:"
echo "   /plugin marketplace add <owner>/notify-on-done"
echo "   /plugin install notify-on-done"
echo ""
echo "4. Restart Claude Code for hooks to take effect"
echo ""
echo "Configuration:"
echo "   ~/.config/claude-code/notify-on-done.conf"
echo "   (auto-generated on first notification)"
echo ""
