# VHash Tools 说明

## 命令

- `VHash: Copy Path With Line Range`

## 快捷键

- 默认快捷键：`Shift+Cmd+V`
- 命令 ID：`vhashTools.copySelectionPathRange`

## 功能行为

- 复制当前文件的路径与行号范围，格式为 `path.py:start-end`（可为相对或绝对路径）。
- 如果没有选区，则使用光标所在行，起止行相同。
- 如果选区结束位置在下一行第 0 列，则结束行会减 1，避免多算空行。

## 示例输出

- `src/app.py:10-42`
- `/Users/liaohuqiu/.../vhash-vscode-ext/AGENTS.md:20-20`

## 本地安装（Cursor / VS Code）

1. 在本目录打开终端。
2. 执行 `npm install`。
3. 执行 `npm run compile`。
4. Shift + Cm+ P 打开命令面板，输入 `Extensions: Install from VSIX`，选择当前目录（或对应 `.vsix` 文件）。
5. 选择当前目录（或对应 `.vsix` 文件）。

## 使用方法

1. 在编辑器中选中代码（或只放置光标）。
2. 运行命令 `VHash: Copy Path With Line Range`，或直接按 `Shift+Cmd+V`。

## keybinding

- `Shift+Cmd+P`：open command palette

```
- `Shift+Cmd+E`：show explorer
{
  "key": "shift+cmd+e",
  "command": "workbench.view.explorer",
}

- `Option+F`：search
{
  "key": "alt+f",
  "command": "workbench.action.findInFiles"
}
- `Shift+Cmd+O`：open files
{
  "key": "shift+cmd+o",
  "command": "workbench.action.quickOpen"
}

- `Shift+Cmd+[`：left tab
{
  "key": "shift+cmd+[",
  "command": "workbench.action.previousEditor"
}
- `Shift+Cmd+]`：right tab
{
  "key": "shift+cmd+]",
  "command": "workbench.action.nextEditor"
}
```

{
  "key": "shift+cmd+e",
  "command": "workbench.files.action.showActiveFileInExplorer"
}