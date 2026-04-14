# notify-on-done

一个跨平台的 Claude Code 桌面通知插件，通过 hooks 触发，支持 WSL2 和原生 Linux。

## 功能

- **WSL2**：任务栏闪烁 + BalloonTip 通知 + 自定义音效
- **Linux**：`notify-send` + 系统播放器回退
- **焦点检测**：若 Claude Code 窗口已聚焦则跳过通知
- **速率限制**：每个 session 2 秒内最多一次通知
- **实验性**：点击通知跳转回窗口（WSL2  only）

## 安装

### 方式一：作为 Plugin（推荐）

```bash
# 本地测试
claude --plugin-dir /path/to/notify-on-done

# 或安装到 Claude Code（若已发布到 marketplace）
/plugin install notify-on-done
```

### 方式二：Standalone 安装

将 `hooks/` 配置合并到你的 `~/.claude/settings.json` 或项目 `.claude/settings.json` 中，并修改脚本路径为你的实际目录。

## 快速测试

```bash
# 发送测试通知
bash scripts/notify.sh task_complete "test message"

# 清除速率限制状态
rm -f ~/.cache/notify-on-done/default
```

## 配置

首次运行时会自动生成配置文件：

```
~/.config/claude-code/notify-on-done.conf
```

可用选项：

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_SOUND` | `true` | 播放自定义提示音 |
| `ENABLE_FLASH_TASKBAR` | `true` | WSL2 下闪烁任务栏图标 |
| `ENABLE_FOCUS_ON_CLICK` | `false` | 实验性：点击通知跳转窗口 |
| `FOCUS_TIMEOUT_SECONDS` | `30` | 点击跳转监听超时时间 |
| `LANG` | `zh` | 界面语言（`zh` 或 `en`）|

## 项目结构

```
notify-on-done/
├── .claude-plugin/
│   └── plugin.json      # 插件清单
├── hooks/
│   └── hooks.json       # Hook 配置
├── scripts/
│   └── notify.sh        # 主脚本
├── sounds/
│   ├── task-complete.wav
│   ├── question.wav
│   ├── plan-ready.wav
│   └── error.wav
├── README.md
└── LICENSE
```

## 许可证

MIT License
