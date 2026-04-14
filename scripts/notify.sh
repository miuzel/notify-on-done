#!/usr/bin/env bash
# notify.sh - Lightweight cross-platform notifications for Claude Code
# Usage: notify.sh <status> <message>
#   status: task_complete | question | plan_ready | error
#   message: notification body text

set -euo pipefail

STATUS="${1:-task_complete}"
MESSAGE="${2:-Claude Code needs your attention}"
TITLE="Claude Code"

# Directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------
# Configuration
# ------------------------------------------------------------------

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/claude-code/notify-on-done.conf"

# Defaults
ENABLE_SOUND="true"
ENABLE_FLASH_TASKBAR="true"
ENABLE_FOCUS_ON_CLICK="false"
FOCUS_TIMEOUT_SECONDS="30"
LANG="zh"

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
    else
        create_default_config
    fi
}

create_default_config() {
    cat > "$CONFIG_FILE" <<'EOF'
# notify-on-done 配置文件
# 修改后下次通知生效，无需重启 Claude Code

# 是否播放自定义提示音 (true/false)
ENABLE_SOUND="true"

# 是否在 WSL2 下闪烁任务栏图标 (true/false)
ENABLE_FLASH_TASKBAR="true"

# 实验性功能：点击通知跳转窗口 (true/false)
# 启用后会启动一个隐藏的 PowerShell 进程监听点击，最多存活 FOCUS_TIMEOUT_SECONDS 秒
ENABLE_FOCUS_ON_CLICK="false"

# 点击跳转监听超时时间（秒）
FOCUS_TIMEOUT_SECONDS="30"

# 界面语言 (zh / en)
LANG="zh"
EOF
}

load_config

# ------------------------------------------------------------------
# i18n
# ------------------------------------------------------------------

get_message() {
    local key="$1"
    case "$LANG" in
        en)
            case "$key" in
                click_to_focus_hint) printf '(Click within %s seconds to focus this window)' "$FOCUS_TIMEOUT_SECONDS" ;;
                *) printf '%s' "$key" ;;
            esac
            ;;
        zh|*)
            case "$key" in
                click_to_focus_hint) printf '（%s秒内点击此通知可跳转窗口）' "$FOCUS_TIMEOUT_SECONDS" ;;
                *) printf '%s' "$key" ;;
            esac
            ;;
    esac
}

# ------------------------------------------------------------------
# Helpers
# ------------------------------------------------------------------

is_wsl() {
    # WSL detection: check for WSL-specific strings in /proc/version
    if [[ -f /proc/version ]]; then
        grep -qiaE "(microsoft|wsl)" /proc/version && return 0
    fi
    # Additional check: powershell.exe availability
    command -v powershell.exe >/dev/null 2>&1 && return 0
    return 1
}

escape_ps() {
    # Escape single quotes for PowerShell strings
    printf '%s' "$1" | sed "s/'/''/g"
}

get_sound_file() {
    local sounds_dir
    sounds_dir="$(cd "$SCRIPT_DIR/../sounds" && pwd)"
    case "$STATUS" in
        task_complete) echo "$sounds_dir/task-complete.wav" ;;
        question)      echo "$sounds_dir/question.wav" ;;
        plan_ready)    echo "$sounds_dir/plan-ready.wav" ;;
        error)         echo "$sounds_dir/error.wav" ;;
        *)             echo "$sounds_dir/task-complete.wav" ;;
    esac
}

# Cached host window info: "ProcessName:PID:HWND"
HOST_WINDOW_INFO=""

