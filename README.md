# cc-pop

个人 Claude Code 配置仓库，包含自定义 skills、hooks 和 settings，主要用于 WSL2 + Windows Terminal 环境。

## 功能

### `notify-on-done` Skill

位置：`.claude/skills/notify-on-done/`

一个跨平台的桌面通知 skill，在 Claude Code 触发特定 hook 时发送通知。

**核心文件：**
- `notify.sh` — 主脚本，支持 WSL2 和原生 Linux
- `SKILL.md` — Skill 清单和文档
- `notify-on-done.conf` — 用户配置文件（首次运行时自动生成）
- `*.wav` — 自定义提示音

**主要特性：**
- WSL2：任务栏闪烁 + BalloonTip 通知 + 自定义音效
- Linux：`notify-send` + 系统播放器回退
- 焦点检测：若窗口已聚焦则跳过通知
- 速率限制：每个 session 2 秒内最多一次通知
- 实验性：点击通知跳转回窗口

**Hook 配置（`.claude/settings.json`）：**
- `Stop` → `task_complete`
- `Notification` → `question`
- `PreToolUse` (`ExitPlanMode`) → `plan_ready`

## 快速测试

```bash
# 发送测试通知
bash .claude/skills/notify-on-done/notify.sh task_complete "test message"

# 清除速率限制状态
rm -f ~/.cache/notify-on-done/default
```

## 许可证

MIT License
