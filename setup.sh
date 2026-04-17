#!/usr/bin/env bash

# setup.sh - Verify notify-on-done plugin installation

set -euo pipefail

echo "=========================================="
echo " notify-on-done Plugin - Setup"
echo "=========================================="
echo ""

# Check if packaged plugin exists
if [ ! -f "notify-on-done/scripts/notify.sh" ]; then
    echo "❌ Error: notify-on-done/scripts/notify.sh not found"
    echo ""
    echo "This file should be included in the repository."
    exit 1
fi

# Check if hook config exists
if [ ! -f "notify-on-done/hooks/hooks.json" ]; then
    echo "❌ Error: notify-on-done/hooks/hooks.json not found"
    echo ""
    echo "This file should be included in the repository."
    exit 1
fi

# Check if Claude plugin manifest exists
if [ ! -f "notify-on-done/.claude-plugin/plugin.json" ]; then
    echo "❌ Error: notify-on-done/.claude-plugin/plugin.json not found"
    echo ""
    echo "This file should be included in the repository."
    exit 1
fi

# Check if Codex plugin manifest exists
if [ ! -f "notify-on-done/.codex-plugin/plugin.json" ]; then
    echo "❌ Error: notify-on-done/.codex-plugin/plugin.json not found"
    echo ""
    echo "This file should be included in the repository."
    exit 1
fi

if [ ! -f "notify-on-done/sounds/task-complete.wav" ]; then
    echo "❌ Error: notify-on-done/sounds/task-complete.wav not found"
    echo ""
    echo "This file should be included in the repository."
    exit 1
fi

if [ ! -f ".agents/plugins/marketplace.json" ]; then
    echo "❌ Error: .agents/plugins/marketplace.json not found"
    echo ""
    echo "This file should be included in the repository."
    exit 1
fi

if [ ! -f ".claude-plugin/marketplace.json" ]; then
    echo "❌ Error: .claude-plugin/marketplace.json not found"
    echo ""
    echo "This file should be included in the repository."
    exit 1
fi

if [ ! -f ".codex/hooks.json" ]; then
    echo "❌ Error: .codex/hooks.json not found"
    echo ""
    echo "This file should be included in the repository."
    exit 1
fi

# Make script executable
chmod +x notify-on-done/scripts/notify.sh

echo "✓ Plugin scripts verified"
echo ""
echo "=========================================="
echo " Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Local test:"
echo "   bash notify-on-done/scripts/notify.sh task_complete \"test message\""
echo ""
echo "2. Load as plugin in Claude Code (local dev):"
echo "   claude --plugin-dir $(pwd)/notify-on-done"
echo ""
echo "3. Install in Codex:"
echo "   codex marketplace add $(pwd)"
echo ""
echo "4. Or install from GitHub:"
echo "   codex marketplace add miuzel/notify-on-done@github"
echo ""
echo "5. Or install from GitHub in Claude Code:"
echo "   /plugin marketplace add <owner>/notify-on-done"
echo "   /plugin install notify-on-done"
echo ""
echo "6. Enable Codex hooks if needed:"
echo "   [features]"
echo "   codex_hooks = true"
echo ""
echo "7. Restart Claude Code or Codex for hooks to take effect"
echo ""
echo "Configuration:"
echo "   ~/.config/claude-code/notify-on-done.conf"
echo "   (auto-generated on first notification)"
echo ""
