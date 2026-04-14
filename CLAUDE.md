# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Claude Code plugin that sends cross-platform desktop notifications via hooks. It is primarily optimized for WSL2 + Windows Terminal, with a fallback path for native Linux.

## Architecture

- `scripts/notify.sh` — Main bash script. Detects WSL2 vs native Linux, handles focus detection, rate limiting, taskbar flashing, sounds, and BalloonTip notifications.
- `sounds/` — Notification audio files mapped by status: `task-complete.wav`, `question.wav`, `plan-ready.wav`, `error.wav`.
- `hooks/hooks.json` — Hook definitions consumed by Claude Code. Uses `${CLAUDE_PLUGIN_ROOT}` to reference the plugin root.
- `.claude-plugin/plugin.json` — Plugin manifest.
- `~/.config/claude-code/notify-on-done.conf` — Auto-generated user config (bash-sourcable `KEY="value"` format). Created on first run if missing.

**Key behaviors:**
- WSL2 path: flashes taskbar via `FlashWindowEx`, shows `BalloonTip` via PowerShell, plays sound via `MediaPlayer`.
- Native Linux path: uses `notify-send` and falls back to `paplay`/`ffplay`/`mpg123` for sound.
- Focus detection (`is_claude_focused`) skips notifications entirely if the foreground window is Windows Terminal with "Claude Code" in the title, or VS Code.
- Rate limiting (`should_notify`) enforces a 2-second cooldown per `CLAUDE_SESSION_ID`.
- Experimental click-to-focus (`ENABLE_FOCUS_ON_CLICK`) launches a hidden PowerShell listener that waits for `BalloonTipClicked` and calls `SetForegroundWindow` on the Windows Terminal process.

**Hook integration (`hooks/hooks.json`):**
- `Stop` → `task_complete`
- `Notification` (permission/idle prompts) → `question`
- `PreToolUse` (`ExitPlanMode`) → `plan_ready`

## Common Commands

There is no build system, test suite, or package manager. Validate changes by running the script directly:

```bash
# Send a test notification (creates default config if missing)
bash scripts/notify.sh task_complete "test message"

# Clear rate-limit state to test rapid notifications
rm -f ~/.cache/notify-on-done/default
```

## Notes

- The user prefers Chinese UI strings by default (`LANG="zh"` in the notify config).
- The user works in WSL2 with Windows Terminal; WSL2-specific features are first-class.
- When editing `notify.sh`, avoid breaking the PowerShell heredocs and string-escaping paths passed to `powershell.exe`.
