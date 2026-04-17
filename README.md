# notify-on-done

Claude Code 和 Codex 桌面通知插件。任务完成、计划就绪或需要确认时，通过系统通知提醒你。

## 安装

### 本地安装

```bash
# 克隆到本地
git clone https://github.com/miuzel/notify-on-done.git

# 在 Claude Code 中从子目录安装
/plugin install /path/to/notify-on-done/notify-on-done
```

### 通过 Marketplace 安装

若你的 Claude Code 已配置自定义 marketplace：

```bash
# 添加 marketplace（只需一次）
/plugin marketplace add <owner>/<repo>

# 安装插件
/plugin install notify-on-done
```

### 在 Codex 中安装

这个仓库同时提供 Codex 可识别的插件清单。Codex 通过仓库内的 `notify-on-done/` 作为插件根目录加载插件，把仓库作为本地 marketplace 添加到 Codex：

```bash
codex marketplace add /path/to/notify-on-done
```

如果你是通过 GitHub 克隆的仓库，也可以直接添加远程 marketplace：

```bash
codex marketplace add miuzel/notify-on-done@github
```

然后在 Codex 的插件/marketplace 界面中安装 `notify-on-done`。

## 启用插件

安装后，Claude Code 或 Codex 会自动加载插件。首次运行时会自动生成配置文件：

```
~/.config/claude-code/notify-on-done.conf
```

## 快速测试

```bash
bash notify-on-done/scripts/notify.sh task_complete "test message"
```

## 配置项

| 选项 | 默认值 | 说明 |
|------|--------|------|
| `ENABLE_SOUND` | `true` | 播放提示音 |
| `ENABLE_FLASH_TASKBAR` | `true` | 闪烁任务栏（WSL2） |
| `ENABLE_FOCUS_ON_CLICK` | `false` | 点击通知跳转窗口（实验性） |
| `FOCUS_TIMEOUT_SECONDS` | `30` | 点击跳转监听超时 |
| `LANG` | `zh` | 界面语言 |

## 许可证

MIT License