# Detect the Windows window that hosts the current WSL session.
# Traces the powershell.exe parent chain up to the first wsl.exe ancestor,
# then continues upward to find WindowsTerminal or Code.
# Outputs: "ProcessName:PID:HWND" (HWND may be 0)
get_host_window() {
    if [[ -n "$HOST_WINDOW_INFO" ]]; then
        echo "$HOST_WINDOW_INFO"
        return
    fi

    if ! is_wsl; then
        echo ""
        return
    fi

    local ps_script result
    ps_script='
$myPid = $PID
$allProcs = Get-WmiObject Win32_Process
$wslProcs = $allProcs | Where-Object { $_.Name -eq "wsl.exe" }

function Find-AncestorWsl($processId, $visited) {
    if ($visited.ContainsKey($processId)) { return $null }
    $visited[$processId] = $true
    $proc = $allProcs | Where-Object { $_.ProcessId -eq $processId } | Select-Object -First 1
    if (-not $proc) { return $null }
    $wslMatch = $wslProcs | Where-Object { $_.ProcessId -eq $processId } | Select-Object -First 1
    if ($wslMatch) { return $wslMatch }
    return Find-AncestorWsl $proc.ParentProcessId $visited
}

$visited = @{}
$ancestorWsl = Find-AncestorWsl $myPid $visited

if (-not $ancestorWsl) {
    Write-Output "NOTFOUND"
    exit
}

$currentPid = $ancestorWsl.ParentProcessId
$hostProc = $null
$lastCodeProc = $null
while ($currentPid -ne 0) {
    try {
        $p = Get-Process -Id $currentPid -ErrorAction Stop
        if ($p.ProcessName -eq "WindowsTerminal") {
            if ($p.MainWindowHandle -ne [IntPtr]::Zero) {
                $hostProc = $p
                break
            }
        } elseif ($p.ProcessName -eq "Code") {
            $lastCodeProc = $p
            if ($p.MainWindowHandle -ne [IntPtr]::Zero) {
                $hostProc = $p
                break
            }
        }
        if ($p.Parent) {
            $currentPid = $p.Parent.Id
        } else {
            $wmiP = $allProcs | Where-Object { $_.ProcessId -eq $currentPid } | Select-Object -First 1
            if ($wmiP) {
                $currentPid = $wmiP.ParentProcessId
            } else {
                break
            }
        }
    } catch {
        break
    }
}

if (-not $hostProc -and $lastCodeProc) {
    $hostProc = $lastCodeProc
}

if ($hostProc) {
    Write-Output ($hostProc.ProcessName + ":" + $hostProc.Id + ":" + $hostProc.MainWindowHandle)
} else {
    Write-Output "NOTFOUND"
}
'

    result="$(printf '%s\n' "$ps_script" | powershell.exe -Command - 2>/dev/null | tr -d '\r')"
    HOST_WINDOW_INFO="$result"
    echo "$HOST_WINDOW_INFO"
}

# Check if the current foreground window is already Claude Code.
# Returns 0 (true) if focused, 1 (false) if not.
is_claude_focused() {
    if ! is_wsl; then
        return 1
    fi

    local host_info host_pid
    host_info="$(get_host_window)"
    if [[ -z "$host_info" ]] || [[ "$host_info" == "NOTFOUND" ]]; then
        return 1
    fi
    host_pid="$(echo "$host_info" | cut -d: -f2)"

    local ps_script focus_info
    ps_script='
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WinAPI {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll", CharSet=CharSet.Auto)] public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);
}
"@
$hwnd = [WinAPI]::GetForegroundWindow()
$fgPid = 0
[void][WinAPI]::GetWindowThreadProcessId($hwnd, [ref]$fgPid)
Write-Output ("FG:" + $fgPid)
'

    focus_info="$(printf '%s\n' "$ps_script" | powershell.exe -Command - 2>/dev/null)"
    local fg_pid
    fg_pid="$(printf '%s\n' "$focus_info" | grep '^FG:' | cut -d: -f2 | tr -d '\r')"

    if [[ -n "$fg_pid" ]] && [[ "$fg_pid" == "$host_pid" ]]; then
        return 0
    fi

    return 1
}

send_terminal_bell() {
    # No-op: FlashWindowEx provides proper taskbar highlighting on WSL2.
    # OSC 9 was removed because Windows Terminal forwards it as an audible
    # bell without any visible notification or taskbar change.
    :
}

