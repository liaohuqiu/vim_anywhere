# Handoff Note

本轮主要改的是本机的 Rime 与 Karabiner 配置，不在仓库代码里。

## 变更文件

- `/Users/liaohuqiu/Library/Rime/default.custom.yaml`
- `/Users/liaohuqiu/Library/Rime/rime.lua`
- `/Users/liaohuqiu/Library/Rime/tiger.schema.yaml`
- `/Users/liaohuqiu/Library/Rime/tigress.schema.yaml`
- `/Users/liaohuqiu/Library/Rime/PY_c.schema.yaml`
- `/Users/liaohuqiu/Library/Rime/lua/reverse_lookup_logger.lua`
- `/Users/liaohuqiu/Library/Rime/lua/command_registry.lua`
- `/Users/liaohuqiu/Library/Rime/lua/command_palette.lua`
- `/Users/liaohuqiu/Library/Rime/lua/command_executor.lua`
- `/Users/liaohuqiu/.config/karabiner/karabiner.json`

## 已完成内容

- 关闭了 `Shift_L/Shift_R: commit_code`，改为 `noop`。
- 保留了 `Cmd+E` 的英文切换职责，内部桥接仍是 `Control+semicolon`。
- 保留了现有反查前缀 `` ` ``，没有移除。
- 新增了 `Cmd+I` 快捷反查入口，Karabiner 会在 `Squirrel.Hans` 下把 `Left Command + I` 映射成 `` ` ``。
- 在 `tiger` 里接入了统一 logger processor，日志文件仍写到 `/Users/liaohuqiu/Library/Rime/reverse_lookup.log`。
- logger 当前会写三类事件：
  - `tiger_commit`
  - `reverse_lookup_commit`
  - `ascii_english_commit`
- 将 tiger 的命令模式从“隐形字符串匹配 + 后续任意键触发”改成了“候选面板 + 确认执行”。
- 命令表已经抽到 `command_registry.lua`，`command_palette.lua` 和 `command_executor.lua` 共用同一套命令定义。
- tiger 当前不再使用旧的 `lua_processor@exe_processor` 执行命令，已改为：
  - `lua_translator@command_palette`
  - `lua_processor@command_executor`
- 已做过 `luac -p`、`jq empty`、YAML 语法校验，并执行过 Squirrel reload。

## 当前实际效果

### 输入与切换

- 在 `tiger` / `tigress` / `PY_c` 中，`Control+semicolon` 会切 `ascii_mode`。
- 在 `Squirrel.Hans` 下：
  - `Left Command + E` 映射到 `Control+semicolon`
  - `Left Command + I` 映射到 `` ` ``
- 反查现在有两种入口：
  - 直接输入 `` ` ``
  - 按 `Left Command + I`

### 日志

- 中文正常 commit 会写 `tiger_commit`。
- 反查成功上屏会写 `reverse_lookup_commit`，包含 `query` 和 `commit_text`。
- 旧日志文件里还保留着早期格式的记录，没有清理；新格式记录带 `event_type`。

### 命令模式

- 输入 `/huma` 时，会在候选区出现“打开 Tiger 官网”这一条命令候选。
- 输入 `/google`、`/zitong` 等已有命令时，也会出现对应命令候选。
- 只有按空格、回车，或数字选中命令候选时才执行。
- 旧问题“输入完 `/huma` 后后续任意键都会触发”已经通过新设计规避。

## 当前限制 / 未解决问题

### 1. ascii_mode 英文日志仍然拿不到

- `ascii_mode` 下英文“每个字母直接上屏”时，当前没有日志。
- 原因已确认：这类输入在 Squirrel/Rime 路径里通常不会进入我们挂的 `commit_notifier`，而是直接回到应用侧上屏，所以 `reverse_lookup_logger.lua` 收不到对应 commit。
- 这不是当前 Lua 条件判断的小 bug，而是事件路径层面的限制。

### 2. 命令模式需要真实手测确认

- 语法和接线已经检查过，`build/tiger.schema.yaml` 里也能看到：
  - `lua_processor@command_executor`
  - `lua_translator@command_palette`
- 但还没有在这里替用户完成真实交互手测。
- 需要本机验证：
  - `/huma` 是否出现候选而不是立即执行
  - `/huma + 空格/回车/数字` 是否执行命令并清空上下文
  - `/huma` 后继续输入其他键是否不执行

## 关键实现说明

### 命令表

`command_registry.lua` 当前维护的是静态命令表，包含这些主入口：

- `/huma` / `/zhmn`
- `/baidu` / `/bddu` / `/fuxl`
- `/biying` / `/bing` / `/biyk` / `/htxk`
- `/guge` / `/google` / `/hgzz`
- `/wangpan` / `/whpj` / `/mbia`
- `/genda` / `/gfda` / `/piua` / `/muyi` / `/emon`
- `/zitong` / `/zits` / `/whib`
- `/yedian` / `/yedm` / `/dnih`

### 命令 UI

- `command_palette.lua` 只在输入串完整匹配命令表时产生命令候选。
- 候选类型为 `command`，候选文字是用户可见标签，comment 保存原始命令串。

### 命令执行

- `command_executor.lua` 只在当前输入刚好是某条命令且当前有候选菜单时工作。
- 它只响应：
  - `space`
  - `Return`
  - `KP_Enter`
  - 数字选中
- 选中命令候选后会调用 `open` 打开对应 URL，并 `context:clear()`。

## 如果后续要继续

有两条明显的后续路线：

- 保持当前手感：
  - 接受 `ascii_mode` 英文不记日志
  - 继续保留中文 commit、反查 commit、命令面板
- 继续追求完整日志：
  - 不再用“真 ascii_mode 直通英文”
  - 改成一种仍经过 Rime 的英文模式
  - 这样才有机会稳定记录英文 commit

## 参考文件

- `/Users/liaohuqiu/Library/Rime/reverse_lookup.log`
- `/Users/liaohuqiu/Library/Rime/build/tiger.schema.yaml`
