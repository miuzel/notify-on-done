# notify-on-done

Claude Code 桌面通知插件。任务完成、计划就绪或需要确认时，通过系统通知提醒你。

## 安装

### 从 GitHub 直接安装

```bash
/plugin install miuzel/notify-on-done@github
```

### 本地安装

```bash
# 克隆到本地
git clone https://github.com/miuzel/notify-on-done.git

# 在 Claude Code 中从本地路径安装
/plugin install /path/to/notify-on-done
```

### 通过 Marketplace 安装

若你的 Claude Code 已配置自定义 marketplace：

```bash
# 添加 marketplace（只需一次）
/plugin marketplace add <owner>/<repo>

# 安装插件
/plugin install notify-on-done
```

## 启用插件

安装后，Claude Code 会自动加载插件。首次运行时会自动生成配置文件：

```
~/.config/claude-code/notify-on-done.conf
```

## 快速测试

```bash
bash scripts/notify.sh task_complete "test message"
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