# Rate limit: allow only one notification per session every 2 seconds.
# Returns 0 if allowed, 1 if throttled.
should_notify() {
    local session_id="${CLAUDE_SESSION_ID:-default}"
    local cooldown_seconds=2
    local state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/notify-on-done"
    local state_file="$state_dir/$session_id"

    mkdir -p "$state_dir" 2>/dev/null || return 0

    local now last
    now="$(date +%s)"
    last=0
    if [[ -f "$state_file" ]]; then
        last="$(cat "$state_file" 2>/dev/null || echo 0)"
    fi

    if [[ "$last" =~ ^[0-9]+$ ]] && (( now - last < cooldown_seconds )); then
        return 1
    fi

    printf '%s\n' "$now" > "$state_file" 2>/dev/null || true
    return 0
}

play_sound() {
    [[ "$ENABLE_SOUND" == "true" ]] || return 0

    local sound_file
    sound_file="$(get_sound_file)"
    [[ -f "$sound_file" ]] || return 0

    if is_wsl; then
        local winpath
        winpath="$(wslpath -w "$sound_file")"
        # Try MediaPlayer first (supports MP3), fallback to SoundPlayer (WAV only)
        powershell.exe -Command "
            Add-Type -AssemblyName presentationCore
            \$player = New-Object System.Windows.Media.MediaPlayer
            \$player.Open([System.Uri]::new('$(escape_ps "$winpath")'))
            \$player.Play()
            Start-Sleep -Milliseconds 1500
            \$player.Stop()
            \$player.Close()
        " >/dev/null 2>&1 || true
    else
        # Linux: try multiple players
        if command -v paplay >/dev/null 2>&1; then
            paplay "$sound_file" >/dev/null 2>&1 || true
        elif command -v ffplay >/dev/null 2>&1; then
            ffplay -nodisp -autoexit -loglevel quiet "$sound_file" >/dev/null 2>&1 || true
        elif command -v mpg123 >/dev/null 2>&1; then
            mpg123 -q "$sound_file" >/dev/null 2>&1 || true
        fi
    fi
}

