import * as vscode from "vscode";

function getSelectionRange(editor: vscode.TextEditor): { startLine: number; endLine: number } {
  const sel = editor.selection;

  if (sel.isEmpty) {
    const line = sel.active.line + 1;
    return { startLine: line, endLine: line };
  }

  let startLine = sel.start.line;
  let endLine = sel.end.line;

  if (sel.end.character === 0 && endLine > startLine) {
    endLine -= 1;
  }

  return { startLine: startLine + 1, endLine: endLine + 1 };
}

function getAbsolutePath(document: vscode.TextDocument): string {
  return document.uri.fsPath;
}

export function activate(context: vscode.ExtensionContext): void {
  const cmd = vscode.commands.registerCommand("vhashTools.copySelectionPathRange", () => {
    const editor = vscode.window.activeTextEditor;
    if (!editor) {
      vscode.window.showWarningMessage("No active editor");
      return;
    }

    const document = editor.document;
    const relPath = getAbsolutePath(document);
    const { startLine, endLine } = getSelectionRange(editor);
    const text = `@${relPath}:${startLine}-${endLine}`;

    vscode.env.clipboard.writeText(text);
    vscode.window.showInformationMessage(`Copied: ${text}`);
  });

  context.subscriptions.push(cmd);
}

export function deactivate(): void {}
