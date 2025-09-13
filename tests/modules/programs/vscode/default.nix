{
  vscode-keybindings = ./keybindings.nix;
  vscode-tasks = ./tasks.nix;
  vscode-mcp = ./mcp.nix;
  vscode-update-checks = ./update-checks.nix;
  vscode-snippets = ./snippets.nix;

  vscode-forks-cursor-override-mcp-path = ./forks/cursor-override-mcp-path.nix;
}
// (import ./tests.nix {
  programName = "vscode";
  packageName = "vscode";
  configDirName = "Code";
})
// (import ./tests.nix {
  programName = "cursor";
  packageName = "code-cursor";
  configDirName = "Cursor";
})