# Flash the Windows taskbar button for the window that hosts this WSL session.
# Uses get_host_window to find the correct Code or WindowsTerminal handle.
flash_taskbar() {
    [[ "$ENABLE_FLASH_TASKBAR" == "true" ]] || return 0

    local host_info host_hwnd
    host_info="$(get_host_window)"
    if [[ -n "$host_info" ]] && [[ "$host_info" != "NOTFOUND" ]]; then
        host_hwnd="$(echo "$host_info" | cut -d: -f3)"
    fi

    # If we have a valid HWND, flash it directly
    if [[ -n "$host_hwnd" ]] && [[ "$host_hwnd" != "0" ]]; then
        local ps_script
        ps_script='
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class FlashAPI {
    [DllImport("user32.dll")]
    public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);
    [StructLayout(LayoutKind.Sequential)]
    public struct FLASHWINFO {
        public uint cbSize;
        public IntPtr hwnd;
        public uint dwFlags;
        public uint uCount;
        public uint dwTimeout;
    }
    public const uint FLASHW_ALL = 3;
    public const uint FLASHW_TIMERNOFG = 12;
}
"@
$hwnd = [IntPtr]__HWND_PLACEHOLDER__
if ($hwnd -ne [IntPtr]::Zero) {
    $fi = New-Object FlashAPI+FLASHWINFO
    $fi.cbSize = [uint32][System.Runtime.InteropServices.Marshal]::SizeOf($fi)
    $fi.hwnd = $hwnd
    $fi.dwFlags = [FlashAPI]::FLASHW_ALL -bor [FlashAPI]::FLASHW_TIMERNOFG
    $fi.uCount = 20
    $fi.dwTimeout = 200
    [void][FlashAPI]::FlashWindowEx([ref]$fi)
}
'
        ps_script="${ps_script/__HWND_PLACEHOLDER__/$host_hwnd}"
        printf '%s\n' "$ps_script" | powershell.exe -Command - >/dev/null 2>&1 || true
        return
    fi

    # Fallback: search by visible window title
    local search_title
    search_title="$(escape_ps "${1:-Claude Code}")"

    local ps_script
    ps_script='
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class FlashAPI {
    [DllImport("user32.dll")]
    public static extern bool FlashWindowEx(ref FLASHWINFO pwfi);
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    [StructLayout(LayoutKind.Sequential)]
    public struct FLASHWINFO {
        public uint cbSize;
        public IntPtr hwnd;
        public uint dwFlags;
        public uint uCount;
        public uint dwTimeout;
    }
    public const uint FLASHW_ALL = 3;
    public const uint FLASHW_TIMERNOFG = 12;
}
"@
$titleFilter = "__TITLE_PLACEHOLDER__"
$script:foundHwnd = [IntPtr]::Zero
$enumProc = [FlashAPI+EnumWindowsProc] {
    param($h, $lp)
    if ([FlashAPI]::IsWindowVisible($h)) {
        $sb = New-Object System.Text.StringBuilder 256
        [void][FlashAPI]::GetWindowText($h, $sb, 256)
        if ($sb.ToString() -like "*$titleFilter*") {
            $script:foundHwnd = $h
            return $false
        }
    }
    return $true
}
[void][FlashAPI]::EnumWindows($enumProc, [IntPtr]::Zero)
$hwnd = $script:foundHwnd
if ($hwnd -ne [IntPtr]::Zero) {
    $fi = New-Object FlashAPI+FLASHWINFO
    $fi.cbSize = [uint32][System.Runtime.InteropServices.Marshal]::SizeOf($fi)
    $fi.hwnd = $hwnd
    $fi.dwFlags = [FlashAPI]::FLASHW_ALL -bor [FlashAPI]::FLASHW_TIMERNOFG
    $fi.uCount = 20
    $fi.dwTimeout = 200
    [void][FlashAPI]::FlashWindowEx([ref]$fi)
}
'
    ps_script="${ps_script/__TITLE_PLACEHOLDER__/$search_title}"
    printf '%s\n' "$ps_script" | powershell.exe -Command - >/dev/null 2>&1 || true
}

# ------------------------------------------------------------------
# WSL2 -> Windows notification
# ------------------------------------------------------------------

# Show BalloonTip with an experimental click-to-focus listener.
# Runs a hidden PowerShell process that stays alive for FOCUS_TIMEOUT_SECONDS.
notify_wsl_with_focus() {
    local ps_title
    local ps_message
    ps_title="$(escape_ps "$TITLE")"
    ps_message="$(escape_ps "$MESSAGE")"

    # Build status-specific title
    case "$STATUS" in
        task_complete) ps_title="$(escape_ps "✅ Claude Code - 已完成")" ;;
        question)      ps_title="$(escape_ps "❓ Claude Code - 需要确认")" ;;
        plan_ready)    ps_title="$(escape_ps "📋 Claude Code - 计划待审")" ;;
        error)         ps_title="$(escape_ps "🔴 Claude Code - 出错")" ;;
    esac

    local focus_hint
    focus_hint="$(get_message click_to_focus_hint)"
    ps_message="${ps_message} ${focus_hint}"

    # Delay actual notification by 3 seconds: if the user clicks in during
    # the wait, skip the remaining notification and sound.
    sleep 3
    if is_claude_focused; then
        return 0
    fi

    # Flash taskbar button for Windows Terminal / VS Code
    flash_taskbar "Claude Code"

    # Play custom sound after a short delay so it does not overlap with system sounds
    (sleep 1; play_sound) &

    # Get Windows temp folder via PowerShell (avoids hardcoding user profile)
    local win_temp
    win_temp="$(powershell.exe -Command 'Write-Host $env:TEMP' 2>/dev/null | tr -d '\r')"
    if [[ -z "$win_temp" ]]; then
        win_temp="C:\\Windows\\Temp"
    fi

    local ps_file
    ps_file="$win_temp\\notify-on-done-focus.ps1"
    local pid_file
    pid_file="$win_temp\\notify-on-done-focus.pid"

    local host_info host_hwnd host_proc_name
    host_info="$(get_host_window)"
    host_hwnd="0"
    host_proc_name=""
    if [[ -n "$host_info" ]] && [[ "$host_info" != "NOTFOUND" ]]; then
        host_proc_name="$(echo "$host_info" | cut -d: -f1)"
        host_hwnd="$(echo "$host_info" | cut -d: -f3)"
    fi

    local ps_script
    ps_script='
