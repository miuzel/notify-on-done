---
name: notify-on-done
description: Send desktop notification when Claude finishes a task or needs user attention.
type: productivity
---

# Notify on Done

A lightweight, cross-platform notification skill for Claude Code.

## What it does

- Sends a desktop notification when Claude completes work or asks a question
- Works on **native Linux** (`notify-send`) and **WSL2** (Windows BalloonTip via PowerShell)
- Plays a custom sound and flashes the taskbar button on WSL2
- Skips notifications if the Claude Code window is already focused

## Supported triggers

| Event | When it fires |
|-------|---------------|
| `task_complete` | Claude finishes a response after tools usage |
| `question` | Claude asks for permission or user input |
| `plan_ready` | A plan is generated and waiting for approval |

## Installation

No installation required — the skill is active once this directory is present in `.claude/skills/notify-on-done/`.

## Configuration

The skill auto-creates a config file on first run:

```bash
.claude/skills/notify-on-done/notify-on-done.conf
```

Available options:

| Option | Default | Description |
|--------|---------|-------------|
| `ENABLE_SOUND` | `true` | Play a custom sound when a notification fires |
| `ENABLE_FLASH_TASKBAR` | `true` | Flash the Windows taskbar button (WSL2 only) |
| `ENABLE_FOCUS_ON_CLICK` | `false` | **Experimental:** click the BalloonTip to focus the Claude Code window (WSL2 only) |
| `FOCUS_TIMEOUT_SECONDS` | `30` | How long the click-to-focus listener stays alive |
| `LANG` | `zh` | UI language (`zh` or `en`) |

Edit the config file to customize behavior without touching the script.

## Experimental click-to-focus (WSL2)

When `ENABLE_FOCUS_ON_CLICK="true"`, the notification shows a hint like:

> （30秒内点击此通知可跳转窗口）

If you click the BalloonTip within the timeout, the hidden PowerShell listener will bring the Windows Terminal window to the foreground. The listener automatically exits after the timeout or when clicked.

## Custom sounds

Place WAV files in the same directory as `notify.sh`:

- `task-complete.wav`
- `question.wav`
- `plan-ready.wav`
- `error.wav`

If a file is missing, the sound for that status is skipped.
