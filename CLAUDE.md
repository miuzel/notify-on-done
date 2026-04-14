# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal Claude Code configuration repository. It contains custom skills, hooks, and settings that extend Claude Code's behavior, primarily focused on a WSL2 + Windows Terminal environment.

## Key Components

### `notify-on-done` Skill

Location: `.claude/skills/notify-on-done/`

A cross-platform desktop notification skill for Claude Code that triggers on hooks.

**Architecture:**
- `notify.sh` — Main bash script. Detects WSL2 vs native Linux, handles focus detection, rate limiting, taskbar flashing, sounds, and BalloonTip notifications.
- `notify-on-done.conf` — Auto-generated user config file (bash-sourcable `KEY="value"` format). Created on first run if missing.
- `SKILL.md` — Skill manifest and documentation.
- `.wav` files — Custom notification sounds (`task-complete.wav`, `question.wav`, `plan-ready.wav`, `error.wav`).

**Key behaviors:**
- WSL2 path: flashes taskbar via `FlashWindowEx`, shows `BalloonTip` via PowerShell, plays sound via `MediaPlayer`.
- Native Linux path: uses `notify-send` and falls back to `paplay`/`ffplay`/`mpg123` for sound.
- Focus detection (`is_claude_focused`) skips notifications entirely if the foreground window is Windows Terminal with "Claude Code" in the title, or VS Code.
- Rate limiting (`should_notify`) enforces a 2-second cooldown per `CLAUDE_SESSION_ID`.
- Experimental click-to-focus (`ENABLE_FOCUS_ON_CLICK`) launches a hidden PowerShell listener that waits for `BalloonTipClicked` and calls `SetForegroundWindow` on the Windows Terminal process.

**Hook integration:**
Configured in `.claude/settings.json`:
- `Stop` hook → `task_complete`
- `Notification` hook (permission/idle prompts) → `question`
- `PreToolUse` hook (`ExitPlanMode`) → `plan_ready`

## Common Commands

There is no build system, test suite, or package manager in this repository. Changes are validated by running the script directly:

```bash
# Send a test notification (creates default config if missing)
bash .claude/skills/notify-on-done/notify.sh task_complete "test message"

# Clear rate-limit state to test rapid notifications
rm -f ~/.cache/notify-on-done/default
```

## Settings

- `.claude/settings.json` — Global hooks configuration.
- `.claude/settings.local.json` — Local permissions (contains allowed `Bash` patterns and `WebFetch` domains).

## Notes

- The user prefers Chinese UI strings by default (`LANG="zh"` in the notify config).
- The user works in WSL2 with Windows Terminal; WSL2-specific features are first-class.