param([string]$Title, [string]$Body, [int]$TimeoutSec, [string]$HostProcName)

$PidFile = "$env:TEMP\notify-on-done-focus.pid"

# Deduplicate: kill existing daemon
if (Test-Path $PidFile) {
    $oldPid = Get-Content $PidFile -ErrorAction SilentlyContinue
    if ($oldPid) {
        try { Stop-Process -Id $oldPid -Force -ErrorAction SilentlyContinue } catch {}
    }
}
# Write current PID
$pid | Set-Content $PidFile -ErrorAction SilentlyContinue

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Win32 API for focus
$win32 = @"
using System;
using System.Runtime.InteropServices;
public class Win32Focus {
    [DllImport("user32.dll")] [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);
}
"@
Add-Type -TypeDefinition $win32 -ErrorAction SilentlyContinue

Unregister-Event -SourceIdentifier "ClaudeNotifyBalloonClicked" -ErrorAction SilentlyContinue

$icon = New-Object System.Windows.Forms.NotifyIcon
$icon.Icon = [System.Drawing.SystemIcons]::Information
$icon.Visible = $true
$icon.BalloonTipTitle = $Title
$icon.BalloonTipText = $Body

$action = {
    $hwnd = [IntPtr]__HOST_HWND_PLACEHOLDER__
    if ($hwnd -eq [IntPtr]::Zero) {
        $proc = Get-Process -Name WindowsTerminal -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($proc -and $proc.MainWindowHandle -ne [IntPtr]::Zero) {
            $hwnd = $proc.MainWindowHandle
        }
    }
    if ($hwnd -eq [IntPtr]::Zero) {
        $proc = Get-Process -Name Code -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($proc -and $proc.MainWindowHandle -ne [IntPtr]::Zero) {
            $hwnd = $proc.MainWindowHandle
        }
    }
    if ($hwnd -ne [IntPtr]::Zero) {
        # ShowWindow(9) restores minimized windows, but for VS Code it can
        # incorrectly un-maximize the window. Skip it for Code.
        if ($HostProcName -ne "Code" -and [Win32Focus]::IsIconic($hwnd)) {
            [Win32Focus]::ShowWindow($hwnd, 9) | Out-Null
        }
        [Win32Focus]::SetForegroundWindow($hwnd) | Out-Null
    }
    $icon.Visible = $false
    $icon.Dispose()
    Unregister-Event -SourceIdentifier "ClaudeNotifyBalloonClicked" -ErrorAction SilentlyContinue
}

Register-ObjectEvent -InputObject $icon -EventName "BalloonTipClicked" -SourceIdentifier "ClaudeNotifyBalloonClicked" -Action $action | Out-Null
$icon.ShowBalloonTip(5000)

# Wait for click or timeout
Wait-Event -SourceIdentifier "ClaudeNotifyBalloonClicked" -Timeout $TimeoutSec -ErrorAction SilentlyContinue | Out-Null

# Cleanup
$icon.Visible = $false
$icon.Dispose()
Unregister-Event -SourceIdentifier "ClaudeNotifyBalloonClicked" -ErrorAction SilentlyContinue
if (Test-Path $PidFile) { Remove-Item $PidFile -ErrorAction SilentlyContinue }
'
    ps_script="${ps_script/__HOST_HWND_PLACEHOLDER__/$host_hwnd}"

    # Write the .ps1 file from bash side via powershell.exe to avoid path/permission issues
    powershell.exe -Command "
        Set-Content -Path '$(escape_ps "$ps_file")' -Value '$(escape_ps "$ps_script")' -Encoding UTF8
    " >/dev/null 2>&1 || true

    # Launch PowerShell directly (no Start-Process hidden window) in bash background.
    # WSL2 powershell.exe is a Windows process and survives bash exit.
    nohup powershell.exe -ExecutionPolicy Bypass -File "$(escape_ps "$ps_file")" \
        -Title "$(escape_ps "$ps_title")" \
        -Body "$(escape_ps "$ps_message")" \
        -TimeoutSec "$FOCUS_TIMEOUT_SECONDS" \
        -HostProcName "$(escape_ps "$host_proc_name")" \
        >/dev/null 2>&1 &
}

notify_wsl() {
    local ps_title
    local ps_message
    ps_title="$(escape_ps "$TITLE")"
    ps_message="$(escape_ps "$MESSAGE")"

    # Build status-specific title
    case "$STATUS" in
        task_complete) ps_title="$(escape_ps "✅ Claude Code - 已完成")" ;;
        question)      ps_title="$(escape_ps "❓ Claude Code - 需要确认")" ;;
        plan_ready)    ps_title="$(escape_ps "📋 Claude Code - 计划待审")" ;;
        error)         ps_title="$(escape_ps "🔴 Claude Code - 出错")" ;;
    esac

    # Delay actual notification by 3 seconds: if the user clicks in during
    # the wait, skip the remaining notification and sound.
    sleep 3
    if is_claude_focused; then
        return 0
    fi

    # Flash taskbar button for Windows Terminal / VS Code
    flash_taskbar "Claude Code"

    # Play custom sound after a short delay so it does not overlap with system sounds
    (sleep 1; play_sound) &

    # Use NotifyIcon BalloonTip (reliable across Windows 10/11)
    powershell.exe -Command "
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        \$icon = New-Object System.Windows.Forms.NotifyIcon
        \$icon.Icon = [System.Drawing.SystemIcons]::Information
        \$icon.Visible = \$true
        \$icon.BalloonTipTitle = '${ps_title}'
        \$icon.BalloonTipText = '${ps_message}'
        \$icon.ShowBalloonTip(5000)
        Start-Sleep -Milliseconds 500
        \$icon.Dispose()
    " >/dev/null 2>&1 || true
}

# ------------------------------------------------------------------
# Native Linux notification
# ------------------------------------------------------------------
notify_linux() {
    local urgency="normal"

    case "$STATUS" in
        task_complete) TITLE="✅ 已完成" ;;
        question)      TITLE="❓ 需要确认"; urgency="critical" ;;
        plan_ready)    TITLE="📋 计划待审" ;;
        error)         TITLE="🔴 出错"; urgency="critical" ;;
    esac

    # Play sound after a short delay so it doesn't overlap with system notification sound
    (sleep 1; play_sound) &

    if command -v notify-send >/dev/null 2>&1; then
        notify-send \
            --app-name="Claude Code" \
            --urgency="$urgency" \
            "$TITLE" \
            "$MESSAGE" 2>/dev/null || true
    else
        echo "[notify-on-done] notify-send not found; skipping desktop notification"
    fi
}

# ------------------------------------------------------------------
# Main
# ------------------------------------------------------------------

main() {
    send_terminal_bell

    if ! should_notify; then
        # Rate limited — skip notification
        return 0
    fi

    if is_wsl; then
        if [[ "$ENABLE_FOCUS_ON_CLICK" == "true" ]]; then
            notify_wsl_with_focus
        else
            notify_wsl
        fi
    else
        if is_claude_focused; then
            return 0
        fi
        notify_linux
    fi
}

main "$@"
